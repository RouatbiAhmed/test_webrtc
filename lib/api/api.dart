import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class Api {
  static const String apiUrl = "http://192.168.1.20:8080";

  static sendNotificationRequestToFriendToAcceptCall(String roomId, User user) async {
    var data = jsonEncode({
      "uuid": user.uuid,
      "caller_id": user.phoneNumber,
      "caller_name": user.name,
      "caller_id_type": "number",
      "has_video": "false",
      "room_id": roomId,
      "fcm_token": user.firebaseToken
    });
    var r = await http.post(Uri.parse("$apiUrl/send-notification"), body: data, headers: {"Content-Type": "application/json"});
    print(r.body);
  }
}



/*
class Api {
  // IMPORTANT: Replace this with your Server Key from the Firebase Console
  static const String _firebaseServerKey = '';

  static Future<void> sendNotificationRequestToFriendToAcceptCall(
      String roomId, User friendToCall) async {

    // The 'user' object from main.dart is the person making the call (e.g., Yash).
    User caller = main_app.user;

    // The 'friendToCall' is the person receiving the call (e.g., Rick).
    // We need their FCM token to send them the notification.
    String friendFcmToken = friendToCall.firebaseToken;

    if (friendFcmToken.isEmpty) {
      print('[FCM_ERROR] Cannot send notification. Friend\'s FCM token is empty.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // This is the authorization using your server key.
          'Authorization': 'key=$_firebaseServerKey',
        },
        body: jsonEncode(<String, dynamic>{
          // 'to' is the specific device token we are sending the notification to.
          'to': friendFcmToken,
          // 'priority': 'high' is crucial for call notifications on Android.
          'priority': 'high',
          // 'data' is the custom payload your app will receive in the background.
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'room_id': roomId,
            'caller_name': caller.name, // The name of the person calling
            'has_video': 'false',
            'uuid': caller.uuid,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('[FCM_SUCCESS] Notification sent successfully to ${friendToCall.name}.');
      } else {
        print('[FCM_ERROR] Failed to send notification. Status: ${response.statusCode}');
        print('[FCM_ERROR] Body: ${response.body}');
      }
    } catch (e) {
      print('[FCM_ERROR] Exception while sending notification: $e');
    }
  }
}
*/