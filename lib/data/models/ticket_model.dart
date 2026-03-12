import 'package:helpdesk_mobile/data/enums/ticket_status.dart';

class TicketModel {
  final String ticketId;
  final String subject;
  final String? message; // Optional - not in list response
  final TicketStatus status;
  final String? replyStatus; // From API: replystatus
  final String? priority; // From API: priority
  final int? categoryId;
  final String? categoryName;
  final int? subCategoryId;
  final String? subCategoryName;
  final String? project;
  final String? requestToUserId;
  final String? requestToOther;
  final String? requestToName; // From API: request_to_name
  final String? envatoSupport;
  final String? customerName;
  final String? customerEmail;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastReply; // From API: last_reply
  final List<TicketReplyModel>? replies;
  final List<AttachmentModel>? attachments;
  // New fields from API update
  final CategoryInfoModel? categoryInfo;
  final RequestToModel? requestTo;
  final TicketTimestampsModel? timestamps;
  final ActivitySummaryModel? activitySummary;
  final SlaSummaryModel? slaSummary;
  final TicketPointsModel? points;
  final TicketPermissionsModel? permissions;

  TicketModel({
    required this.ticketId,
    required this.subject,
    this.message,
    required this.status,
    this.replyStatus,
    this.priority,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.project,
    this.requestToUserId,
    this.requestToOther,
    this.requestToName,
    this.envatoSupport,
    this.customerName,
    this.customerEmail,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.lastReply,
    this.replies,
    this.attachments,
    this.categoryInfo,
    this.requestTo,
    this.timestamps,
    this.activitySummary,
    this.slaSummary,
    this.points,
    this.permissions,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      ticketId: json['ticket_id']?.toString() ?? json['id']?.toString() ?? '',
      subject: json['subject'] ?? '',
      message: json['message'], // Optional in list response
      status: TicketStatus.fromString(json['status'] ?? 'New'),
      replyStatus: json['replystatus'],
      priority: json['priority'],
      categoryId: json['category_id'],
      // category can be string (in list) or object (in detail)
      categoryName: json['category'] is String 
          ? json['category'] 
          : json['category']?['name'] ?? json['category_name'],
      subCategoryId: json['subcategory_id'] ?? json['subscategory'],
      subCategoryName: json['subcategory_name'],
      project: json['project'],
      requestToUserId: json['request_to_user_id']?.toString(),
      requestToOther: json['request_to_other'],
      requestToName: json['request_to_name'],
      envatoSupport: json['envato_support'],
      customerName: json['customer_name'] ?? json['customer']?['name'],
      customerEmail: json['customer_email'] ?? json['customer']?['email'],
      assignedTo: json['assigned_to'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      lastReply: json['last_reply'] != null
          ? DateTime.parse(json['last_reply'])
          : null,
      // Handle both 'replies' (old) and 'comments' (detail API)
      replies: json['comments'] != null
          ? (json['comments'] as List)
              .map((e) => TicketReplyModel.fromJson(e))
              .toList()
          : json['replies'] != null
              ? (json['replies'] as List)
                  .map((e) => TicketReplyModel.fromJson(e))
                  .toList()
              : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => AttachmentModel.fromJson(e))
              .toList()
          : null,
      categoryInfo: json['category_info'] != null
          ? CategoryInfoModel.fromJson(json['category_info'])
          : null,
      requestTo: json['request_to'] != null && json['request_to'] is Map
          ? RequestToModel.fromJson(json['request_to'])
          : null,
      timestamps: json['timestamps'] != null
          ? TicketTimestampsModel.fromJson(json['timestamps'])
          : null,
      activitySummary: json['activity_summary'] != null
          ? ActivitySummaryModel.fromJson(json['activity_summary'])
          : null,
      slaSummary: json['sla_summary'] != null
          ? SlaSummaryModel.fromJson(json['sla_summary'])
          : null,
      points: json['points'] != null
          ? TicketPointsModel.fromJson(json['points'])
          : null,
      permissions: json['permissions'] != null
          ? TicketPermissionsModel.fromJson(json['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'subject': subject,
      'message': message,
      'status': status.value,
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategory_id': subCategoryId,
      'subcategory_name': subCategoryName,
      'project': project,
      'request_to_user_id': requestToUserId,
      'request_to_other': requestToOther,
      'envato_support': envatoSupport,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'replies': replies?.map((e) => e.toJson()).toList(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
    };
  }
}

class TicketReplyModel {
  final int id;
  final String comment;
  final String userName;
  final String userRole;
  final String? userImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<AttachmentModel>? attachments;
  final bool editable;
  final bool isEdited; // From API: is_edited flag

  TicketReplyModel({
    required this.id,
    required this.comment,
    required this.userName,
    required this.userRole,
    this.userImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.attachments,
    this.editable = false,
    this.isEdited = false,
  });

  factory TicketReplyModel.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new format with 'author' object
    String userName = '';
    String userRole = 'customer';
    String? userImageUrl;
    
    if (json['author'] != null) {
      // New format from detail API
      userName = json['author']['name'] ?? '';
      userRole = json['author']['type'] ?? 'customer';
      userImageUrl = json['author']['image_url'];
    } else {
      // Old format
      userName = json['user_name'] ?? json['user']?['name'] ?? '';
      userRole = json['user_role'] ?? json['user']?['role'] ?? 'customer';
      userImageUrl = json['user_image_url'] ?? json['user']?['image_url'];
    }
    
    return TicketReplyModel(
      id: json['id'] ?? 0,
      comment: json['comment'] ?? '',
      userName: userName,
      userRole: userRole,
      userImageUrl: userImageUrl,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => AttachmentModel.fromJson(e))
              .toList()
          : null,
      editable: json['editable'] ?? false,
      isEdited: json['is_edited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'user_name': userName,
      'user_role': userRole,
      'user_image_url': userImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'is_edited': isEdited,
    };
  }
}

class AttachmentModel {
  final int id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;

  AttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? json['name'] ?? '',
      fileUrl: json['file_url'] ?? json['url'] ?? '',
      fileType: json['file_type'] ?? json['type'],
      fileSize: json['file_size'] ?? json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }

  bool get isImage {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }
}

// ---------------------------------------------------------------------------
// New Model Classes (API update)
// ---------------------------------------------------------------------------

class CategoryInfoModel {
  final int id;
  final String name;
  final String? priority;

