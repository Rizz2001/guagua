import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/print_spooler_service.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _storeNameCtrl = TextEditingController(text: 'Mi Comercial Guagua POS');
  final TextEditingController _rifCtrl = TextEditingController(text: 'J-50192837-0');
  final TextEditingController _phoneCtrl = TextEditingController(text: '584141234567');
  final TextEditingController _addressCtrl = TextEditingController(text: 'Av. Bolivar, Local 12');

  List<Printer> _availablePrinters = [];
  bool _isLoadingPrinters = false;
  bool _is80mm = PrintSpoolerService.is80mm;
  String? _selectedPrinter = PrintSpoolerService.selectedPrinterName;

  bool _useNetworkPrinter = PrintSpoolerService.useNetworkPrinter;
  late final TextEditingController _networkIpCtrl;
  late final TextEditingController _networkPortCtrl;
  bool _igtfEnabled = PrintSpoolerService.igtfEnabled;
  String _activeStore = PrintSpoolerService.activeStoreName;

  @override
  void initState() {
    super.initState();
    _networkIpCtrl = TextEditingController(text: PrintSpoolerService.networkPrinterIp);
    _networkPortCtrl = TextEditingController(text: PrintSpoolerService.networkPrinterPort.toString());
    _loadPrinters();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _rifCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _networkIpCtrl.dispose();
    _networkPortCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoadingPrinters = true);
    try {
      final list = await Printing.listPrinters();
      setState(() {
        _availablePrinters = list;
        _isLoadingPrinters = false;
      });
    } catch (_) {
      setState(() => _isLoadingPrinters = false);
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Gestión de Usuarios'),
          content: const Text('Para registrar nuevos operadores, por favor cierra sesión y utiliza la opción "Registrar Usuario" en la pantalla de inicio.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> _fetchUsers() async {
    final client = SupabaseService().client;
    if (client == null) return [];
    try {
      return await client.from('profiles').select();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingSpoolJobs = PrintSpoolerService.pendingJobsCount;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración General & Enterprise',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hardware de mostrador, gavetas de dinero, régimen fiscal IGTF, sucursales y usuarios.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // 1. GESTIÓN MULTI-SUCURSAL (FASE 4)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_outlined, color: AppColors.primaryCharcoal),
                      const SizedBox(width: 8),
                      Text('Sucursal Activa (Multi-Sucursal & Almacenes)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Define en cuál sucursal o almacén está operando esta terminal de venta.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _activeStore,
                    decoration: const InputDecoration(
                      labelText: 'Sucursal / Almacén Operativo',
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: [
                      'Sucursal Principal - Centro',
                      'Sucursal 2 - Bodegón Este',
                      'Almacén Central (Bodega Distribuidora)'
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _activeStore = val);
                        PrintSpoolerService.activeStoreName = val;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🏢 Sucursal activa conmutada a: $val')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. DATOS DE LA TIENDA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos del Negocio / Comercio', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _storeNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Comercial de la Tienda (Cualquier Sector)',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rifCtrl,
                          decoration: const InputDecoration(labelText: 'RIF / Identificación Fiscal', prefixIcon: Icon(Icons.badge)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Teléfono Comercial WhatsApp', prefixIcon: Icon(Icons.phone)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección Física', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('💾 Datos del comercio guardados exitosamente')),
                      );
                    },
                    child: const Text('Guardar Cambios de Tienda'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. HARDWARE: CONFIGURACIÓN DE IMPRESORA TÉRMICA & GAVETA ESC/POS
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Impresora Térmica & Hardware Mostrador (ESC/POS)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Configura impresoras USB, Bluetooth, LAN Ethernet (puerto 9100) y apertura de gaveta.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Recargar impresoras',
                        onPressed: _loadPrinters,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selector de Formato de Papel (58mm vs 80mm)
                  Row(
                    children: [
                      const Text('Formato de Papel Térmico: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('58 mm (Estándar)'),
                        selected: !_is80mm,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _is80mm = false);
                            PrintSpoolerService.is80mm = false;
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('80 mm (Ancho)'),
                        selected: _is80mm,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _is80mm = true);
                            PrintSpoolerService.is80mm = true;
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Switch para usar Impresora de Red (Ethernet/Wi-Fi LAN)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conexión por Red LAN (Ethernet / Wi-Fi IP)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Impresión directa por socket TCP (puerto 9100) sin depender del driver del sistema.', style: TextStyle(fontSize: 12)),
                    value: _useNetworkPrinter,
                    onChanged: (val) {
                      setState(() => _useNetworkPrinter = val);
                      PrintSpoolerService.useNetworkPrinter = val;
                    },
                  ),

                  if (_useNetworkPrinter) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _networkIpCtrl,
                            decoration: const InputDecoration(labelText: 'Dirección IP de la Impresora', hintText: '192.168.1.100'),
                            onChanged: (val) => PrintSpoolerService.networkPrinterIp = val.trim(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _networkPortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Puerto', hintText: '9100'),
                            onChanged: (val) => PrintSpoolerService.networkPrinterPort = int.tryParse(val) ?? 9100,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Dropdown de impresoras del sistema
                    if (_isLoadingPrinters)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Buscando impresoras en el sistema...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    else if (_availablePrinters.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No se detectaron impresoras instaladas en este dispositivo. La app usará la ventana de impresión del sistema.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPrinter,
                        decoration: const InputDecoration(
                          labelText: 'Impresora Térmica Predeterminada',
                          prefixIcon: Icon(Icons.print),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Predeterminada del Sistema')),
                          ..._availablePrinters.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedPrinter = val);
                          PrintSpoolerService.selectedPrinterName = val;
                        },
                      ),
                  ],

                  const SizedBox(height: 20),

                  // Acciones de Prueba de Impresora y Gaveta
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await PrintSpoolerService.printTestReceipt();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? '🖨️ Ticket de prueba enviado con éxito' : '⚠️ Trabajo guardado en cola o cancelado')),
                            );
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Imprimir Ticket de Prueba'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await PrintSpoolerService.testCashDrawer();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? '💵 Pulso de apertura enviado a la gaveta' : '⚠️ Error al enviar pulso a la gaveta'),
                                backgroundColor: ok ? AppColors.successGreenDark : AppColors.dangerBg,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.point_of_sale, size: 18),
                        label: const Text('Probar Gaveta (Cash Drawer)'),
                      ),
                      if (pendingSpoolJobs > 0) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            await PrintSpoolerService.retryPendingJobs();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reintentando imprimir tickets pendientes...')),
                              );
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: Text('Reintentar Cola ($pendingSpoolJobs pendientes)'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await PrintSpoolerService.clearQueue();
                            setState(() {});
                          },
                          child: const Text('Limpiar Cola', style: TextStyle(color: AppColors.dangerText)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. RÉGIMEN FISCAL & IGTF (FASE 3)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance, color: AppColors.primaryCharcoal),
                      const SizedBox(width: 8),
                      Text('Régimen Fiscal & IGTF (3% Divisas)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Configuración para comercios que aplican el Impuesto a las Grandes Transacciones Financieras.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Habilitar cobro de IGTF (3%)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Aplica el 3% exclusivamente sobre pagos liquidados en divisas en efectivo (\$) o transferencias extranjeras (Zelle). Exenta pagos en bolívares.', style: TextStyle(fontSize: 12)),
                    value: _igtfEnabled,
                    onChanged: (val) {
                      setState(() => _igtfEnabled = val);
                      PrintSpoolerService.igtfEnabled = val;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? '🏛️ IGTF (3%) habilitado en caja' : '🏛️ IGTF deshabilitado')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. GESTIÓN DE USUARIOS Y PERFILES (RBAC)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal & Roles de Seguridad (RBAC)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Lista de perfiles registrados en Supabase con permisos asignados.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Información'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<dynamic>>(
                    future: _fetchUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return const Text('No hay usuarios o no hay conexión a Supabase.');
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final user = users[idx];
                          final name = user['full_name'] ?? 'Desconocido';
                          final email = user['email'] ?? '';
                          final role = user['role'] ?? 'CASHIER';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryCharcoal,
                              child: Text(name.toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text('$email • Rol: $role', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
