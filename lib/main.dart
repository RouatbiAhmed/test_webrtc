import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:test_webrtc/newapp/main_screen.dart';
import 'package:test_webrtc/newapp/call_screen.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart'; // Needed for call IDs


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Uuid _uuid = Uuid();

final MethodChannel _channel = MethodChannel("callkit_channel");

Map<String, dynamic>? _initialCallData;
Future<void> setupCallkitHandler() async {
  _channel.setMethodCallHandler((MethodCall call) async {
    if(call.method == "CALL_ACCEPTED_INTENT"){
      _initialCallData = Map<String, dynamic>.from(call.arguments);
    }
  });
}

Map<String, dynamic>? getAppLaunchCallData() {
  return _initialCallData;
}
//---------

// old one
/*
void setupNativeCallListener() {
  platform.setMethodCallHandler((call) async {
    if (call.method == "callAccepted") {
      final data = Map<String, dynamic>.from(call.arguments);

      final extra = Map<String, dynamic>.from(data['extra'] ?? {});

      final callerUuid = extra['callerUuid'];
      final roomId = extra['roomId'];

      if (callerUuid == null || roomId == null) return;

      final caller = (callerUuid == User1Template.uuid)
          ? User1Template
          : User2Template;

      final currentUser = (callerUuid != User1Template.uuid)
          ? User1Template
          : User2Template;

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
    }
  });
}*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //setupNativeCallListener();
  listenToCallkitEvents();

  await setupCallkitHandler();
  final callData = getAppLaunchCallData();
  print("callData from flutter state $callData");
  print("room from flutter state ${callData?['roomId']}");
  print("caller id from flutter killed state ${callData?['callerUuid']}");

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

class NewVoiceCallApp extends StatelessWidget {
  const NewVoiceCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Voice Call App',
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}











/*

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'calls',
        channelName: 'Incoming Calls',
        channelDescription: 'Notifications for incoming voice calls.',
        defaultColor: Colors.red,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        locked: true,
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
      )
    ],
    debug: true,
  );
  await AwesomeNotifications().requestPermissionToSendNotifications();


  // This is the ONLY listener you should set.
  AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Got a message whilst in the foreground!");
    print("Message data: ${message.data}");

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _firebaseMessagingBackgroundHandler(message);
    }
  });

  runApp(const NewVoiceCallApp());
}

class NotificationController {
  /// This method is called when a notification action is tapped.
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload == null) return;

    if (receivedAction.buttonKeyPressed == 'ACCEPT') {
      final callerUuid = payload['callerUuid'];
      final roomId = payload['roomId'];
      if (callerUuid == null || roomId == null) return;

      final caller = (callerUuid == User1Template.uuid)
          ? User1Template
          : User2Template;

      // The current user is the one receiving the call.
      final currentUser = (callerUuid != User1Template.uuid)
          ? User1Template
          : User2Template;

      // Use the static navigatorKey to navigate to the CallScreen.
      // This is the ONLY place where navigation should happen.
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            currentUser: currentUser,
            friendId: caller.uuid,
            isCaller: false,
            callId: roomId,
          ),
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  var payload = message.data;
  var callerName = payload['caller_name'] as String?;
  var roomId = payload['room_id'] as String?;
  var uuid = payload['uuid'] as String?;

  if (callerName == null || roomId == null || uuid == null) {
    print("Background message is missing required data.");
    return;
  }

  final caller = (uuid == User1Template.uuid)
      ? User1Template
      : User2Template;

  AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 123,
        channelKey: 'calls',
        title: 'Incoming Call',
        body: '$callerName is calling you',
        largeIcon: caller.picture,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Call,
        locked: true,
        autoDismissible: false,
        fullScreenIntent: true,
        payload: {'roomId': roomId, 'callerUuid': uuid},
      ),
      actionButtons: [
        NotificationActionButton(key: 'DECLINE', label: 'Decline', color: Colors.red, actionType: ActionType.DismissAction),
        NotificationActionButton(key: 'ACCEPT', label: 'Accept', color: Colors.green, actionType: ActionType.Default),
      ]);
}

class NewVoiceCallApp extends StatelessWidget {
  const NewVoiceCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the static navigator key
      navigatorKey: navigatorKey,
      title: 'New Voice Call App',
      theme: ThemeData.dark(),
      // Make sure main_screen.dart also uses the global templates
      home: MainScreen(),
    );
  }
}
*/