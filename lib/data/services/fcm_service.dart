import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:helpdesk_mobile/data/services/fcm_api_service.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callback untuk handle notification tap
  Function(Map<String, dynamic>)? onNotificationTap;

  /// Initialize FCM dan request permission
  /// Support FCM HTTP v1 API (dengan OAuth2 authentication di backend)
  Future<void> initialize() async {
    try {
      // Request permission untuk iOS dan Android 13+
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('FCM: User granted permission');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('FCM: User granted provisional permission');
        }
      } else {
        if (kDebugMode) {
          print('FCM: User declined or has not accepted permission');
        }
        return;
      }

      // Get FCM token (retry jika gagal)
      _fcmToken = await _getFcmToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Listen untuk token refresh dan AUTO RE-REGISTER ke backend
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        final oldToken = _fcmToken;
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed!');
          print('  Old: $oldToken');
          print('  New: $newToken');
        }
        // PENTING: Auto re-register ke backend jika user sedang login
        await _autoReRegisterToken(newToken);
      });

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Set foreground notification presentation options untuk iOS
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization error: $e');
      }
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // Create notification channel untuk Android
    if (Platform.isAndroid) {
      // Create multiple channels untuk different notification types
      final List<AndroidNotificationChannel> channels = [
        const AndroidNotificationChannel(
          'helpdesk_notifications', // default channel
          'Helpdesk Notifications',
          description: 'General helpdesk notifications',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
        const AndroidNotificationChannel(
          'helpdesk_new_tickets',
          'New Tickets',
          description: 'Notifications for new ticket assignments',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
        const AndroidNotificationChannel(
          'helpdesk_status_updates',
          'Status Updates',
          description: 'Notifications for ticket status changes',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
        const AndroidNotificationChannel(
          'helpdesk_messages',
          'Messages & Replies',
          description: 'Notifications for comments and replies',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      ];

      // Create all channels
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        for (var channel in channels) {
          await androidPlugin.createNotificationChannel(channel);
        }
        
        if (kDebugMode) {
          print('Created ${channels.length} notification channels');
        }
      }
    }
  }

  /// Setup message handlers untuk foreground, background, dan terminated
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
        print('Data: ${message.data}');
      }
      _showLocalNotification(message);
    });

    // Note: Background handler sudah di-register di main.dart
    // Tidak perlu register lagi di sini untuk hindari duplikasi

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped (background): ${message.messageId}');
      }
      _handleNotificationData(message.data);
    });

    // Check if app was opened from terminated state via notification
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state: ${message.messageId}');
        }
        _handleNotificationData(message.data);
      }
    });
  }

  /// Show local notification untuk foreground messages
  /// Compatible dengan FCM v1 payload structure
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    if (notification == null) return;

    // Extract additional info dari FCM v1 payload
    final String? ticketId = data['ticket_id'];
    final String? notificationType = data['type'];
    final String? imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;

    // Determine notification channel based on type
    String channelId = 'helpdesk_notifications';
    String channelName = 'Helpdesk Notifications';
    Importance importance = Importance.high;

    // Customize channel berdasarkan notification type untuk better UX
    if (notificationType != null) {
      switch (notificationType) {
        case 'ticket.created':
          channelId = 'helpdesk_new_tickets';
          channelName = 'New Tickets';
          importance = Importance.high;
          break;
        case 'ticket.status_changed':
          channelId = 'helpdesk_status_updates';
          channelName = 'Status Updates';
          importance = Importance.defaultImportance;
          break;
        case 'ticket.comment_added':
        case 'ticket.reply_received':
          channelId = 'helpdesk_messages';
          channelName = 'Messages & Replies';
          importance = Importance.high;
          break;
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for helpdesk tickets and updates',
      importance: importance,
      priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
      enableVibration: true,
      playSound: true,
      // Support image notification jika ada
      styleInformation: imageUrl != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              contentTitle: notification.title,
              summaryText: notification.body,
            )
          : BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
            ),
      // Add ticket ID ke tag untuk notification grouping
      tag: ticketId,
      // Add logging tag
      ticker: notification.title,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Support untuk iOS notification categories (jika diimplementasikan)
      categoryIdentifier: 'TICKET_NOTIFICATION',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: _encodePayload(data),
    );
  }

  /// Encode notification data ke string payload
  String _encodePayload(Map<String, dynamic> data) {
    try {
      return data.entries.map((e) => '${e.key}=${e.value}').join('&');
    } catch (e) {
      return '';
    }
  }

  /// Decode payload string ke map
  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final map = <String, dynamic>{};
      final pairs = payload.split('&');
      for (var pair in pairs) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          map[parts[0]] = parts[1];
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(String payload) {
    final data = _decodePayload(payload);
    _handleNotificationData(data);
  }

  /// Handle notification data dan routing
  void _handleNotificationData(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('Handling notification data: $data');
    }

    // Call callback jika ada
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    }
  }

  /// Get FCM token dengan retry logic
  /// Retry hingga 3x jika gagal untuk memastikan token valid
  Future<String?> _getFcmToken() async {
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) {
            print('FCM token obtained successfully (attempt ${retryCount + 1})');
          }
          return token;
        }
        
        if (kDebugMode) {
          print('FCM token is null or empty (attempt ${retryCount + 1})');
        }
        
        retryCount++; 
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2)); // Exponential backoff
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting FCM token (attempt ${retryCount + 1}): $e');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }
    
    if (kDebugMode) {
      print('Failed to get FCM token after $maxRetries attempts');
    }
    return null;
  }

  /// Get fresh FCM token dari Firebase (WAJIB dipanggil sebelum login)
  /// TIDAK memanggil deleteToken() - hanya request token terbaru
  Future<String?> getOrRefreshToken() async {
    try {
      // Request fresh token dari Firebase (bukan dari cache)
      final freshToken = await _firebaseMessaging.getToken();
      
      if (freshToken != null && freshToken.isNotEmpty) {
        _fcmToken = freshToken;
        if (kDebugMode) {
          print('FCM fresh token obtained: $freshToken');
        }
        return freshToken;
      }
      
      // Fallback: pakai token dari cache jika ada
      if (_fcmToken != null) {
        if (kDebugMode) {
          print('Using cached FCM token: $_fcmToken');
        }
        return _fcmToken;
      }
      
      if (kDebugMode) {
        print('No FCM token available');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting fresh FCM token: $e');
      }
      return _fcmToken; // Fallback to cache
    }
  }

  /// Get device info untuk registration
  /// PENTING: Panggil getOrRefreshToken() dulu sebelum method ini
  Map<String, dynamic> getDeviceInfo() {
    return {
      'fcm_token': _fcmToken,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'app_version': '1.0.0', // TODO: Get from package_info
    };
  }

  /// Auto re-register token ke backend saat onTokenRefresh
  /// Cek apakah user sedang login, jika iya langsung update backend
  Future<void> _autoReRegisterToken(String newToken) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      
      // Cek apakah customer sedang login
      final customerToken = await StorageService.getCustomerToken();
      if (customerToken != null) {
        final success = await FcmApiService.registerCustomerToken(
          token: customerToken,
          fcmToken: newToken,
          platform: platform,
          appVersion: '1.0.0',
        );
        if (kDebugMode) {
          print('Auto re-register customer FCM token: ${success ? "SUCCESS" : "FAILED"}');
        }
        return;
      }
      
      // Cek apakah internal user sedang login
      final internalToken = await StorageService.getInternalToken();
      if (internalToken != null) {
        final success = await FcmApiService.registerInternalToken(
          token: internalToken,
          fcmToken: newToken,
          platform: platform,
          appVersion: '1.0.0',
        );
        if (kDebugMode) {
          print('Auto re-register internal FCM token: ${success ? "SUCCESS" : "FAILED"}');
        }
        return;
      }
      
      if (kDebugMode) {
        print('No active session, skip auto re-register FCM token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error auto re-registering FCM token: $e');
      }
    }
  }

  /// Delete FCM token dari Firebase (HANYA untuk "remove this device")
  /// JANGAN panggil ini saat logout biasa!
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('FCM token DELETED from Firebase (device removed)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }
}
