import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import 'call_screen.dart';
import 'main_screen.dart';
import 'models/users_templates.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Uuid _uuid = Uuid();
final MethodChannel _channel = MethodChannel("callkit_channel");
Map<String, dynamic>? _killedStateCallData;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  listenToCallkitEvents();

  await setupKilledStateHandler();
  final callData = _killedStateCallData;

  if(callData != null){
    final callerUuid = callData['callerUuid'];
    final roomId = callData['roomId'];

    final caller = (callerUuid == User1Template.uuid)
        ? User1Template
        : User2Template;

    final currentUser = (callerUuid != User1Template.uuid)
        ? User1Template
        : User2Template;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            currentUser: currentUser,
            friendId: caller.uuid,
            isCaller: false,
            callId: roomId,
          ),
        ),
            (route) => false,
      );
  });
  }

  runApp(const NewVoiceCallApp());
}

class NewVoiceCallApp extends StatelessWidget {
  const NewVoiceCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Call App',
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}


Future<void> setupKilledStateHandler() async {
  _channel.setMethodCallHandler((MethodCall call) async {
    if(call.method == "CALL_ACCEPTED_INTENT"){
      _killedStateCallData = Map<String, dynamic>.from(call.arguments);
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  var payload = message.data;
  var callerName = payload['caller_name'] as String?;
  var roomId = payload['room_id'] as String?;
  var callerUuid = payload['uuid'] as String?;

  if (callerName == null || roomId == null || callerUuid == null) {
    print("Background message is missing required data.");
    return;
  }

  final callUUID = _uuid.v4();
  final caller = (callerUuid == User1Template.uuid) ? User1Template : User2Template;

  final params = CallKitParams(
    id: callUUID,
    nameCaller: callerName,
    appName: 'Test WebRTC',
    avatar: caller.picture,
    handle: 'Incoming Call',
    type: 0,
    duration: 30000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    extra: <String, dynamic>{
      'callerUuid': callerUuid,
      'roomId': roomId,
    },
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: false,
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

void listenToCallkitEvents() {
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    if (event == null) return;

    switch (event.event) {
      case Event.actionCallAccept:
        if (event.body == null || event.body is! Map) return;
        final body = Map<String, dynamic>.from(event.body!);
        if (body['extra'] == null || body['extra'] is! Map) return;

        final extra = Map<String, dynamic>.from(body['extra']);
        final callerUuid = extra['callerUuid'] as String?;
        final roomId = extra['roomId'] as String?;
        if (callerUuid == null || roomId == null) return;

        FlutterCallkitIncoming.setCallConnected(body['id'] as String);

        final caller = (callerUuid == User1Template.uuid) ? User1Template : User2Template;
        final currentUser = (callerUuid != User1Template.uuid) ? User1Template : User2Template;

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              currentUser: currentUser,
              friendId: caller.uuid,
              isCaller: false,
              callId: roomId,
            ),
          ),
              (route) => false,
        );
        break;

      case Event.actionCallDecline:
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        break;

      default:
        break;
    }
  });
}
