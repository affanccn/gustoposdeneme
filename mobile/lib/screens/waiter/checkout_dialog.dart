import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/table.dart';
import '../../models/order.dart';
import '../../models/customer.dart';
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

  // Alman Usulü (Ürün Bazlı Ödeme / Split Bill) State'i
  bool _isSplitBilling = false;
  final Map<String, double> _splitQuantities = {};

  // Cari Müşteri State'i
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _amountToPay = widget.table.remainingAmount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().loadCustomers();
    });
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

  // İndirim Uygulama Dialogu (Admin PIN korumalı)
  void _showDiscountDialog() {
    final auth = context.read<AuthProvider>();
    final pos = context.read<PosProvider>();

    String discountType = 'percentage'; // 'percentage' | 'amount'
    final valController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'İndirim Uygula',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('% Yüzde İndirimi'),
                      selected: discountType == 'percentage',
                      onSelected: (_) => setDlgState(() => discountType = 'percentage'),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('₺ Tutar İndirimi'),
                      selected: discountType == 'amount',
                      onSelected: (_) => setDlgState(() => discountType = 'amount'),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: discountType == 'percentage' ? 'İndirim Oranı (%)' : 'İndirim Tutarı (₺)',
                  hintText: discountType == 'percentage' ? 'Örn: 10' : 'Örn: 50',
                ),
              ),
              if (discountType == 'percentage') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [5, 10, 15, 20, 25].map((pct) {
                    return ActionChip(
                      label: Text('%$pct'),
                      onPressed: () => setDlgState(() => valController.text = '$pct'),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final double? numVal = double.tryParse(valController.text.trim());
                if (numVal == null || numVal <= 0) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final pin = await NumpadSheet.show(
                  context,
                  title: 'Yönetici PIN Onayı',
                  subtitle: 'İndirim uygulamak için PIN girin',
                  isPin: true,
                );

                if (pin != null && mounted) {
                  final isAuth = await auth.verifyAdminPin(pin);
                  if (isAuth) {
                    await pos.applyDiscount(discountType, numVal);
                    if (mounted) {
                      setState(() {
                        _amountToPay = widget.table.remainingAmount;
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('İndirim başarıyla uygulandı!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } else if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Hatalı PIN!'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Onayla & Yetkilendir'),
            ),
          ],
        ),
      ),
    );
  }

  // Termal Fiş Önizleme Modalı (GustoPOS 80mm Termal Fiş)
  void _showReceiptPreview(PosOrder? order) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'GUSTO RESTORAN',
                  style: GoogleFonts.courierPrime(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  'Bağdat Caddesi No: 42 Kadıköy / İstanbul',
                  style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                Text('Tel: 0216 555 4433', style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black54)),
                const Divider(color: Colors.black38, thickness: 1, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Masa: ${widget.table.name}', style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
                    Text(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                        style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black)),
                  ],
                ),
                const Divider(color: Colors.black38, thickness: 1, height: 16),

                // Kalemler
                if (order != null)
                  ...order.items.where((i) => i.isActive).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity.toInt()}x ${item.productName}',
                              style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black),
                            ),
                          ),
                          Text(
                            '₺${item.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),

                const Divider(color: Colors.black38, thickness: 1, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOPLAM:', style: GoogleFonts.courierPrime(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('₺${widget.table.activeOrderTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.courierPrime(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                if (widget.table.activeOrderPaid > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ÖDENEN:', style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
                      Text('₺${widget.table.activeOrderPaid.toStringAsFixed(2)}',
                          style: GoogleFonts.courierPrime(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('KALAN:', style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('₺${widget.table.remainingAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                const Divider(color: Colors.black38, thickness: 1, height: 16),
                Text(
                  'BİZİ TERCİH ETTİĞİNİZ İÇİN\nTEŞEKKÜR EDERİZ.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.courierPrime(fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Kapat'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Alman Usulü Seçilen Kalemlerin Toplamını Hesapla
  void _calculateSplitTotal(List<OrderItem> items) {
    double total = 0.0;
    _splitQuantities.forEach((itemId, qty) {
      final match = items.firstWhere((i) => i.id == itemId, orElse: () => OrderItem(id: '', productId: '', productName: '', unitPrice: 0, quantity: 0));
      if (match.id.isNotEmpty) {
        total += match.effectiveUnitPrice * qty;
      }
    });

    setState(() {
      _amountToPay = total.clamp(0.0, widget.table.remainingAmount);
    });
  }

  void _confirmPayment() async {
    if (_amountToPay <= 0) return;

    setState(() => _isProcessing = true);
    final pos = context.read<PosProvider>();

    final success = await pos.processPayment(
      amount: _amountToPay,
      paymentMethod: _selectedPaymentMethod,
      customerId: _selectedMethodIsCari ? _selectedCustomer?.id : null,
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

  bool get _selectedMethodIsCari => _selectedPaymentMethod == 'CARI';

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final remaining = widget.table.remainingAmount;
    final order = pos.activeOrder;
    final items = order?.items.where((i) => i.isActive).toList() ?? [];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık & Fiş Önizleme Butonu
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
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Hesap Fişi Önizle',
                          icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                          onPressed: () => _showReceiptPreview(order),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: AppColors.cardBorder, height: 20),

                // Tutar & İndirim Kartı
                Container(
                  padding: const EdgeInsets.all(14),
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ödenen:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          Text('₺${widget.table.activeOrderPaid.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: AppColors.cardBorder, height: 16),
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
                const SizedBox(height: 12),

                // İndirim Uygula & Alman Usulü Seçenekleri
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDiscountDialog,
                        icon: const Icon(Icons.percent_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          'İndirim Uygula',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text(
                          'Alman Usulü (Ürün Seç)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isSplitBilling ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                        selected: _isSplitBilling,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.black,
                        onSelected: (val) {
                          setState(() {
                            _isSplitBilling = val;
                            if (!_isSplitBilling) {
                              _amountToPay = remaining;
                              _splitQuantities.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Alman Usulü Kalem Listesi (Eğer seçiliyse)
                if (_isSplitBilling) ...[
                  Text(
                    'Ödenecek Ürünleri Seçin:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(color: AppColors.cardBorder, height: 1),
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        final double currentSelected = _splitQuantities[item.id] ?? 0.0;
                        final bool isChecked = currentSelected > 0;

                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          activeColor: AppColors.primary,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            if (val == true) {
                              _splitQuantities[item.id] = item.quantity;
                            } else {
                              _splitQuantities.remove(item.id);
                            }
                            _calculateSplitTotal(items);
                          },
                          title: Text(item.productName, style: GoogleFonts.inter(fontSize: 13)),
                          subtitle: Text(
                            '₺${item.effectiveUnitPrice.toStringAsFixed(2)} x ${item.quantity.toInt()} adet',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Ödenecek Miktar Girişi / Gösterimi
                Text('Tahsil Edilecek Tutar:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _isSplitBilling ? null : _onCustomAmount,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        if (!_isSplitBilling) const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Hızlı Tutar Butonları (Alman usulü aktif değilse)
                if (!_isSplitBilling) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickBtn('Tamamı', () => _onQuickFraction(1.0)),
                      _buildQuickBtn('1/2 Yarısı', () => _onQuickFraction(0.5)),
                      _buildQuickBtn('1/3', () => _onQuickFraction(1 / 3)),
                      _buildQuickBtn('₺100', () => _onQuickAmount(100.0)),
                      _buildQuickBtn('₺200', () => _onQuickAmount(200.0)),
                      _buildQuickBtn('₺500', () => _onQuickAmount(500.0)),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Ödeme Yöntemi Seçimi
                Text('Ödeme Yöntemi:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildMethodOption('Nakit', 'CASH', Icons.payments_rounded),
                    const SizedBox(width: 6),
                    _buildMethodOption('Kredi Kartı', 'CREDIT_CARD', Icons.credit_card_rounded),
                    const SizedBox(width: 6),
                    _buildMethodOption('Yemek Kartı', 'MEAL_CARD', Icons.fastfood_rounded),
                    const SizedBox(width: 6),
                    _buildMethodOption('Cari', 'CARI', Icons.account_balance_wallet_rounded),
                  ],
                ),
                const SizedBox(height: 10),

                // Cari Müşteri Seçimi (Eğer Cari seçiliyse)
                if (_selectedMethodIsCari) ...[
                  Text('Veresiye Müşteri Seçin:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Customer>(
                    initialValue: _selectedCustomer,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      hintText: 'Müşteri seçin...',
                      prefixIcon: Icon(Icons.person_search_rounded, color: AppColors.primary),
                    ),
                    items: pos.customers.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (Borç: ₺${c.balance.toStringAsFixed(0)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Tahsil Et Butonu
                SizedBox(
                  height: 48,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
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
