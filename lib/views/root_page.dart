import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:hidable/hidable.dart';
import 'package:line_icons/line_icons.dart';
import 'package:test_webrtc/views/profile_page/main_profile_page.dart';
//import 'package:whatsapp_application/views/profile_page/main_profile_page.dart';
import '../constants/colors.dart';
import '../helper/size_config.dart';
import '../main.dart';
import 'call_page/call_list_page.dart';
import 'call_page/calling_page.dart';
import 'home_page/home_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int selectedIndex = 1;
  final ScrollController scrollController = ScrollController();

  // THE OLD "listen()" METHOD AND "_actionStreamSubscription" VARIABLE HAVE BEEN REMOVED.

  @override
  void initState() {
    super.initState(); // It's best practice to call super.initState() first.

    // --- THIS IS THE NEW, CORRECT WAY TO LISTEN FOR NOTIFICATION ACTIONS ---
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        // This is where your old logic goes.
        // The 'message' variable is now called 'receivedAction'.
        if (receivedAction.buttonKeyPressed.startsWith("accept")) {
          Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) => CallAcceptDeclinePage(
              user: user,
              callStatus: CallStatus.accepted,
              roomId: receivedAction.buttonKeyPressed.replaceAll("accept-", ""),
            ),
          ));
        } else if (receivedAction.buttonKeyPressed == "decline") {
          // Handle the decline call action here.
          print("Call declined by user from notification.");
        }
      },
    );

    // --- Your existing Firebase code remains the same ---
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        print('[FCM] token => ' + token);
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      myBackgroundMessageHandler(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        backgroundColor: backgroundColor(context),
        body: getBody(),
        bottomNavigationBar: Hidable(
          child: bottomNavigationBar(),
          controller: scrollController,
        ));
  }

  Widget getBody() {
    switch (selectedIndex) {
      case 0:
        return CallListPage(
          scrollController: scrollController,
        );
      case 1:
        return HomePage(
          scrollController: scrollController,
        );
      case 2:
        return MainProfilePage(
          scrollController: scrollController,
        );
      default:
        return HomePage(
          scrollController: scrollController,
        );
    }
  }

  Widget bottomNavigationBar() {
    return CustomNavigationBar(
      iconSize: 24.0,
      selectedColor: greenColor,
      strokeColor: greenGradient.lightShade.withOpacity(0.6),
      unSelectedColor: const Color(0xff6c788a),
      backgroundColor: backgroundColor(context),
      items: [
        CustomNavigationBarItem(
          icon: const Icon(
            LineIcons.phone,
            size: 24,
          ),
        ),
        CustomNavigationBarItem(
          icon: const Icon(
            LineIcons.sms,
            size: 24,
          ),
        ),
        CustomNavigationBarItem(
          icon: const Icon(
            LineIcons.user,
            size: 24,
          ),
        ),
      ],
      currentIndex: selectedIndex,
      onTap: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}
