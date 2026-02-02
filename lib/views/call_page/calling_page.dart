import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:test_webrtc/views/call_page/webrtc_logic.dart';
import '../../api/api.dart';
import '../../constants/colors.dart';
import '../../helper/countup.dart';
import '../../helper/size_config.dart';
import '../../models/user.dart';

// Represents the different states a call can be in
enum CallStatus { calling, accepted, ringing }

// Page shown when a call is being made, received, or accepted
class CallAcceptDeclinePage extends StatefulWidget {
  final User user;                 // The other user involved in the call
  final CallStatus? callStatus;    // Current call state (calling / ringing / accepted)
  final String? roomId;            // WebRTC room ID (used to connect peers)

  const CallAcceptDeclinePage({
    Key? key,
    required this.user,
    this.callStatus,
    this.roomId,
  }) : super(key: key);

  @override
  _CallAcceptDeclinePageState createState() =>
      _CallAcceptDeclinePageState();
}

class _CallAcceptDeclinePageState extends State<CallAcceptDeclinePage> {
  late CallStatus callStatus; // Local mutable call status

  // Icons shown in the bottom sliding panel (speaker, bluetooth, video, mute, hang up)
  List<IconData> bottomSheetIcons = [
    LineIcons.speakerDeck,
    LineIcons.bluetooth,
    LineIcons.videoAlt,
    LineIcons.microphoneSlash,
    LineIcons.phoneSlash
  ];

  // Handles WebRTC signaling and media logic
  WebRTCLogic webrtcLogic = WebRTCLogic();

  // Renderers for displaying local and remote video streams
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  String? roomId; // Stores the active WebRTC room ID

  // Initializes WebRTC, media streams, and signaling logic
  initializeWebRTC() async {
    // Prepare video renderers
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    // Called when the remote peer stream is received
    webrtcLogic.onAddRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {}); // Refresh UI to show remote video
    };

    // Opens camera and microphone
    webrtcLogic.openUserMedia(_localRenderer, _remoteRenderer);

    if (callStatus == CallStatus.calling) {
      // Caller creates a WebRTC room
      roomId = await webrtcLogic.createRoom(_remoteRenderer);
      print("roomID: $roomId");

      // Send FCM notification to the other user to accept the call
      Api.sendNotificationRequestToFriendToAcceptCall(
        roomId!,
        widget.user,
      );
    } else {
      // Receiver joins an existing WebRTC room
      roomId = widget.roomId;
      webrtcLogic.joinRoom(
        roomId!,
        _remoteRenderer,
      );
    }

    if (kDebugMode) {
      print("connected successfully");
    }
  }

  @override
  void initState() {
    // If no call status is provided, default to calling
    callStatus = widget.callStatus ?? CallStatus.calling;

    // Start WebRTC setup as soon as the page loads
    initializeWebRTC();

    super.initState();
  }

  @override
  void dispose() {
    // Release camera, microphone, and WebRTC resources
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    webrtcLogic.hangUp(_localRenderer);
    super.dispose();
  }

  // Returns different UI layouts depending on the call status
  Widget getBody() {
    switch (callStatus) {

    // UI shown while calling the other user
      case CallStatus.calling:
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Column(
                children: [
                  // User profile picture
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(widget.user.picture),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Calling status text
                  const Text(
                    "Calling...",
                    style: TextStyle(
                      color: Colors.white,
                      shadows: [
                        BoxShadow(color: Colors.black, blurRadius: 3)
                      ],
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ],
          ),
        );

    // UI shown when the call is accepted and ongoing
      case CallStatus.accepted:
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Column(
                children: [
                  // User profile picture
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(widget.user.picture),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call duration counter
                  Countup(
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: [
                        BoxShadow(color: Colors.black, blurRadius: 3)
                      ],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

    // UI shown when the phone is ringing (incoming call)
      case CallStatus.ringing:
        return Column(
          children: [
            const Spacer(),

            // Caller information
            Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(widget.user.picture),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Calling...",
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      BoxShadow(color: Colors.black, blurRadius: 3)
                    ],
                    fontSize: 16,
                  ),
                )
              ],
            ),

            const SizedBox(height: 60),

            // Accept / Decline buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Accept call button
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: greenGradient.lightShade,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LineIcons.phone,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),

                // Decline call button
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LineIcons.phoneSlash,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Decline",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Quick decline message options
            const Text(
              "Decline & Send Message",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 10),

            // Blurred message suggestion panel
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: Container(
                  width: SizeConfig.screenWidth * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: const [
                        SizedBox(height: 10),
                        Text(
                          "I'll call you back",
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Sorry, I can't talk right now",
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background using user's picture
          Container(
            width: SizeConfig.screenWidth,
            height: SizeConfig.screenHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.user.picture),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.white.withOpacity(0.0),
              ),
            ),
          ),

          // Main call UI (depends on call status)
          getBody(),

          // Sliding bottom panel with call controls
          SlidingUpPanel(
            panel: Container(
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  bottomSheetIcons.length,
                      (index) => Icon(
                    bottomSheetIcons[index],
                    color:
                    index == 4 ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ),
            minHeight: 90,
            maxHeight: 200,
            collapsed: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  bottomSheetIcons.length,
                      (index) => Icon(
                    bottomSheetIcons[index],
                    color:
                    index == 4 ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
          ),
        ],
      ),
    );
  }
}
