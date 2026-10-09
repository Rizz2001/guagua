enum UserRole {
  admin,
  supervisor,
  cashier,
  warehouse,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.cashier:
        return 'Cajero';
      case UserRole.warehouse:
        return 'Bodeguero';
    }
  }

  bool get canEditExchangeRate => this == UserRole.admin || this == UserRole.supervisor;
  bool get canViewFinancials => this == UserRole.admin || this == UserRole.supervisor;
  bool get canManageInventory => this == UserRole.admin || this == UserRole.supervisor || this == UserRole.warehouse;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String pin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.pin,
  });
}
