class CompanyModel {
  final String id;
  final String legalName;
  final String tradeName;
  final String rif;
  final String address;
  final String phone;
  final String email;
  final String baseCurrency;
  final bool isActive;
  final DateTime? createdAt;

  const CompanyModel({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.rif,
    required this.address,
    required this.phone,
    required this.email,
    this.baseCurrency = 'USD',
    this.isActive = true,
    this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String? ?? '',
      legalName: json['legal_name'] as String? ?? '',
      tradeName: json['trade_name'] as String? ?? '',
      rif: json['rif'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      baseCurrency: json['base_currency'] as String? ?? 'USD',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'legal_name': legalName,
      'trade_name': tradeName,
      'rif': rif,
      'address': address,
      'phone': phone,
      'email': email,
      'base_currency': baseCurrency,
      'is_active': isActive,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? legalName,
    String? tradeName,
    String? rif,
    String? address,
    String? phone,
    String? email,
    String? baseCurrency,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      rif: rif ?? this.rif,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
