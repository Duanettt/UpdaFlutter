import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<String?> initializeAndSaveToken() async {
    try {
      print('📢 Requesting notification permission...');

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📢 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        print('📢 Getting FCM token...');
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

  /// Initialize local notifications for foreground display
  Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'upda_channel',
      'Upda Notifications',
      description: 'News article notifications',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      print('Local notification tapped with payload: $payload');
      // Payload will be the article URL
      try {
        final uri = Uri.parse(payload);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('Error opening article from local notification: $e');
      }
    }
  }

  /// Show local notification when app is in foreground
  Future<void> showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'upda_channel',
      'Upda Notifications',
      channelDescription: 'News article notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Article',
      body: message.notification?.body ?? '',
      notificationDetails: notificationDetails,
      payload: message.data['articleUrl'], // Pass article URL as payload
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      print('💾 Saving token to Firestore: $token');

      final docRef = _firestore.collection('device_tokens').doc(token);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists - only update token and timestamp, preserve discover array
        await docRef.update({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Token updated in Firestore (preserving existing topics)');
      } else {
        // New document - create with empty discover array
        await docRef.set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'discover': [],
        });
        print('✅ New token saved to Firestore');
      }
    } catch (e, stackTrace) {
      print('❌ Error saving token to Firestore: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Associates a topic with this device's token
  Future<void> subscribeToTopic(int topicId, String topicName) async {
    try {
      print('📢 SUBSCRIBING to topic: $topicName (ID: $topicId)');

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