import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_theme.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';
import 'package:helpdesk_mobile/ui/customer/login_screen.dart';
import 'package:helpdesk_mobile/ui/customer/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: '.env');
  
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
    final authState = ref.watch(customerAuthProvider);

    return MaterialApp(
      title: 'Helpdesk Mobile',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: authState.isAuthenticated
          ? const CustomerDashboardScreen()
          : const CustomerLoginScreen(),
    );
  }
}
