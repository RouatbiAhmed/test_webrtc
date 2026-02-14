import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/location.dart';
import '../models/user.dart';
import 'call_screen.dart';

User User1Template = User(
    name: "User 1",
    email: "User1@gmail.com",
    gender: "Male",
    phoneNumber: "9999999999",
    birthDate: 498456350,
    location: Location(city: "XXX", postcode: "124001", state: "xxxxx", street: "New Street"),
    username: "User 1",
    password: "password123",
    firstName: "User 1",
    lastName: "User 1",
    title: "Full Stack Developer",
    uuid: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    picture: "https://images.unsplash.com/photo-1453396450673-3fe83d2db2c4?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=387&q=80",
    firebaseToken: "dGRg2SRNQlmQ_FzSdhxoYy:APA91bE9RK7HYZrUzmoMN8FMgILAVOeZ-zje2Jk6MdnroafCbcUsFwPeBmrH6bdPPLOqSLB1N2SDJeH4rQ32BTMLSZCi3jnScJsuDhMZ0PkHddZn_cMBCAo"
);

User User2Template = User(
    name: "User 2",
    email: "user2@gmail.com",
    gender: "Male",
    phoneNumber: "8888888888",
    birthDate: 498456351,
    location: Location(city: "xxxxx", postcode: "124001", state: "xxxx", street: "New Street"),
    username: "User 2",
    password: "password456",
    firstName: "User 2",
    lastName: "User 2",
    title: "Web Developer",
    uuid: "b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6a",
    picture: "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
    firebaseToken: "e4MDJyqDTcGmAv4B59qlNi:APA91bE8u8J1XRFtWR7wWRi3A8U5B19ifw2iCxbcKpa00nMbo4zv_f0Pm9HVlRsRp4-Tj7p4gycqRJOFvrHpWhqhuRchyjWPhbrVm5qUdzoa8GoGo9Snh2o"
);

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

    // 1. Fetch the real FCM token for this device
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print("Error: Could not get FCM token.");
      setState(() { _isLoading = false; });
      return;
    }
    print("Logged in as ${userTemplate.name} with fresh token: $token");

    // 2. Create a User object for the current session
    _currentUser = User.fromUser(userTemplate, newFirebaseToken: token);

    // 3. Update the user's data in Firestore, including the new token
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


    // 4. Determine who the friend is based on UUID
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
          friendId: _friend!.uuid, // Pass friend's ID
          isCaller: true, // This user is initiating the call
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
            ? Column( // Login View
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => _loginAs(User1Template), child: Text("Login as User 1")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _loginAs(User2Template), child: Text("Login as Usr 2")),
          ],
        )
            : Column( // Main View
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