  CategoryInfoModel({required this.id, required this.name, this.priority});

  factory CategoryInfoModel.fromJson(Map<String, dynamic> json) {
    return CategoryInfoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      priority: json['priority'],
    );
  }
}

class RequestToModel {
  final dynamic userId; // int or String 'other'
  final String? other;
  final String? name;

  RequestToModel({this.userId, this.other, this.name});

  factory RequestToModel.fromJson(Map<String, dynamic> json) {
    return RequestToModel(
      userId: json['user_id'],
      other: json['other'],
      name: json['name'],
    );
  }

  String get displayName => name ?? other ?? userId?.toString() ?? '';
}

class TicketTimestampsModel {
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastReplyAt;
  final DateTime? assignedAt;
  final DateTime? inProgressAt;
  final DateTime? solvedAt;
  final DateTime? reopenAt;
  final DateTime? holdAt;
  final DateTime? closedAt;
  final DateTime? firstResponseAt;

  TicketTimestampsModel({
    this.createdAt,
    this.updatedAt,
    this.lastReplyAt,
    this.assignedAt,
    this.inProgressAt,
    this.solvedAt,
    this.reopenAt,
    this.holdAt,
    this.closedAt,
    this.firstResponseAt,
  });

  static DateTime? _parse(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  factory TicketTimestampsModel.fromJson(Map<String, dynamic> json) {
    return TicketTimestampsModel(
      createdAt: _parse(json['created_at']),
      updatedAt: _parse(json['updated_at']),
      lastReplyAt: _parse(json['last_reply_at']),
      assignedAt: _parse(json['assigned_at']),
      inProgressAt: _parse(json['in_progress_at']),
      solvedAt: _parse(json['solved_at']),
      reopenAt: _parse(json['reopen_at']),
      holdAt: _parse(json['hold_at']),
      closedAt: _parse(json['closed_at']),
      firstResponseAt: _parse(json['first_response_at']),
    );
  }
}

class LastResponderModel {
  final int id;
  final String name;
  final String? email;

