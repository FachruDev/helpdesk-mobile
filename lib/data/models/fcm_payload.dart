class FcmPayload {
  final String? type;
  final String? ticketId;
  final String? status;
  final String? replyId;
  final String? actorType;
  final String? actorName;
  final String? clickAction;
  final String? deepLink;
  final String? sentAt;

  FcmPayload({
    this.type,
    this.ticketId,
    this.status,
    this.replyId,
    this.actorType,
    this.actorName,
    this.clickAction,
    this.deepLink,
    this.sentAt,
  });

  /// Parse dari RemoteMessage data
  factory FcmPayload.fromMap(Map<String, dynamic> data) {
    return FcmPayload(
      type: data['type'] as String?,
      ticketId: data['ticket_id'] as String?,
      status: data['status'] as String?,
      replyId: data['reply_id'] as String?,
      actorType: data['actor_type'] as String?,
      actorName: data['actor_name'] as String?,
      clickAction: data['click_action'] as String?,
      deepLink: data['deep_link'] as String?,
      sentAt: data['sent_at'] as String?,
    );
  }

  /// Validate payload completeness
  bool get isValid => type != null && ticketId != null;

  /// Get notification priority based on type
  NotificationPriority get priority {
    switch (type) {
      case 'ticket.created':
      case 'ticket.reply_received':
        return NotificationPriority.high;
      case 'ticket.comment_added':
        return NotificationPriority.high;
      case 'ticket.status_changed':
        return NotificationPriority.medium;
      default:
        return NotificationPriority.low;
    }
  }

  /// Get user-friendly notification type name
  String get typeName {
    switch (type) {
      case 'ticket.created':
        return 'Tiket Baru';
      case 'ticket.status_changed':
        return 'Status Berubah';
      case 'ticket.comment_added':
        return 'Komentar Baru';
      case 'ticket.reply_received':
        return 'Balasan Diterima';
      default:
        return 'Notifikasi';
    }
  }

  /// Get notification channel ID for this type
  String get channelId {
    switch (type) {
      case 'ticket.created':
        return 'helpdesk_new_tickets';
      case 'ticket.status_changed':
        return 'helpdesk_status_updates';
      case 'ticket.comment_added':
      case 'ticket.reply_received':
        return 'helpdesk_messages';
      default:
        return 'helpdesk_notifications';
    }
  }

  /// Check if this is a high priority notification
  bool get isHighPriority => 
      type == 'ticket.created' || 
      type == 'ticket.reply_received' ||
      type == 'ticket.comment_added';

  /// Check if notification involves user action
  bool get requiresUserAction => isHighPriority;

  /// Generate unique notification key for deduplication
  String get uniqueKey => '$type-$ticketId-$sentAt';

  @override
  String toString() {
    return 'FcmPayload(type: $type, ticketId: $ticketId, '
        'status: $status, actorName: $actorName)';
  }

  /// Convert to Map for storage/logging
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'ticket_id': ticketId,
      'status': status,
      'reply_id': replyId,
      'actor_type': actorType,
      'actor_name': actorName,
      'click_action': clickAction,
      'deep_link': deepLink,
      'sent_at': sentAt,
    };
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}
