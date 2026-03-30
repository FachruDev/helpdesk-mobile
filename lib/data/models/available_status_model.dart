/// Permission set returned inside `available-statuses` endpoint.
class InternalStatusPermissions {
  final bool canReply;
  final bool canHold;
  final bool canResume;
  final bool canCancel;
  final bool canBackNew;
  final bool canEditResolutionTargetWorkingDays;
  final bool canViewCsat;

  InternalStatusPermissions({
    required this.canReply,
    required this.canHold,
    required this.canResume,
    required this.canCancel,
    required this.canBackNew,
    required this.canEditResolutionTargetWorkingDays,
    required this.canViewCsat,
  });

  factory InternalStatusPermissions.fromJson(Map<String, dynamic> json) {
    return InternalStatusPermissions(
      canReply: json['can_reply'] ?? false,
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

/// One option in the `hold_reason_options` list.
class HoldReasonOption {
  final String value;
  final String label;
  final bool requiresNote;

  HoldReasonOption({
    required this.value,
    required this.label,
    required this.requiresNote,
  });

  factory HoldReasonOption.fromJson(Map<String, dynamic> json) {
    return HoldReasonOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      requiresNote: json['requires_note'] ?? false,
    );
  }
}

/// Validation constraints from the `requirements` object.
class AvailableStatusRequirements {
  final bool resolutionTargetEnabled;
  final int resolutionTargetMin;
  final int resolutionTargetMax;
  final bool holdNoteRequiredWhenReasonIsOther;

  AvailableStatusRequirements({
    required this.resolutionTargetEnabled,
    required this.resolutionTargetMin,
    required this.resolutionTargetMax,
    required this.holdNoteRequiredWhenReasonIsOther,
  });

  factory AvailableStatusRequirements.fromJson(Map<String, dynamic> json) {
    final rtwd = json['resolution_target_working_days'];
    return AvailableStatusRequirements(
      resolutionTargetEnabled: rtwd?['enabled'] ?? false,
      resolutionTargetMin: rtwd?['min'] ?? 1,
      resolutionTargetMax: rtwd?['max'] ?? 365,
      holdNoteRequiredWhenReasonIsOther:
          json['hold_note_required_when_reason_is_other'] ?? false,
    );
  }
}

class AvailableStatusModel {
  final String currentStatus;
  final List<StatusOptionModel> availableStatuses;
  final InternalStatusPermissions? permissions;
  final List<HoldReasonOption> holdReasonOptions;
  final AvailableStatusRequirements? requirements;
  final List<String> commonRequiredFields;

  AvailableStatusModel({
    required this.currentStatus,
    required this.availableStatuses,
    this.permissions,
    this.holdReasonOptions = const [],
    this.requirements,
    this.commonRequiredFields = const [],
  });

  factory AvailableStatusModel.fromJson(Map<String, dynamic> json) {
    return AvailableStatusModel(
      currentStatus: json['current_status'] ?? '',
      availableStatuses: json['available_statuses'] != null
          ? (json['available_statuses'] as List)
              .map((e) => StatusOptionModel.fromJson(e))
              .toList()
          : [],
      permissions: json['permissions'] != null
          ? InternalStatusPermissions.fromJson(json['permissions'])
          : null,
      holdReasonOptions: json['hold_reason_options'] != null
          ? (json['hold_reason_options'] as List)
              .map((e) => HoldReasonOption.fromJson(e))
              .toList()
          : [],
      requirements: json['requirements'] != null
          ? AvailableStatusRequirements.fromJson(json['requirements'])
          : null,
      commonRequiredFields: json['common_required_fields'] != null
          ? List<String>.from(json['common_required_fields'])
          : [],
    );
  }

  bool get hasOptions => availableStatuses.isNotEmpty;
  bool get isTerminalStatus => !hasOptions;
  bool get canHold => permissions?.canHold ?? false;
  bool get canEditResolutionTarget =>
      permissions?.canEditResolutionTargetWorkingDays ?? false;
}

class StatusOptionModel {
  final String value;
  final String label;
  final String? description;
  final String? requiresPermission;
  final String? requiresRole;
  final List<String> requiresFields;
  final List<String> optionalFields;

  StatusOptionModel({
    required this.value,
    required this.label,
    this.description,
    this.requiresPermission,
    this.requiresRole,
    this.requiresFields = const [],
    this.optionalFields = const [],
  });

  factory StatusOptionModel.fromJson(Map<String, dynamic> json) {
    return StatusOptionModel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      description: json['description'],
      requiresPermission: json['requires_permission'],
      requiresRole: json['requires_role'],
      requiresFields: json['requires_fields'] != null
          ? List<String>.from(json['requires_fields'])
          : [],
      optionalFields: json['optional_fields'] != null
          ? List<String>.from(json['optional_fields'])
          : [],
    );
  }

  bool get hasPermissionRequirement => requiresPermission != null;
  bool get hasRoleRequirement => requiresRole != null;
  bool get requiresHoldReason => requiresFields.contains('sla_pause_reason_code');
}
