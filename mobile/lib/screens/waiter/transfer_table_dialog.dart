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

  void _onConfirm() async {
    if (_selectedTargetTableId == null) return;
    setState(() => _isProcessing = true);

    final pos = context.read<PosProvider>();
    final success = await pos.transferTable(widget.sourceTable.id, _selectedTargetTableId!);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masa başarıyla aktarıldı/birleştirildi!'),
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
    // Hedef masalar (kaynak masa hariç tüm masalar)
    final candidateTables = pos.tables.where((t) => t.id != widget.sourceTable.id).toList();

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
        child: candidateTables.isEmpty
            ? const Text('Aktarılabilecek başka masa bulunamadı.')
            : DropdownButtonFormField<String>(
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
