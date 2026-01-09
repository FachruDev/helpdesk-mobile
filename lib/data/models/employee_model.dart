class EmployeeModel {
  final int id;
  final String name;
  final String email;
  final String? department;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    this.department,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
    };
  }
}
