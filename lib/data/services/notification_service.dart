import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/presentation/screens/notifications/pt_notifications_screen.dart';

/// A tiny global key that lets us navigate from anywhere.
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'pt_requests',
    'PT Requests',
    description: 'Notifications for PT client requests',
    importance: Importance.high,
  );

  int _counter = 0;

  /// must be called *before* runApp()
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      // foreground & background taps (UI isolate)
      onDidReceiveNotificationResponse: _handleTap,
      // background-isolate handler (do NOT navigate here)
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    // Android / iOS runtime permissions & channel
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Show a high-priority banner that, when tapped, opens PTNotificationsScreen.
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final detail =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final user = FirebaseAuth.instance.currentUser;

    // Use a *named* route as the payload – easy to parse later.
    await _plugin.show(
      _counter++,
      title,
      body,
      detail,
      payload: user?.uid, // 👈 route we’ll push on tap
    );
  }

  // ---------- private helpers ---------- //

  /// Runs on the UI isolate for *all* taps except cold-start ones.
  void _handleTap(NotificationResponse response) {
    final payload = response.payload;
    print('Notification tapped with payload: $payload');
    if (payload == null) return;    
    
    Navigator.push(
      globalNavigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => PTNotificationsScreen(ptId: payload),
      ),
    );
  }

  /// Runs on a *background* isolate (Android only). Do NOT navigate here.
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    // keep empty or do light logging – heavy work & navigation are NOT allowed
  }

  /// Expose the plugin for `getNotificationAppLaunchDetails()` in main.dart.
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}
