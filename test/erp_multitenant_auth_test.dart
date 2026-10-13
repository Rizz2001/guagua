import 'package:flutter_test/flutter_test.dart';
import 'package:guagua/features/auth/models/user_model.dart';
import 'package:guagua/features/company/controllers/company_controller.dart';
import 'package:guagua/features/company/models/company_membership_model.dart';
import 'package:guagua/features/company/models/company_model.dart';

void main() {
  group('Fase 1 ERP: Modelos de Empresa & Multi-Tenancy Tests', () {
    test('CompanyModel serializa y deserializa JSON correctamente', () {
      final json = {
        'id': 'comp-100',
        'legal_name': 'Distribuidora Los Llanos C.A.',
        'trade_name': 'Los Llanos Mayorista',
        'rif': 'J-12345678-9',
        'address': 'Av. Bolívar, Barinas',
        'phone': '+584141234567',
        'email': 'contacto@losllanos.com',
        'base_currency': 'USD',
        'is_active': true,
        'created_at': '2026-10-12T12:00:00Z',
      };

      final company = CompanyModel.fromJson(json);

      expect(company.id, 'comp-100');
      expect(company.legalName, 'Distribuidora Los Llanos C.A.');
      expect(company.tradeName, 'Los Llanos Mayorista');
      expect(company.rif, 'J-12345678-9');
      expect(company.baseCurrency, 'USD');
      expect(company.isActive, isTrue);

      final output = company.toJson();
      expect(output['rif'], 'J-12345678-9');
      expect(output['trade_name'], 'Los Llanos Mayorista');
    });

    test('CompanyMembershipModel deserializa datos y relación anidada', () {
      final json = {
        'id': 'mem-1',
        'company_id': 'comp-100',
        'user_id': 'user-55',
        'role': 'ADMIN',
        'status': 'ACTIVE',
        'joined_at': '2026-10-12T15:00:00Z',
        'companies': {
          'id': 'comp-100',
          'legal_name': 'Inversiones Ávila C.A.',
          'trade_name': 'Ávila POS',
          'rif': 'J-98765432-1',
          'address': 'Caracas',
          'phone': '+582120000000',
          'email': 'admin@avila.com',
        },
      };

      final membership = CompanyMembershipModel.fromJson(json);

      expect(membership.id, 'mem-1');
      expect(membership.role, 'ADMIN');
      expect(membership.status, 'ACTIVE');
      expect(membership.company, isNotNull);
      expect(membership.company?.tradeName, 'Ávila POS');
      expect(membership.company?.rif, 'J-98765432-1');
    });

    test(
      'CompanyState y CompanyNotifier gestionan cambio de empresa activa',
      () {
        const compA = CompanyModel(
          id: 'comp-A',
          legalName: 'Empresa A C.A.',
          tradeName: 'Comercial A',
          rif: 'J-11111111-1',
          address: 'Valencia',
          phone: '04121111111',
          email: 'a@test.com',
        );

        const compB = CompanyModel(
          id: 'comp-B',
          legalName: 'Empresa B C.A.',
          tradeName: 'Comercial B',
          rif: 'J-22222222-2',
          address: 'Maracaibo',
          phone: '04122222222',
          email: 'b@test.com',
        );

        const memA = CompanyMembershipModel(
          id: 'mem-A',
          companyId: 'comp-A',
          userId: 'user-1',
          role: 'ADMIN',
          company: compA,
        );

        const memB = CompanyMembershipModel(
          id: 'mem-B',
          companyId: 'comp-B',
          userId: 'user-1',
          role: 'CASHIER',
          company: compB,
        );

        var state = const CompanyState(
          activeCompany: compA,
          memberships: [memA, memB],
        );

        expect(state.activeCompany?.id, 'comp-A');

        // Simular conmutación de empresa
        final targetMem = state.memberships.firstWhere(
          (m) => m.company?.id == 'comp-B',
        );
        state = state.copyWith(activeCompany: targetMem.company);

        expect(state.activeCompany?.id, 'comp-B');
        expect(state.activeCompany?.tradeName, 'Comercial B');
      },
    );

    test('Permisos por rol: ADMIN y SUPERVISOR tienen acceso privilegiado', () {
      const adminRole = UserRole.admin;
      const supervisorRole = UserRole.supervisor;
      const cashierRole = UserRole.cashier;
      const warehouseRole = UserRole.warehouse;

      expect(adminRole.canEditExchangeRate, isTrue);
      expect(adminRole.canViewFinancials, isTrue);
      expect(adminRole.canManageInventory, isTrue);

      expect(supervisorRole.canEditExchangeRate, isTrue);
      expect(supervisorRole.canViewFinancials, isTrue);
      expect(supervisorRole.canManageInventory, isTrue);

      expect(cashierRole.canEditExchangeRate, isFalse);
      expect(cashierRole.canViewFinancials, isFalse);
      expect(cashierRole.canManageInventory, isFalse);

      expect(warehouseRole.canManageInventory, isTrue);
      expect(warehouseRole.canViewFinancials, isFalse);
    });
  });
}
