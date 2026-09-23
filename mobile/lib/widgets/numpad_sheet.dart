import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class NumpadSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isPin;
  final String initialValue;
  final Function(String value) onConfirm;

  const NumpadSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.isPin = false,
    this.initialValue = '',
    required this.onConfirm,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool isPin = false,
    String initialValue = '',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NumpadSheet(
        title: title,
        subtitle: subtitle,
        isPin: isPin,
        initialValue: initialValue,
        onConfirm: (val) => Navigator.pop(ctx, val),
      ),
    );
  }

  @override
  State<NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<NumpadSheet> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _onDigit(String d) {
    if (widget.isPin && _currentValue.length >= 4) return;
    setState(() {
      _currentValue += d;
    });
  }

  void _onDelete() {
    if (_currentValue.isNotEmpty) {
      setState(() {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _currentValue = '';
    });
  }

  Widget _buildKey(String label, {VoidCallback? onTap, Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Material(
          color: color ?? AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap ?? () => _onDigit(label),
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme Tutamacı
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Başlık
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 18),

            // Ekran / Gösterge
            Container(
              height: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: widget.isPin
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _currentValue.length;
                        return Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? AppColors.primary : AppColors.surfaceLight,
                            border: Border.all(
                              color: filled ? AppColors.primaryLight : AppColors.cardBorder,
                            ),
                          ),
                        );
                      }),
                    )
                  : Text(
                      _currentValue.isEmpty ? '0.00' : '₺$_currentValue',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Tuş Takımı
            Row(
              children: [
                _buildKey('1'),
                _buildKey('2'),
                _buildKey('3'),
              ],
            ),
            Row(
              children: [
                _buildKey('4'),
                _buildKey('5'),
                _buildKey('6'),
              ],
            ),
            Row(
              children: [
                _buildKey('7'),
                _buildKey('8'),
                _buildKey('9'),
              ],
            ),
            Row(
              children: [
                widget.isPin
                    ? _buildKey('C', onTap: _onClear, color: AppColors.surface, textColor: AppColors.danger)
                    : _buildKey('.', onTap: () => _onDigit('.')),
                _buildKey('0'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          child: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Onay Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _currentValue.isEmpty ? null : () => widget.onConfirm(_currentValue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Onayla',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
