enum UserRole {
  customer('customer'),
  internal('internal');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'internal':
      case 'employee':
      case 'agent':
        return UserRole.internal;
      default:
        return UserRole.customer;
    }
  }
}
