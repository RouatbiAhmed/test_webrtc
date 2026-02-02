import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:test_webrtc/views/root_page.dart';
import 'package:uuid/uuid.dart';
import 'constants/colors.dart';
import 'models/location.dart';
import 'models/user.dart';

User user = User(
    name: "Yash Makan",
    email: "yashmakan.fake.email@gmail.com",
    gender: "Male",
    phoneNumber: "9999999999",
    birthDate: 498456350,
    location: Location(
        city: "Rohtak",
        postcode: "124001",
        state: "Haryana",
        street: "New Street"),
    username: "yashmakan",
    password: "79aa7b81bcdd14fd98282b810b61312b",
    firstName: "Yash",
    lastName: "Makan",
    title: "Full Stack Developer",
    //firebaseToken: "e1E1sZR4T-ysib46L2idFq:APA91bFRtT1a2Q_HqIWMwN7iKX6TIt4nBHIum3sQPTl3lTYWYx0nSh1khX8Tg0ntOzTWlnZgsh_PowXEKl58MF_9tO2Sn5QFZ_6yRkdiU-B54EgwP680vozB4zfeIEi_vxI4IzOGWKcd",
    firebaseToken: "dnGqIf0WTJ-7zHaj1HAMXV:APA91bFHViIoKU5k52ra_l4aUslgSG_3bQYh_XUZtmCPpjgFQ2EZMKJDA5vjVWt0v2TEuFcBJuoU5JcF73NMpMWcEaeGq3RDq1b6oItNeaKlK2QtV-uZnPg",
    uuid: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    picture:
    "https://images.unsplash.com/photo-1453396450673-3fe83d2db2c4?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=387&q=80");

User rick = User(
    name: "Rick Rolland",
    email: "rick.fake.email@gmail.com",
    gender: "Male",
    phoneNumber: "8888888888",
    birthDate: 498456351,
    location: Location(
        city: "Rohtak",
        postcode: "124001",
        state: "Haryana",
        street: "New Street"),
    username: "rickkk",
    password: "79aa7b81bcdd14fd98282b810b61312a",
    firstName: "Rick",
    lastName: "Rolland",
    title: "Web Developer",
    firebaseToken: "f2Y_kiwCQlat7s7c8i0hdc:APA91bFV2qhTJTimDAz4cJo74mNWsNtpXR6qDjtuM1uUSYTMvgzClu3yaZnBgSeJkcc293XhHb2nQfBetsPcISY1PL0jgEuZ1ey_cSbFX_anERiXBREXiS4",
    uuid: "b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6a",
    picture:
    "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2");

@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage event) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Map message = event.toMap();
  print('backgroundMessage: message => ${message.toString()}');
  var payload = message['data'];
  var roomId = payload['room_id'] as String;
  var callerName = payload['caller_name'] as String;
  var uuid = payload['uuid'] as String?;
  var hasVideo = payload['has_video'] == "true";

  final callUUID = uuid ?? const Uuid().v4();

  AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: '$callerName is calling...',
        body: 'Pick upppp!!!',
      ),
      actionButtons: [
        NotificationActionButton(
          label: 'Decline',
          enabled: false,
          isDangerousOption: true,
          actionType: ActionType.Default,
          key: 'decline',
        ),
        NotificationActionButton(
          label: 'Accept',
          enabled: true,
          actionType: ActionType.Default,
          key: 'accept-$roomId',
        )
      ]
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Whatsapp',
            channelDescription: 'Whatsapp calling',
            defaultColor: greenColor,
            ledColor: Colors.white)
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true
  );
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  runApp(const MyApp());
}

class ScrollGlowEffect extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whatsapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: "SFProText"),
      builder: (context, child) {
        return ScrollConfiguration(behavior: ScrollGlowEffect(), child: child!);
      },
      home: const RootPage(),
    );
  }
}