import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  Position? _currentPosition;
  double _alertRadius = 500;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'crime_alerts_channel',
      'Crime Alerts',
      description: 'Notifications for nearby crime incidents',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save token to Firestore (optional, for targeted notifications)
    // You can save this to the user's document if needed
  }

  // Set user location for proximity checks
  void setUserLocation(Position position) {
    _currentPosition = position;
  }

  // Set alert radius
  void setAlertRadius(double radius) {
    _alertRadius = radius;
  }

  // Listen to crime posts in real-time
  void startListeningToCrimePosts() {
    FirebaseFirestore.instance
        .collection('crime_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _checkAndNotify(data);
        }
      }
    });
  }

  // Check if crime is nearby and notify
  void _checkAndNotify(Map<String, dynamic> crimeData) {
    if (_currentPosition == null) return;

    final lat = crimeData['latitude'] as double?;
    final lon = crimeData['longitude'] as double?;

    if (lat == null || lon == null) return;

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );

    // Only notify if within alert radius
    if (distance <= _alertRadius) {
      _showLocalNotification(crimeData, distance);
    }
  }

  // Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Distance in meters
  }

  // Show local notification
// Show local notification
Future<void> _showLocalNotification(
  Map<String, dynamic> crimeData,
  double distance,
) async {
  final crimeType = crimeData['crimeType'] ?? 'Crime';
  final title = crimeData['title'] ?? 'Crime Alert';
  final location = crimeData['location'] ?? 'Unknown location';

  String distanceText = distance < 1000
      ? '${distance.toInt()}m away'
      : '${(distance / 1000).toStringAsFixed(1)}km away';

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'crime_alerts_channel',
    'Crime Alerts',
    channelDescription: 'Notifications for nearby crime incidents',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(''),
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    '⚠️ $crimeType Alert Nearby',
    '$title • $distanceText • $location',
    details,
    payload: crimeData['id']?.toString(),
  );
}

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    
    if (message.notification != null) {
      _showLocalNotification(
        message.data,
        0, // Distance not available from FCM
      );
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to inbox or specific crime details
    // You can use a navigator key or event bus here
  }

  // Dispose
  void dispose() {
    // Clean up if needed
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
}