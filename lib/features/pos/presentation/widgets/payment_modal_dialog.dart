import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/utils/currency_engine.dart';
import '../../../cash_shift/controllers/cash_shift_controller.dart';

class PaymentModalDialog extends ConsumerStatefulWidget {
  final double totalUsd;
  final double exchangeRate;
  final List<Map<String, dynamic>> itemsSummary;
  final void Function(bool shouldPrint) onPaymentSuccess;

  const PaymentModalDialog({
    super.key,
    required this.totalUsd,
    required this.exchangeRate,
    required this.itemsSummary,
    required this.onPaymentSuccess,
  });

  @override
  ConsumerState<PaymentModalDialog> createState() => _PaymentModalDialogState();
}

class _PaymentModalDialogState extends ConsumerState<PaymentModalDialog> {
  final TextEditingController _usdCashController = TextEditingController();
  final TextEditingController _vesPagoMovilController = TextEditingController();
  final TextEditingController _zelleController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();

  double _paidUsdCash = 0.0;
  double _paidVesPagoMovil = 0.0;
  double _paidZelleUsd = 0.0;

  @override
  void initState() {
    super.initState();
    _usdCashController.addListener(_recalculate);
    _vesPagoMovilController.addListener(_recalculate);
    _zelleController.addListener(_recalculate);
  }

  void _recalculate() {
    setState(() {
      _paidUsdCash = double.tryParse(_usdCashController.text) ?? 0.0;
      _paidVesPagoMovil = double.tryParse(_vesPagoMovilController.text) ?? 0.0;
      _paidZelleUsd = double.tryParse(_zelleController.text) ?? 0.0;
    });
  }

  @override
  void dispose() {
    _usdCashController.dispose();
    _vesPagoMovilController.dispose();
    _zelleController.dispose();
    _clientPhoneController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cashShiftState = ref.watch(cashShiftProvider);
    final double totalVes = CurrencyEngine.usdToVes(widget.totalUsd, widget.exchangeRate);
    final calculation = CurrencyEngine.calculatePaymentAndChange(
      totalToPayUsd: widget.totalUsd,
      exchangeRate: widget.exchangeRate,
      paidUsdCash: _paidUsdCash,
      paidVesPagoMovil: _paidVesPagoMovil,
      paidZelleUsd: _paidZelleUsd,
      paidCardVes: 0.0,
      fondoCajaUsd: cashShiftState.fondoCajaUsd,
      fondoCajaBs: cashShiftState.fondoCajaBs,
    );

    final bool isComplete = calculation['isComplete'] as bool;
    final double changeUsd = calculation['changeUsd'] as double;
    final double changeVes = calculation['changeVes'] as double;
    final double pendingUsd = calculation['pendingUsd'] as double;
    final double pendingVes = calculation['pendingVes'] as double;
    final double suggestedChangeUsd = calculation['suggestedChangeUsd'] as double;
    final double suggestedChangeVes = calculation['suggestedChangeVes'] as double;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Cobro Multimoneda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Box (USD & VES)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total a Pagar (USD)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '\$${widget.totalUsd.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Equivalente (VES)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Bs. ${totalVes.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreenDark,
                              ),
                            ),
                          ),
                          Text(
                            'Tasa: ${widget.exchangeRate} Bs/USD',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Inputs Métodos de Pago
              Text('Métodos de Pago Ingresados', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),

              TextField(
                controller: _usdCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: r'Efectivo USD ($)',
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.successGreen),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _vesPagoMovilController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Pago Móvil / Transferencia (Bs.)',
                  prefixIcon: Icon(Icons.phone_android, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _zelleController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: r'Zelle / Transferencia USD ($)',
                  prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Change / Pending Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.warningBg.withValues(alpha: 0.4) : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isComplete ? AppColors.warningBorder : AppColors.dangerText,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isComplete ? 'Vuelto Total a Entregar:' : 'Monto Faltante:',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: isComplete ? AppColors.warningText : AppColors.dangerText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isComplete ? '\$${changeUsd.toStringAsFixed(2)} USD' : '\$${pendingUsd.toStringAsFixed(2)} USD',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isComplete ? AppColors.warningText : AppColors.dangerText,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isComplete ? 'Bs. ${changeVes.toStringAsFixed(2)}' : 'Bs. ${pendingVes.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isComplete ? AppColors.warningText : AppColors.dangerText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isComplete && (suggestedChangeUsd > 0 || suggestedChangeVes > 0)) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: AppColors.warningText, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sugerencia: Entregar \$${suggestedChangeUsd.toStringAsFixed(0)} en físico y Bs. ${suggestedChangeVes.toStringAsFixed(2)} por Pago Móvil/Efectivo.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Cliente WhatsApp Opcional
              Text('Datos para Recibo WhatsApp (Opcional)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(labelText: 'Nombre Cliente', hintText: 'Ej. Juan Pérez'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _clientPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono WhatsApp', hintText: '58414...'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isComplete
                          ? () {
                              widget.onPaymentSuccess(false); // Solo cobrar
                              Navigator.of(context).pop();
                              if (_clientPhoneController.text.isNotEmpty) {
                                WhatsAppService.sendDigitalReceipt(
                                  phone: _clientPhoneController.text,
                                  clientName: _clientNameController.text.isEmpty ? 'Cliente' : _clientNameController.text,
                                  receiptId: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
                                  totalUsd: widget.totalUsd,
                                  exchangeRate: widget.exchangeRate,
                                  itemsSummary: widget.itemsSummary,
                                );
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppColors.primaryCharcoal),
                      ),
                      child: const Text('Solo Cobrar', style: TextStyle(color: AppColors.primaryCharcoal, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isComplete
                          ? () {
                              widget.onPaymentSuccess(true); // Cobrar e Imprimir
                              Navigator.of(context).pop();
                              if (_clientPhoneController.text.isNotEmpty) {
                                WhatsAppService.sendDigitalReceipt(
                                  phone: _clientPhoneController.text,
                                  clientName: _clientNameController.text.isEmpty ? 'Cliente' : _clientNameController.text,
                                  receiptId: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
                                  totalUsd: widget.totalUsd,
                                  exchangeRate: widget.exchangeRate,
                                  itemsSummary: widget.itemsSummary,
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCharcoal,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cobrar e Imprimir (\$${widget.totalUsd.toStringAsFixed(2)})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
