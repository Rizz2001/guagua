import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../cash_shift/presentation/cash_shift_screen.dart';
import '../../credit/presentation/credit_management_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../pos/presentation/pos_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../suppliers/presentation/supplier_purchases_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PosScreen(),
    DashboardScreen(),
    CreditManagementScreen(),
    InventoryScreen(),
    SupplierPurchaseScreen(),
    CashShiftScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Guagua POS',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          actions: [
            if (user != null)
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.name ?? 'Operador', style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text('Rol: ${user?.role.displayName ?? "Cajero"}'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name.substring(0, 1) ?? 'U',
                    style: const TextStyle(color: AppColors.primaryCharcoal, fontWeight: FontWeight.bold),
                  ),
                ),
                decoration: const BoxDecoration(color: AppColors.primaryCharcoal),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(0, Icons.shopping_cart, 'Punto de Venta (POS)'),
                    if (user?.role.canViewFinancials ?? true) _buildDrawerItem(1, Icons.dashboard, 'Dashboard & Riesgo'),
                    _buildDrawerItem(2, Icons.credit_score, 'Cuentas por Cobrar'),
                    if (user?.role.canManageInventory ?? true) _buildDrawerItem(3, Icons.inventory_2, 'Inventario & Combos'),
                    if (user?.role.canViewFinancials ?? true) _buildDrawerItem(4, Icons.local_shipping, 'Compras (CPP)'),
                    _buildDrawerItem(5, Icons.receipt_long, 'Cierre de Caja X/Z'),
                    _buildDrawerItem(6, Icons.settings, 'Configuración'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          selectedItemColor: AppColors.primaryCharcoal,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'POS'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Riesgo'),
            BottomNavigationBarItem(icon: Icon(Icons.credit_score), label: 'Cobrar'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Caja'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Navigation Rail
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Brand
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCharcoal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guagua POS',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Sistema General',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Navigation Items
                _buildNavItem(0, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Punto de Venta (POS)'),
                if (user?.role.canViewFinancials ?? true)
                  _buildNavItem(1, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard & Riesgo'),
                _buildNavItem(2, Icons.credit_score_outlined, Icons.credit_score, 'Cuentas por Cobrar'),
                if (user?.role.canManageInventory ?? true)
                  _buildNavItem(3, Icons.inventory_2_outlined, Icons.inventory_2, 'Inventario & Combos'),
                if (user?.role.canViewFinancials ?? true)
                  _buildNavItem(4, Icons.local_shipping_outlined, Icons.local_shipping, 'Compras (CPP)'),
                _buildNavItem(5, Icons.receipt_long_outlined, Icons.receipt_long, 'Cierre de Caja X/Z'),
                _buildNavItem(6, Icons.settings_outlined, Icons.settings, 'Configuración'),

                const Spacer(),
                const Divider(height: 1),

                // User Profile & Logout Box
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryCharcoal,
                              child: Text(
                                user.name.substring(0, 1),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.role.displayName,
                                      style: TextStyle(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                          },
                          icon: const Icon(Icons.logout, size: 14),
                          label: const Text('Cerrar Turno', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 32),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main View Content Area
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? AppColors.primaryCharcoal : AppColors.textMuted),
      title: Text(title, style: TextStyle(fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.of(context).pop(); // Close drawer
      },
    );
  }

  Widget _buildNavItem(int index, IconData iconUnselected, IconData iconSelected, String label) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? AppColors.primaryCharcoal : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? iconSelected : iconUnselected,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
