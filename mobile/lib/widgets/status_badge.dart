import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.tableStatus(String status) {
    switch (status) {
      case 'OCCUPIED':
        return const StatusBadge(
          label: 'Dolu',
          color: AppColors.primary,
          icon: Icons.people_alt_rounded,
        );
      case 'BILL_REQUESTED':
        return const StatusBadge(
          label: 'Hesap İstendi',
          color: AppColors.info,
          icon: Icons.receipt_long_rounded,
        );
      case 'EMPTY':
      default:
        return const StatusBadge(
          label: 'Boş',
          color: AppColors.textMuted,
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
