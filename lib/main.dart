import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helpdesk_mobile/config/app_theme.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';
import 'package:helpdesk_mobile/states/internal/internal_auth_provider.dart';
import 'package:helpdesk_mobile/ui/customer/login_screen.dart';
import 'package:helpdesk_mobile/ui/customer/dashboard_screen.dart';
import 'package:helpdesk_mobile/ui/internal/dashboard_screen.dart';
import 'package:helpdesk_mobile/data/services/fcm_service.dart';
import 'package:helpdesk_mobile/data/services/notification_handler.dart';

// Top-level background message handler
// HARUS di-define di top-level (tidak boleh di dalam class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase jika belum (untuk background/terminated state)
  await Firebase.initializeApp();
  
  print('[Background] Message received: ${message.messageId}');
  print('[Background] Data: ${message.data}');
  print('[Background] Notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase PERTAMA
  await Firebase.initializeApp();
  
  // PENTING: Register background message handler SEBELUM initialize FCM Service
  // Handler ini akan dipanggil saat app di-close/terminated dan ada notifikasi masuk
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM Service (request permission, get token, setup foreground handler)
  await FcmService().initialize();
  
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAuthState = ref.watch(customerAuthProvider);
    final internalAuthState = ref.watch(internalAuthProvider);

    // Initialize notification handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler().initialize(context, ref);
    });

    // Determine home screen based on authentication status
    Widget homeScreen = const CustomerLoginScreen();
    
    // Check if internal user is authenticated
    if (internalAuthState.isAuthenticated) {
      homeScreen = const InternalDashboardScreen();
    } 
    // Check if customer is authenticated
    else if (customerAuthState.isAuthenticated) {
      homeScreen = const CustomerDashboardScreen();
    }

    return MaterialApp(
      title: 'Helpdesk Mobile',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationHandler.navigatorKey,
      home: homeScreen,
    );
  }
}