  LastResponderModel({required this.id, required this.name, this.email});

  factory LastResponderModel.fromJson(Map<String, dynamic> json) {
    return LastResponderModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
    );
  }
}

class ActivitySummaryModel {
  final int replyCount;
  final bool hasReplies;
  final DateTime? lastReplyAt;
  final LastResponderModel? lastResponder;
  final String workflowState; // 'open', 'on_hold', 'closed'
  final String waitingFor;    // 'customer', 'internal', 'none'
  final bool isWaitingCustomer;
  final bool isWaitingInternal;
  final bool isClosed;
  final bool isOnHold;

  ActivitySummaryModel({
    required this.replyCount,
    required this.hasReplies,
    this.lastReplyAt,
    this.lastResponder,
    required this.workflowState,
    required this.waitingFor,
    required this.isWaitingCustomer,
    required this.isWaitingInternal,
    required this.isClosed,
    required this.isOnHold,
  });

  factory ActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryModel(
      replyCount: json['reply_count'] ?? 0,
      hasReplies: json['has_replies'] ?? false,
      lastReplyAt: json['last_reply_at'] != null
          ? DateTime.tryParse(json['last_reply_at'].toString())
          : null,
      lastResponder: json['last_responder'] != null
          ? LastResponderModel.fromJson(json['last_responder'])
          : null,
      workflowState: json['workflow_state'] ?? 'open',
      waitingFor: json['waiting_for'] ?? 'none',
      isWaitingCustomer: json['is_waiting_customer'] ?? false,
      isWaitingInternal: json['is_waiting_internal'] ?? false,
      isClosed: json['is_closed'] ?? false,
      isOnHold: json['is_on_hold'] ?? false,
    );
  }
}

class SlaSummaryModel {
  final String mode;
  final bool isActive;
  final String? legacyOverdueStatus;
  final bool isOverdue;
  final DateTime? autoOverdueAt;
  final DateTime? firstResponseAt;
  final DateTime? responseDueAt;
  final String? responseStatus;    // 'Met', 'Breached', 'Pending'
  final DateTime? resolutionDueAt;
  final String? resolutionStatus;  // 'Met', 'Breached', 'Pending'
  final bool isPaused;
  final String? pauseReasonCode;
  final String? pauseReasonLabel;
  final String? pauseReasonNote;
  final int? resolutionTargetWorkingDays;
  final int escalationLevel;

  SlaSummaryModel({
    required this.mode,
    required this.isActive,
    this.legacyOverdueStatus,
    required this.isOverdue,
    this.autoOverdueAt,
    this.firstResponseAt,
    this.responseDueAt,
    this.responseStatus,
    this.resolutionDueAt,
    this.resolutionStatus,
    required this.isPaused,
    this.pauseReasonCode,
    this.pauseReasonLabel,
    this.pauseReasonNote,
    this.resolutionTargetWorkingDays,
    required this.escalationLevel,
  });

