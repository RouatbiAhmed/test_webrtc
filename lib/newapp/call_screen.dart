import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_manager.dart';
import '../models/user.dart';
import '../api/api.dart';

class CallScreen extends StatefulWidget {
  final User currentUser;
  final String friendId;
  final bool isCaller;
  final String? callId;

  const CallScreen({
    super.key,
    required this.currentUser,
    required this.friendId,
    required this.isCaller,
    this.callId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late WebRTCManager _manager;
  final RTCVideoRenderer _audioRenderer = RTCVideoRenderer();

  String _status = 'Initializing';
  RTCPeerConnectionState _state =
      RTCPeerConnectionState.RTCPeerConnectionStateNew;

  Widget _buildAppBarTitle() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.friendId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final friendName = snapshot.data?['name'] ?? 'Friend';
          return Text('Call with $friendName');
        }
        return const Text('Calling...');
      },
    );
  }


  Widget _buildConnectionIcon() {
    IconData icon;
    Color color;

    switch (_state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        icon = Icons.wifi;
        color = Colors.green;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        icon = Icons.wifi_find;
        color = Colors.orange;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        icon = Icons.wifi_off;
        color = Colors.red;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }


  @override
  void initState() {
    super.initState();

    _manager = WebRTCManager(
      onRemoteStream: (stream) async {
        _audioRenderer.srcObject = stream;
        await Helper.setSpeakerphoneOn(true);
        setState(() => _status = 'Connected');
      },
      onConnectionStateChanged: (s) {
        setState(() => _state = s);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _audioRenderer.initialize();
      await _connect();
    });
  }

  Future<void> _connect() async {
    await _manager.initMedia();

    if (widget.isCaller) {
      // Pass currentUser and friendId to the manager
      final id = await _manager.createCall(widget.currentUser, widget.friendId);
      setState(() => _status = 'Ringing...');
      // The WebRTCManager is now responsible for sending the notification, so the API call is removed from here.
    } else {
      await _manager.joinCall(widget.callId!);
      setState(() => _status = 'Connecting...');
    }
  }

  @override
  void dispose() {
    _manager.hangUp();
    _audioRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: _buildAppBarTitle(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildConnectionIcon(),
          )
        ],

      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_status, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 30),

          // AUDIO WILL NOT PLAY WITHOUT THIS
          SizedBox(
            height: 0,
            width: 0,
            child: RTCVideoView(_audioRenderer),
          ),

          const SizedBox(height: 30),
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () {
              _manager.hangUp();
              Navigator.pop(context);
            },
            child: const Icon(Icons.call_end),
          )
        ],
      ),
    );
  }
}
