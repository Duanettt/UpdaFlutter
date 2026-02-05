import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initializeAndSaveToken() async {
    try {
      print('🔔 Requesting notification permission...');

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        print('🔔 Getting FCM token...');
        String? token = await _messaging.getToken();

        if (token != null) {
          print('✅ FCM Token obtained: $token');
          await _saveTokenToFirestore(token);
          return token;
        } else {
          print('❌ FCM token is null');
        }
      } else {
        print('❌ Permission denied: ${settings.authorizationStatus}');
      }

      return null;
    } catch (e, stackTrace) {
      print('❌ Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      print('💾 Saving token to Firestore: $token');

      await _firestore.collection('device_tokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'discover': [],
      }, SetOptions(merge: true));

      print('✅ Token saved to Firestore successfully');
    } catch (e, stackTrace) {
      print('❌ Error saving token to Firestore: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Associates a topic with this device's token
  Future<void> subscribeToTopic(int topicId, String topicName) async {
    try {
      print('🔔 SUBSCRIBING to topic: $topicName (ID: $topicId)');

      String? token = await _messaging.getToken();
      if (token == null) {
        print('❌ No FCM token available');
        return;
      }

      print('✅ FCM Token: $token');

      await _firestore.collection('device_tokens').doc(token).update({
        'discover': FieldValue.arrayUnion([
          {
            'id': topicId,
            'name': topicName,
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully subscribed to topic: $topicName');
    } catch (e, stackTrace) {
      print('❌ Error subscribing to topic: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Removes a topic from this device's subscriptions
  Future<void> unsubscribeFromTopic(int topicId, String topicName) async {
    try {
      String? token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection('device_tokens').doc(token).update({
        'discover': FieldValue.arrayRemove([
          {
            'id': topicId,
            'name': topicName,
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Unsubscribed from topic: $topicName');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}
