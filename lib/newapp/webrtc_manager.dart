import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../api/api.dart';
import '../models/user.dart';

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

  // MODIFIED: Accepts currentUser and friendId
  Future<String> createCall(User currentUser, String friendId) async {
    // 1. Fetch the friend's latest data from Firestore
    final friendDoc = await _firestore.collection('users').doc(friendId).get();
    if (!friendDoc.exists || friendDoc.data() == null) {
      throw Exception("Friend with ID $friendId not found in Firestore.");
    }
    // You need a User.fromMap factory constructor in your User model for this to work cleanly.
    // For now, let's extract the data manually.
    final friendData = friendDoc.data()!;
    final friendToken = friendData['firebaseToken'] as String?;
    final friendName = friendData['name'] as String?;

    if (friendToken == null) {
      throw Exception("The friend you are trying to call does not have a valid FCM token.");
    }

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

    // 2. Send the notification using the FRESH token from Firestore
    // Note: Your Api.sendNotificationRequestToFriendToAcceptCall might need adjustment
    // if it expects a full User object for the friend. Let's assume it can take a token and name.
    Api.sendNotificationRequestToFriendToAcceptCall(
        roomId: room.id,
        caller: currentUser,
        friendToken: friendToken,
        friendName: friendName ?? 'A friend'
    );

    room.snapshots().listen((snap) async {
      final data = snap.data();
      if (data != null && data['answer'] != null && !_remoteDescriptionSet) {
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
