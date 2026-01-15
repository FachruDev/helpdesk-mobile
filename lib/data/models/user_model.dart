class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? image;
  final String? imageUrl;
  final String? company;
  final String role;
  final List<String>? roles;
  final bool? canHoldTicket; // For internal users

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.image,
    this.imageUrl,
    this.company,
    required this.role,
    this.roles,
    this.canHoldTicket,
  });

  // Get display role (first role from roles array or role field)
  String get displayRole {
    if (roles != null && roles!.isNotEmpty) {
      return roles!.first;
    }
    return role;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse roles from array or string
    List<String>? rolesList;
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        rolesList = (json['roles'] as List).map((e) => e.toString()).toList();
      } else {
        rolesList = [json['roles'].toString()];
      }
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      image: json['image'],
      imageUrl: json['image_url'],
      company: json['company'],
      role: json['role'] ?? json['user_type'] ?? rolesList?.first ?? 'customer',
      roles: rolesList,
      canHoldTicket: json['can_hold_ticket'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'image': image,
      'image_url': imageUrl,
      'company': company,
      'role': role,
      'roles': roles,
      'can_hold_ticket': canHoldTicket,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? image,
    String? imageUrl,
    String? company,
    String? role,
    List<String>? roles,
    bool? canHoldTicket,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      company: company ?? this.company,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      canHoldTicket: canHoldTicket ?? this.canHoldTicket,
    );
  }
}
