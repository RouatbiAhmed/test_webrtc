import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class Api {
  static const String apiUrl = "http://192.168.1.20:8080";

  // MODIFIED: Function now accepts friend's token and name directly.
  static Future<void> sendNotificationRequestToFriendToAcceptCall({
    required String roomId,
    required User caller,
    required String friendToken,
    required String friendName,
  }) async {
    print("[API] Preparing notification. Caller: ${caller.name}, Friend: $friendName");
    print("[API] Sending to friend's token: $friendToken");

    var data = jsonEncode({
      // **Where to send:** Use the FRIEND'S token.
      "fcm_token": friendToken,

      // **What to send (the payload):** Use the CALLER'S info.
      "caller_name": caller.name,
      "uuid": caller.uuid,
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