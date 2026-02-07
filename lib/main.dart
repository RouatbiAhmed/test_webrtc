// In /lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:test_webrtc/newapp/main_screen.dart'; // Point to your new app
import 'package:test_webrtc/newapp/call_screen.dart'; // Import CallScreen for navigation
import 'package:test_webrtc/newapp/main_screen.dart' as app_globals;

import 'models/location.dart';
import 'models/user.dart'; // To access user templates

// This needs to be a top-level function (outside of any class)
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  print('Notification action received: ${receivedAction.buttonKeyPressed}');
}


// These templates are moved here to be globally accessible by background handlers.
User yashMakanTemplate = User(
    name: "Yash Makan",
    email: "yashmakan.fake.email@gmail.com",
    gender: "Male",
    phoneNumber: "9999999999",
    birthDate: 498456350,
    location: Location(city: "Rohtak", postcode: "124001", state: "Haryana", street: "New Street"),
    username: "yashmakan",
    password: "password123",
    firstName: "Yash",
    lastName: "Makan",
    title: "Full Stack Developer",
    uuid: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    picture: "https://images.unsplash.com/photo-1453396450673-3fe83d2db2c4?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=387&q=80",
    firebaseToken: "dGRg2SRNQlmQ_FzSdhxoYy:APA91bE9RK7HYZrUzmoMN8FMgILAVOeZ-zje2Jk6MdnroafCbcUsFwPeBmrH6bdPPLOqSLB1N2SDJeH4rQ32BTMLSZCi3jnScJsuDhMZ0PkHddZn_cMBCAo"
);

User rickRollandTemplate = User(
    name: "Rick Rolland",
    email: "rick.fake.email@gmail.com",
    gender: "Male",
    phoneNumber: "8888888888",
    birthDate: 498456351,
    location: Location(city: "Rohtak", postcode: "124001", state: "Haryana", street: "New Street"),
    username: "rickkk",
    password: "password456",
    firstName: "Rick",
    lastName: "Rolland",
    title: "Web Developer",
    uuid: "b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6a",
    picture: "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
    firebaseToken: "e4MDJyqDTcGmAv4B59qlNi:APA91bE8u8J1XRFtWR7wWRi3A8U5B19ifw2iCxbcKpa00nMbo4zv_f0Pm9HVlRsRp4-Tj7p4gycqRJOFvrHpWhqhuRchyjWPhbrVm5qUdzoa8GoGo9Snh2o"
);

/// The navigator key MUST be static and top-level to be accessed from the background.
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

  // This is the ONLY listener you should set.
  AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const NewVoiceCallApp());
}

/// This class is the single source of truth for handling notification actions.
class NotificationController {
  /// This method is called when a notification action is tapped.
  /// It's static and annotated so it can be called from a background isolate.
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload == null) return;

    if (receivedAction.buttonKeyPressed == 'ACCEPT') {
      final callerUuid = payload['callerUuid'];
      final roomId = payload['roomId'];
      if (callerUuid == null || roomId == null) return;

      final caller = (callerUuid == yashMakanTemplate.uuid)
          ? yashMakanTemplate
          : rickRollandTemplate;

      // The current user is the one receiving the call.
      final currentUser = (callerUuid != yashMakanTemplate.uuid)
          ? yashMakanTemplate
          : rickRollandTemplate;

      // Use the static navigatorKey to navigate to the CallScreen.
      // This is the ONLY place where navigation should happen.
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            currentUser: currentUser, // I am the receiver
            friend: caller,          // The person who called me
            isCaller: false,         // I am NOT the caller
            callId: roomId,          // The room to join
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

  final caller = (uuid == yashMakanTemplate.uuid)
      ? yashMakanTemplate
      : rickRollandTemplate;

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

