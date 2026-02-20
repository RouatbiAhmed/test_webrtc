import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import 'call_screen.dart';
import 'models/users_templates.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? _currentUser;
  User? _friend;
  bool _isLoading = false;

  Future<void> _loginAs(User userTemplate) async {
    setState(() { _isLoading = true; });

    // get device FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print("Error: Could not get FCM token.");
      setState(() { _isLoading = false; });
      return;
    }
    print("Logged in as ${userTemplate.name} with fresh token: $token");

    // Create a User object for the current session
    _currentUser = User.fromUser(userTemplate, newFirebaseToken: token);

    // Update the user's data in Firestore, including the new token
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uuid)
          .set(_currentUser!.toMap(), SetOptions(merge: true)); // Use merge to avoid overwriting all data
    } catch (e) {
      print("Error updating user in Firestore: $e");
      setState(() { _isLoading = false; });
      return;
    }


    // Determine who the friend is based on UUID
    _friend = (_currentUser!.uuid == User1Template.uuid)
        ? User2Template
        : User1Template;
    setState(() { _isLoading = false; });
  }


  void _startCall() async {
    if (_currentUser == null || _friend == null) return;

    // We no longer need to pass the friend object, just their ID.
    // The WebRTCManager will fetch the friend's latest data from Firestore.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          currentUser: _currentUser!,
          friendId: _friend!.uuid,
          isCaller: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentUser == null ? "Login" : "Call App")),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _currentUser == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => _loginAs(User1Template), child: Text("Login as User 1")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _loginAs(User2Template), child: Text("Login as Usr 2")),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${_currentUser!.name}", style: TextStyle(fontSize: 24)),
            SizedBox(height: 40),
            ElevatedButton(onPressed: _startCall, child: Text("Call ${_friend!.name}")),
          ],
        ),
      ),
    );
  }
}

