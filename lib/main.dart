import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:upda3/common/style/theme.dart';
import 'package:upda3/routes/app_router.dart';
import 'data/services/notification_service.dart';

/// Background message handler for FCM
/// Must be top-level function, not inside a class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env file)
  await dotenv.load();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications & save FCM token to Firestore
  final notificationService = NotificationService();
  await notificationService.initializeAndSaveToken();
  await notificationService.initializeLocalNotifications();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('🔄 Token refreshed: $newToken');
    final notificationService = NotificationService();
    await notificationService.initializeAndSaveToken();
  });

  // Handle foreground messages (app is open)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    await notificationService.showLocalNotification(message);
  });

  // Handle notification taps (app is in background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    _handleNotificationTap(message);
  });

  // Check if app was opened from a notification (app was terminated)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App opened from notification: ${initialMessage.data}');
    _handleNotificationTap(initialMessage);
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// Handle notification tap - open article URL in browser
Future<void> _handleNotificationTap(RemoteMessage message) async {
  final articleUrl = message.data['articleUrl'];

  if (articleUrl != null && articleUrl.isNotEmpty) {
    try {
      final uri = Uri.parse(articleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Opened article: $articleUrl');
      } else {
        print('Cannot launch URL: $articleUrl');
      }
    } catch (e) {
      print('Error opening article: $e');
    }
  }
}

/// Main app widget
///
/// Uses the generated appRouterProvider from app_router.dart
/// Theme is already set up in theme.dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the generated router provider
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Upda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}