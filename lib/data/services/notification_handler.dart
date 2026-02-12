import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/services/fcm_service.dart';

/// Notification Handler untuk routing dan UI handling
/// Compatible dengan FCM HTTP v1 API payload structure
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  BuildContext? _context;
  WidgetRef? _ref;
  
  // Tracking untuk avoid duplicate routing
  final Set<String> _processedNotifications = {};
  DateTime? _lastNavigationTime;

  /// Initialize notification handler dengan context dan ref
  void initialize(BuildContext context, WidgetRef ref) {
    _context = context;
    _ref = ref;

    // Setup callback untuk handle notification tap
    final fcmService = FcmService();
    fcmService.onNotificationTap = _handleNotificationTap;
    
    debugPrint('NotificationHandler initialized');
  }

  /// Handle notification tap dan routing
  /// Support FCM v1 payload structure dengan data fields
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (_context == null || !_context!.mounted) return;

    final type = data['type'] as String?;
    final ticketId = data['ticket_id'] as String?;
    final deepLink = data['deep_link'] as String?;
    final sentAt = data['sent_at'] as String?;

    debugPrint('Handling notification tap:');
    debugPrint('  Type: $type');
    debugPrint('  Ticket ID: $ticketId');
    debugPrint('  Deep Link: $deepLink');
    debugPrint('  Sent At: $sentAt');

    if (ticketId == null) {
      debugPrint('No ticket ID in notification data, ignoring');
      return;
    }

    // Prevent duplicate navigation (debounce 2 seconds)
    final notificationKey = '$type-$ticketId-$sentAt';
    if (_processedNotifications.contains(notificationKey)) {
      debugPrint('Notification already processed, ignoring duplicate');
      return;
    }
    
    final now = DateTime.now();
    if (_lastNavigationTime != null && 
        now.difference(_lastNavigationTime!).inSeconds < 2) {
      debugPrint('Navigation throttled, too soon after last navigation');
      return;
    }

    // Mark as processed
    _processedNotifications.add(notificationKey);
    _lastNavigationTime = now;
    
    // Clean old entries (keep last 50)
    if (_processedNotifications.length > 50) {
      final list = _processedNotifications.toList();
      _processedNotifications.clear();
      _processedNotifications.addAll(list.skip(list.length - 25));
    }

    // Route berdasarkan tipe notifikasi dari FCM v1 payload
    switch (type) {
      case 'ticket.created':
      case 'ticket.status_changed':
      case 'ticket.comment_added':
      case 'ticket.reply_received':
        _navigateToTicketDetail(ticketId, type: type);
        break;
      default:
        debugPrint('Unknown notification type: $type');
        // Still try to navigate to ticket if we have ticketId
        if (ticketId.isNotEmpty) {
          _navigateToTicketDetail(ticketId);
        }
    }
  }

  /// Navigate ke ticket detail screen
  /// TODO: Implement proper navigation based on user type (customer/internal)
  void _navigateToTicketDetail(String ticketId, {String? type}) {
    if (_context == null || !_context!.mounted) return;

    // Import screens dinamis untuk menghindari circular dependency
    // Perlu di-adjust sesuai dengan screen yang ada
    
    debugPrint('Navigating to ticket detail: $ticketId (type: $type)');
    
    // TODO: Implement proper navigation
    // Contoh routing ke ticket detail:
    // 
    // // Check auth state untuk tau user type
    // final customerAuth = _ref?.read(customerAuthProvider);
    // final internalAuth = _ref?.read(internalAuthProvider);
    // 
    // if (internalAuth?.isAuthenticated ?? false) {
    //   Navigator.push(
    //     _context!,
    //     MaterialPageRoute(
    //       builder: (context) => InternalTicketDetailScreen(ticketId: ticketId),
    //     ),
    //   );
    // } else if (customerAuth?.isAuthenticated ?? false) {
    //   Navigator.push(
    //     _context!,
    //     MaterialPageRoute(
    //       builder: (context) => CustomerTicketDetailScreen(ticketId: ticketId),
    //     ),
    //   );
    // }
    
    // Temporary feedback
    showInAppNotification(
      title: 'Notification Tapped',
      body: 'Opening ticket $ticketId...',
    );
  }

  /// Show in-app notification (optional, untuk foreground)
  void showInAppNotification({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: onTap != null
            ? SnackBarAction(
                label: 'Lihat',
                onPressed: onTap,
              )
            : null,
      ),
    );
  }
}
