import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:test_webrtc/newapp/main_screen.dart'; // Point to your new app
import 'package:test_webrtc/newapp/call_screen.dart'; // Import CallScreen for navigation
import 'package:test_webrtc/newapp/main_screen.dart' as app_globals;

import 'models/location.dart';
import 'models/user.dart';


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