  static DateTime? _parse(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  factory SlaSummaryModel.fromJson(Map<String, dynamic> json) {
    return SlaSummaryModel(
      mode: json['mode'] ?? '',
      isActive: json['is_active'] ?? false,
      legacyOverdueStatus: json['legacy_overdue_status'],
      isOverdue: json['is_overdue'] ?? false,
      autoOverdueAt: _parse(json['auto_overdue_at']),
      firstResponseAt: _parse(json['first_response_at']),
      responseDueAt: _parse(json['response_due_at']),
      responseStatus: json['response_status'],
      resolutionDueAt: _parse(json['resolution_due_at']),
      resolutionStatus: json['resolution_status'],
      isPaused: json['is_paused'] ?? false,
      pauseReasonCode: json['pause_reason_code'],
      pauseReasonLabel: json['pause_reason_label'],
      pauseReasonNote: json['pause_reason_note'],
      resolutionTargetWorkingDays: json['resolution_target_working_days'],
      escalationLevel: json['escalation_level'] ?? 0,
    );
  }
}

class TicketPointsModel {
  final int? profileId;
  final String? profileName;
  final String? responseStatus;
  final int? responsePoints;
  final DateTime? responseAwardedAt;
  final int? resolutionTargetWorkingDays;
  final String? resolutionStatus;
  final int? resolutionPoints;
  final DateTime? resolutionAwardedAt;
  final int? customerSatisfactionPoints;
  final DateTime? customerSatisfactionAwardedAt;
  final int totalPoints;

  TicketPointsModel({
    this.profileId,
    this.profileName,
    this.responseStatus,
    this.responsePoints,
    this.responseAwardedAt,
    this.resolutionTargetWorkingDays,
    this.resolutionStatus,
    this.resolutionPoints,
    this.resolutionAwardedAt,
    this.customerSatisfactionPoints,
    this.customerSatisfactionAwardedAt,
    required this.totalPoints,
  });

  static DateTime? _parse(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  factory TicketPointsModel.fromJson(Map<String, dynamic> json) {
    return TicketPointsModel(
      profileId: json['profile_id'],
      profileName: json['profile_name'],
      responseStatus: json['response_status'],
      responsePoints: json['response_points'],
      responseAwardedAt: _parse(json['response_awarded_at']),
      resolutionTargetWorkingDays: json['resolution_target_working_days'],
      resolutionStatus: json['resolution_status'],
      resolutionPoints: json['resolution_points'],
      resolutionAwardedAt: _parse(json['resolution_awarded_at']),
      customerSatisfactionPoints: json['customer_satisfaction_points'],
      customerSatisfactionAwardedAt:
          _parse(json['customer_satisfaction_awarded_at']),
      totalPoints: json['total_points'] ?? 0,
    );
  }
}

/// Unified permissions model — works for both customer and internal tickets.
/// Fields not applicable to a particular role will simply be false.
class TicketPermissionsModel {
  // Customer permissions
  final bool canReply;
  final bool canClose;
  final bool canReopen;
  final bool canEditLatestReply;
  final bool canRate;
  // Internal permissions
  final bool canHold;
  final bool canResume;
  final bool canCancel;
  final bool canBackNew;
  final bool canEditResolutionTargetWorkingDays;
  final bool canViewCsat;

  TicketPermissionsModel({
    this.canReply = false,
    this.canClose = false,
    this.canReopen = false,
    this.canEditLatestReply = false,
    this.canRate = false,
    this.canHold = false,
    this.canResume = false,
    this.canCancel = false,
    this.canBackNew = false,
    this.canEditResolutionTargetWorkingDays = false,
    this.canViewCsat = false,
  });

  factory TicketPermissionsModel.fromJson(Map<String, dynamic> json) {
    return TicketPermissionsModel(
      canReply: json['can_reply'] ?? false,
      canClose: json['can_close'] ?? false,
      canReopen: json['can_reopen'] ?? false,
      canEditLatestReply: json['can_edit_latest_reply'] ?? false,
      canRate: json['can_rate'] ?? false,
      canHold: json['can_hold'] ?? false,
      canResume: json['can_resume'] ?? false,
      canCancel: json['can_cancel'] ?? false,
      canBackNew: json['can_back_new'] ?? false,
      canEditResolutionTargetWorkingDays:
          json['can_edit_resolution_target_working_days'] ?? false,
      canViewCsat: json['can_view_csat'] ?? false,
    );
  }
}
