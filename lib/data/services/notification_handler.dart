import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/services/fcm_service.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';
import 'package:helpdesk_mobile/states/internal/internal_auth_provider.dart';
import 'package:helpdesk_mobile/ui/customer/ticket_detail_screen.dart';
import 'package:helpdesk_mobile/ui/internal/ticket_detail_screen.dart';

/// Notification Handler untuk routing dan UI handling
/// Compatible dengan FCM HTTP v1 API payload structure
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  // Global navigator key agar bisa navigate dari mana saja
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetRef? _ref;
  
  // Tracking untuk avoid duplicate routing
  final Set<String> _processedNotifications = {};
  DateTime? _lastNavigationTime;

  // Pending notification data (untuk terminated state, navigate setelah app ready)
  Map<String, dynamic>? _pendingNotification;

  /// Initialize notification handler dengan ref
  void initialize(BuildContext context, WidgetRef ref) {
    _ref = ref;

    // Setup callback untuk handle notification tap
    final fcmService = FcmService();
    fcmService.onNotificationTap = _handleNotificationTap;
    
    // Process pending notification jika ada (dari terminated state)
    if (_pendingNotification != null) {
      final pending = _pendingNotification!;
      _pendingNotification = null;
      Future.microtask(() => _handleNotificationTap(pending));
    }
    
    debugPrint('NotificationHandler initialized');
  }

  /// Handle notification tap dan routing
  /// Support FCM v1 payload structure dengan data fields
  void _handleNotificationTap(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // App belum ready, simpan untuk diproses nanti
      _pendingNotification = data;
      debugPrint('Navigator not ready, storing pending notification');
      return;
    }

    final type = data['type'] as String?;
    final ticketId = data['ticket_id'] as String?;
    final sentAt = data['sent_at'] as String?;
    final replyId = data['reply_id']?.toString();

    debugPrint('Handling notification tap:');
    debugPrint('  Type: $type');
    debugPrint('  Ticket ID: $ticketId');

    if (ticketId == null || ticketId.isEmpty) {
      debugPrint('No ticket ID in notification data, ignoring');
      return;
    }

    // Prevent duplicate navigation. If sent_at is missing, fallback to reply_id.
    // If both are missing, use timestamp so a missing sent_at does not block future notifications.
    final dedupeKeyPart = (sentAt != null && sentAt.isNotEmpty)
      ? sentAt
      : (replyId != null && replyId.isNotEmpty)
        ? replyId
        : DateTime.now().microsecondsSinceEpoch.toString();
    final notificationKey = '$type-$ticketId-$dedupeKeyPart';
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
        _navigateToTicketDetail(ticketId);
        break;
      default:
        debugPrint('Unknown notification type: $type');
        if (ticketId.isNotEmpty) {
          _navigateToTicketDetail(ticketId);
        }
    }
  }

  /// Navigate ke ticket detail screen berdasarkan user type
  void _navigateToTicketDetail(String ticketId) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    debugPrint('Navigating to ticket detail: $ticketId');

    // Tentukan user type dari auth state
    final isInternal = _ref?.read(internalAuthProvider).isAuthenticated ?? false;
    final isCustomer = _ref?.read(customerAuthProvider).isAuthenticated ?? false;

    if (isInternal) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => InternalTicketDetailScreen(ticketId: ticketId),
        ),
      );
    } else if (isCustomer) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => CustomerTicketDetailScreen(ticketId: ticketId),
        ),
      );
    } else {
      debugPrint('No authenticated user, cannot navigate to ticket detail');
    }
  }

  /// Show in-app notification (untuk foreground)
  /// Dengan aksi "Lihat" untuk langsung navigate ke ticket
  void showInAppNotification({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final context = nav.context;

    ScaffoldMessenger.of(context).showSnackBar(
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
