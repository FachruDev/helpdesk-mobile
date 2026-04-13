class EmployeeModel {
  final int id;
  final String name;
  final String? displayName;
  final String email;
  final String? department;
  final String? requestToScope;
  final bool isPriorityRequestTo;

  EmployeeModel({
    required this.id,
    required this.name,
    this.displayName,
    required this.email,
    this.department,
    this.requestToScope,
    this.isPriorityRequestTo = false,
  });

  String get effectiveName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return name;
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name']?.toString(),
      email: json['email'] ?? '',
      department: json['department'],
      requestToScope: json['request_to_scope']?.toString(),
      isPriorityRequestTo: json['is_priority_request_to'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'email': email,
      'department': department,
      'request_to_scope': requestToScope,
      'is_priority_request_to': isPriorityRequestTo,
    };
  }
}
