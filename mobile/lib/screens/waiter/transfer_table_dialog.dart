import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../models/table.dart';

class TransferTableDialog extends StatefulWidget {
  final PosTable sourceTable;

  const TransferTableDialog({super.key, required this.sourceTable});

  @override
  State<TransferTableDialog> createState() => _TransferTableDialogState();
}

class _TransferTableDialogState extends State<TransferTableDialog> {
  String? _selectedTargetTableId;
  bool _isProcessing = false;
  bool _isPartialTransfer = false;
  final Map<String, double> _transferQuantities = {};

  void _onConfirm() async {
    if (_selectedTargetTableId == null) return;
    setState(() => _isProcessing = true);

    final pos = context.read<PosProvider>();
    bool success = false;

    if (_isPartialTransfer && _transferQuantities.isNotEmpty) {
      final itemsToMove = _transferQuantities.entries.map((e) {
        return {
          'orderItemId': e.key,
          'quantityToMove': e.value,
        };
      }).toList();
      success = await pos.partialTransferTable(
        widget.sourceTable.id,
        _selectedTargetTableId!,
        itemsToMove,
      );
    } else {
      success = await pos.transferTable(widget.sourceTable.id, _selectedTargetTableId!);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masa / ürünler başarıyla aktarıldı!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masa aktarımı başarısız oldu.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final candidateTables = pos.tables.where((t) => t.id != widget.sourceTable.id).toList();
    final activeItems = pos.activeOrder?.items.where((i) => i.isActive).toList() ?? [];

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masa Taşı / Birleştir',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            'Kaynak: ${widget.sourceTable.name} (${widget.sourceTable.area}) - ₺${widget.sourceTable.remainingAmount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Taşıma Tipi Seçimi
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Tüm Masayı Taşı'),
                      selected: !_isPartialTransfer,
                      onSelected: (_) => setState(() {
                        _isPartialTransfer = false;
                        _transferQuantities.clear();
                      }),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Kısmi Ürün Aktar'),
                      selected: _isPartialTransfer,
                      onSelected: (_) => setState(() => _isPartialTransfer = true),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hedef Masa Seçici
              DropdownButtonFormField<String>(
                initialValue: _selectedTargetTableId,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  labelText: 'Hedef Masayı Seçin',
                  prefixIcon: Icon(Icons.table_restaurant_rounded, color: AppColors.primary),
                ),
                items: candidateTables.map((t) {
                  final statusText = t.isEmpty ? 'Boş' : 'Dolu (₺${t.remainingAmount.toStringAsFixed(0)})';
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Text('${t.name} (${t.area}) - $statusText'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTargetTableId = val),
              ),
              const SizedBox(height: 14),

              // Kısmi Ürün Aktarma Kalem Listesi
              if (_isPartialTransfer) ...[
                Text(
                  'Aktarılacak Ürünleri Seçin:',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: activeItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Aktarılacak açık sipariş kalemi yok.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: activeItems.length,
                          separatorBuilder: (_, _) => const Divider(color: AppColors.cardBorder, height: 1),
                          itemBuilder: (context, idx) {
                            final item = activeItems[idx];
                            final isChecked = (_transferQuantities[item.id] ?? 0) > 0;

                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _transferQuantities[item.id] = item.quantity;
                                  } else {
                                    _transferQuantities.remove(item.id);
                                  }
                                });
                              },
                              title: Text(item.productName, style: GoogleFonts.inter(fontSize: 13)),
                              subtitle: Text(
                                '${item.quantity.toInt()} adet • ₺${item.totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _selectedTargetTableId == null || _isProcessing ? null : _onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Aktarımı Tamamla'),
        ),
      ],
    );
  }
}
