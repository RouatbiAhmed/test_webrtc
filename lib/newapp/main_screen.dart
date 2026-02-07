import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// IMPORTANT: Make sure the path to your old model is correct
import '../main.dart' as app_main;
import '../models/location.dart';
import '../models/user.dart';
import 'call_screen.dart';

// Copy the User object definitions from your old main.dart
// We will update the tokens dynamically.
User yashMakanTemplate = User(
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
    firebaseToken: "dGRg2SRNQlmQ_FzSdhxoYy:APA91bE9RK7HYZrUzmoMN8FMgILAVOeZ-zje2Jk6MdnroafCbcUsFwPeBmrH6bdPPLOqSLB1N2SDJeH4rQ32BTMLSZCi3jnScJsuDhMZ0PkHddZn_cMBCAo",
    uuid: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    picture:
    "https://images.unsplash.com/photo-1453396450673-3fe83d2db2c4?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=387&q=80");

User rickRollandTemplate = User(
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
    firebaseToken: "e4MDJyqDTcGmAv4B59qlNi:APA91bE8u8J1XRFtWR7wWRi3A8U5B19ifw2iCxbcKpa00nMbo4zv_f0Pm9HVlRsRp4-Tj7p4gycqRJOFvrHpWhqhuRchyjWPhbrVm5qUdzoa8GoGo9Snh2o",
    uuid: "b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6a",
    picture:
    "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2");

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

    // Fetch the real FCM token for this device
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print("Error: Could not get FCM token.");
      setState(() { _isLoading = false; });
      return;
    }
    print("Logged in as ${userTemplate.name} with token: $token");

    // Create a new user object with the real token
    _currentUser = User(
      name: userTemplate.name,
      uuid: userTemplate.uuid,
      picture: userTemplate.picture,
      firebaseToken: token,
      // copy other necessary fields...
      email: userTemplate.email,
      gender: userTemplate.gender,
      phoneNumber: userTemplate.phoneNumber,
      birthDate: userTemplate.birthDate,
      location: userTemplate.location,
      username: userTemplate.username,
      password: userTemplate.password,
      firstName: userTemplate.firstName,
      lastName: userTemplate.lastName,
      title: userTemplate.title,
    );

    // Determine who the friend is
    _friend = (_currentUser!.uuid == yashMakanTemplate.uuid)
        ? app_main.rickRollandTemplate
        : app_main.yashMakanTemplate;
    setState(() { _isLoading = false; });
  }

  void _startCall() {
    if (_currentUser == null || _friend == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          currentUser: _currentUser!,
          friend: _friend!,
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
            ElevatedButton(onPressed: () => _loginAs(yashMakanTemplate), child: Text("Login as Yash")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _loginAs(rickRollandTemplate), child: Text("Login as Rick")),
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

