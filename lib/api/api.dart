import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';


class Api {
  // Make sure this IP is correct for your local network
  static const String apiUrl = "http://192.168.1.20:8080";

  // CORRECTED: The function now clearly distinguishes between the caller and the friend.
  static Future<void> sendNotificationRequestToFriendToAcceptCall(
      String roomId, User caller, User friendToCall) async {

    print("[API] Preparing notification. Caller: ${caller.name}, Friend: ${friendToCall.name}");
    print("[API] Sending to friend's token: ${friendToCall.firebaseToken}");

    // This data structure now matches your working Postman request.
    var data = jsonEncode({
      // **Where to send:** Use the FRIEND'S token.
      "fcm_token": friendToCall.firebaseToken,

      // **What to send (the payload):** Use the CALLER'S info.
      "caller_name": caller.name,
      "uuid": caller.uuid, // This is critical for the receiver to know who is calling.
      "caller_id": caller.phoneNumber,
      "caller_id_type": "number",
      "has_video": "false",
      "room_id": roomId,
    });

    try {
      var r = await http.post(
        Uri.parse("$apiUrl/send-notification"),
        body: data,
        headers: {"Content-Type": "application/json"},
      );
      print("[API] Backend response: ${r.body}");
      if (r.statusCode == 200) {
        print("Notification sent successfully");
      }
    } catch (e) {
      print("[API] Error sending notification request: $e");
    }
  }
}
