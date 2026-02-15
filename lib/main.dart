import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:test_webrtc/newapp/main_screen.dart';
import 'package:test_webrtc/newapp/call_screen.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart'; // Needed for call IDs

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Uuid _uuid = Uuid(); // For generating unique call IDs

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up the listener for Callkit events
  listenToCallkitEvents();

  // You can still listen for foreground messages if you want to handle them differently
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Got a message whilst in the foreground!");
    // When the app is open, you might want to show the incoming call UI directly
    // instead of a system notification. Let's trigger the background handler
    // to keep the logic consistent.
    _firebaseMessagingBackgroundHandler(message);
  });

  runApp(const NewVoiceCallApp());
}

/// The new background handler using flutter_callkit_incoming
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  var payload = message.data;
  var callerName = payload['caller_name'] as String?;
  var roomId = payload['room_id'] as String?;
  var callerUuid = payload['uuid'] as String?; // The UUID of the person calling

  if (callerName == null || roomId == null || callerUuid == null) {
    print("Background message is missing required data.");
    return;
  }

  final callUUID = _uuid.v4(); // Generate a UNIQUE UUID for this specific call
  final caller = (callerUuid == User1Template.uuid) ? User1Template : User2Template;

  final params = CallKitParams(
    id: callUUID,
    nameCaller: callerName,
    appName: 'Test WebRTC',
    avatar: caller.picture,
    handle: 'Incoming Call', // Or you could use a phone number
    type: 0, // 0 for voice call
    duration: 30000, // Ringing duration in milliseconds
    textAccept: 'Accept',
    textDecline: 'Decline',
    extra: <String, dynamic>{
      'callerUuid': callerUuid,
      'roomId': roomId,
    },
    android: const AndroidParams(
      isCustomNotification: true, // ???
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

  // This will show the native incoming call screen
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

void listenToCallkitEvents() {
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    if (event == null) return;

    switch (event.event) {
      case Event.actionCallAccept:
      // --- THIS IS THE CORRECTED AND SAFE LOGIC ---
      // The event.body is a Map<Object?, Object?>, so we must cast it safely.
        if (event.body == null || event.body is! Map) return;

        // Create a new, correctly-typed map from the untyped one.
        final body = Map<String, dynamic>.from(event.body!);

        final callIdForPlugin = body['id'] as String;

        // Similarly, safely cast the 'extra' map.
        if (body['extra'] == null || body['extra'] is! Map) return;
        final extra = Map<String, dynamic>.from(body['extra']);

        final callerUuid = extra['callerUuid'] as String?;
        final roomId = extra['roomId'] as String?;

        // Add null checks for safety.
        if (callerUuid == null || roomId == null) {
          print("Error: Missing callerUuid or roomId in callkit payload.");
          return;
        }

        // 1. IMPORTANT: Inform the plugin that the call is connected.
        FlutterCallkitIncoming.setCallConnected(callIdForPlugin);

        // Determine who is who
        final caller = (callerUuid == User1Template.uuid) ? User1Template : User2Template;
        final currentUser = (callerUuid != User1Template.uuid) ? User1Template : User2Template;

        // 2. Use a more robust navigation method.
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              currentUser: currentUser,
              friendId: caller.uuid, // The friend is the one who called
              isCaller: false, // We are receiving the call
              callId: roomId,
            ),
          ),
              (route) => false, // This predicate removes all previous routes.
        );
        break;

      case Event.actionCallDecline:
        print("Call declined by user.");
        break;

      case Event.actionCallEnded:
        print("Call ended.");
        break;

      case Event.actionCallTimeout:
        print("Call timed out.");
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