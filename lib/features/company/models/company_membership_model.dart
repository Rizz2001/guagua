import 'company_model.dart';

class CompanyMembershipModel {
  final String id;
  final String companyId;
  final String userId;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final CompanyModel? company;

  const CompanyMembershipModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    this.status = 'ACTIVE',
    this.joinedAt,
    this.company,
  });

  factory CompanyMembershipModel.fromJson(Map<String, dynamic> json) {
    return CompanyMembershipModel(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'CASHIER',
      status: json['status'] as String? ?? 'ACTIVE',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
      company:
          json['companies'] != null && json['companies'] is Map<String, dynamic>
          ? CompanyModel.fromJson(json['companies'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'role': role,
      'status': status,
    };
  }
}
