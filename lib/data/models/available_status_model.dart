class AvailableStatusModel {
  final String currentStatus;
  final List<StatusOptionModel> availableStatuses;

  AvailableStatusModel({
    required this.currentStatus,
    required this.availableStatuses,
  });

  factory AvailableStatusModel.fromJson(Map<String, dynamic> json) {
    return AvailableStatusModel(
      currentStatus: json['current_status'] ?? '',
      availableStatuses: json['available_statuses'] != null
          ? (json['available_statuses'] as List)
              .map((e) => StatusOptionModel.fromJson(e))
              .toList()
          : [],
    );
  }

  bool get hasOptions => availableStatuses.isNotEmpty;
  bool get isTerminalStatus => !hasOptions;
}

class StatusOptionModel {
  final String value;
  final String label;
  final String? description;
  final String? requiresPermission;
  final String? requiresRole;

  StatusOptionModel({
    required this.value,
    required this.label,
    this.description,
    this.requiresPermission,
    this.requiresRole,
  });

  factory StatusOptionModel.fromJson(Map<String, dynamic> json) {
    return StatusOptionModel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      description: json['description'],
      requiresPermission: json['requires_permission'],
      requiresRole: json['requires_role'],
    );
  }

  bool get hasPermissionRequirement => requiresPermission != null;
  bool get hasRoleRequirement => requiresRole != null;
}
