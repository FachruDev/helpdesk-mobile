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
  final DateTime createdAt;
  final List<AttachmentModel>? attachments;

  TicketReplyModel({
    required this.id,
    required this.comment,
    required this.userName,
    required this.userRole,
    required this.createdAt,
    this.attachments,
  });

  factory TicketReplyModel.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new format with 'author' object
    String userName = '';
    String userRole = 'customer';
    
    if (json['author'] != null) {
      // New format from detail API
      userName = json['author']['name'] ?? '';
      userRole = json['author']['type'] ?? 'customer';
    } else {
      // Old format
      userName = json['user_name'] ?? json['user']?['name'] ?? '';
      userRole = json['user_role'] ?? json['user']?['role'] ?? 'customer';
    }
    
    return TicketReplyModel(
      id: json['id'] ?? 0,
      comment: json['comment'] ?? '',
      userName: userName,
      userRole: userRole,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => AttachmentModel.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'user_name': userName,
      'user_role': userRole,
      'created_at': createdAt.toIso8601String(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
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
