import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? _pc;
  MediaStream? localStream;

  final void Function(MediaStream stream) onRemoteStream;
  final void Function(RTCPeerConnectionState state) onConnectionStateChanged;

  WebRTCManager({
    required this.onRemoteStream,
    required this.onConnectionStateChanged,
  });

  bool _remoteDescriptionSet = false;

  final Map<String, dynamic> _config = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  Future<void> initMedia() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  Future<String> createCall() async {
    final room = _firestore.collection('calls').doc();
    _pc = await createPeerConnection(_config);
    _addCommonListeners();

    for (var track in localStream!.getTracks()) {
      _pc!.addTrack(track, localStream!);
    }

    _pc!.onIceCandidate = (c) {
      if (c != null) {
        room.collection('callerCandidates').add(c.toMap());
      }
    };

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await room.set({'offer': offer.toMap()});

    room.snapshots().listen((snap) async {
      final data = snap.data();
      if (data != null &&
          data['answer'] != null &&
          !_remoteDescriptionSet) {

        await _pc!.setRemoteDescription(
          RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          ),
        );

        _remoteDescriptionSet = true;
      }
    });


    room.collection('calleeCandidates').snapshots().listen((snap) {
      for (var d in snap.docChanges) {
        if (d.type == DocumentChangeType.added) {
          final c = d.doc.data()!;
          _pc!.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
          );
        }
      }
    });

    return room.id;
  }

  Future<void> joinCall(String id) async {
    final room = _firestore.collection('calls').doc(id);
    final snap = await room.get();
    if (!snap.exists) return;

    _pc = await createPeerConnection(_config);
    _addCommonListeners();

    for (var track in localStream!.getTracks()) {
      _pc!.addTrack(track, localStream!);
    }

    _pc!.onIceCandidate = (c) {
      if (c != null) {
        room.collection('calleeCandidates').add(c.toMap());
      }
    };

    final offer = snap.data()!['offer'];
    await _pc!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await room.update({'answer': answer.toMap()});

    room.collection('callerCandidates').snapshots().listen((snap) {
      for (var d in snap.docChanges) {
        if (d.type == DocumentChangeType.added) {
          final c = d.doc.data()!;
          _pc!.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
          );
        }
      }
    });
  }

  void _addCommonListeners() {
    _pc!.onTrack = (e) {
      if (e.streams.isNotEmpty) {
        onRemoteStream(e.streams.first);
      }
    };

    _pc!.onConnectionState = (s) {
      onConnectionStateChanged(s);
    };
  }

  Future<void> hangUp() async {
    await _pc?.close();
    _pc = null;
    localStream?.dispose();
  }
}
