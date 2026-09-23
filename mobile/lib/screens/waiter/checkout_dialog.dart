import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../models/table.dart';
import '../../widgets/numpad_sheet.dart';

class CheckoutDialog extends StatefulWidget {
  final PosTable table;

  const CheckoutDialog({super.key, required this.table});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  late double _amountToPay;
  String _selectedPaymentMethod = 'CASH'; // "CASH", "CREDIT_CARD", "MEAL_CARD", "CARI"
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountToPay = widget.table.remainingAmount;
  }

  void _onQuickFraction(double fraction) {
    setState(() {
      _amountToPay = (widget.table.remainingAmount * fraction).roundToDouble();
    });
  }

  void _onQuickAmount(double amt) {
    setState(() {
      _amountToPay = amt.clamp(1.0, widget.table.remainingAmount);
    });
  }

  void _onCustomAmount() async {
    final val = await NumpadSheet.show(
      context,
      title: 'Ödenecek Tutar Girin',
      subtitle: 'Kalan Tutar: ₺${widget.table.remainingAmount.toStringAsFixed(2)}',
      initialValue: _amountToPay.toStringAsFixed(0),
    );

    if (val != null && mounted) {
      final parsed = double.tryParse(val) ?? 0.0;
      if (parsed > 0) {
        setState(() {
          _amountToPay = parsed;
        });
      }
    }
  }

  void _confirmPayment() async {
    if (_amountToPay <= 0) return;

    setState(() => _isProcessing = true);
    final pos = context.read<PosProvider>();

    final success = await pos.processPayment(
      amount: _amountToPay,
      paymentMethod: _selectedPaymentMethod,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('₺${_amountToPay.toStringAsFixed(2)} tahsilat kaydedildi!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahsilat gerçekleştirilemedi!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.table.remainingAmount;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesap Tahsilatı',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.table.name} (${widget.table.area})',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder, height: 24),

              // Tutar Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Toplam Hesap:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        Text('₺${widget.table.activeOrderTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ödenen Tutar:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        Text('₺${widget.table.activeOrderPaid.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: AppColors.cardBorder, height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kalan Borç:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        Text(
                          '₺${remaining.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ödenecek Miktar Girişi / Gösterimi
              Text('Tahsil Edilecek Tutar:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _onCustomAmount,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${_amountToPay.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Hızlı Tutar / Parçalı Bölme Butonları
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickBtn('Tamamı', () => _onQuickFraction(1.0)),
                  _buildQuickBtn('1/2 Yarısı', () => _onQuickFraction(0.5)),
                  _buildQuickBtn('1/3', () => _onQuickFraction(1 / 3)),
                  _buildQuickBtn('₺100', () => _onQuickAmount(100.0)),
                  _buildQuickBtn('₺200', () => _onQuickAmount(200.0)),
                  _buildQuickBtn('₺500', () => _onQuickAmount(500.0)),
                ],
              ),
              const SizedBox(height: 16),

              // Ödeme Yöntemi Seçimi
              Text('Ödeme Yöntemi:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodOption('Nakit', 'CASH', Icons.payments_rounded),
                  const SizedBox(width: 8),
                  _buildMethodOption('Kredi Kartı', 'CREDIT_CARD', Icons.credit_card_rounded),
                  const SizedBox(width: 8),
                  _buildMethodOption('Yemek Kartı', 'MEAL_CARD', Icons.fastfood_rounded),
                  const SizedBox(width: 8),
                  _buildMethodOption('Cari', 'CARI', Icons.account_balance_wallet_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Tahsil Et Butonu
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          '₺${_amountToPay.toStringAsFixed(2)} Tahsil Et',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String label, String code, IconData icon) {
    final isSelected = _selectedPaymentMethod == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = code),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
