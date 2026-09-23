import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/glass_card.dart';

class WorkdayView extends StatelessWidget {
  const WorkdayView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vardiya Durum Kartı
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          borderColor: admin.isWorkDayOpen ? AppColors.success.withValues(alpha: 0.4) : AppColors.danger.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: admin.isWorkDayOpen ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        admin.isWorkDayOpen ? 'GÜN AÇIK (Vardiya Devam Ediyor)' : 'GÜN KAPALI (Vardiya Bitti)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: admin.isWorkDayOpen ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Vardiya #1042',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                admin.isWorkDayOpen
                    ? 'GustoPOS vardiya sistemi sayesinde gece 00:00 sonrasına sarkan adisyonlar gün sonu kapanana kadar aynı iş gününün Z Raporuna yazılır.'
                    : 'Yeni bir satış günü başlatmak için aşağıdaki butona basarak gün açılışını gerçekleştirin.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Gün Sonu / Gün Başı Butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (admin.isWorkDayOpen) {
                      _showEndDayDialog(context, admin);
                    } else {
                      admin.startWorkDay();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yeni gün / vardiya başlatıldı!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    admin.isWorkDayOpen ? Icons.lock_clock_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                  ),
                  label: Text(
                    admin.isWorkDayOpen ? 'Günü Kapat & Z Raporu Al' : 'Yeni Gün Başlat',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: admin.isWorkDayOpen ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Z Raporu Önizleme
        Text(
          'Mevcut Gün Z Raporu Özeti',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 14,
          child: Column(
            children: [
              _buildZRow('İşletme:', 'GUSTO RESTORAN & KAFE'),
              _buildZRow('Başlangıç Saati:', 'Bugün 08:30'),
              _buildZRow('Kasiyer / Yetkili:', 'Yönetici (Admin)'),
              const Divider(color: AppColors.cardBorder, height: 20),
              _buildZRow('Toplam Kapatılan Ciro:', '₺14,850.00', isBold: true, color: AppColors.success),
              _buildZRow('Nakit Tahsilat:', '₺6,200.00'),
              _buildZRow('Kredi Kartı Tahsilat:', '₺7,150.00'),
              _buildZRow('Yemek Kartı Tahsilat:', '₺1,100.00'),
              _buildZRow('Veresiye / Cari:', '₺400.00'),
              const Divider(color: AppColors.cardBorder, height: 20),
              _buildZRow('Toplam Adisyon Adedi:', '64 Adet'),
              _buildZRow('İptal / İkram Tutarı:', '₺680.00', color: AppColors.danger),
            ],
          ),
        ),
      ],
    );
  }

  void _showEndDayDialog(BuildContext context, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Günü Kapatmak İstiyor Musunuz?'),
        content: const Text(
          'Gün sonu kapatıldığında Z Raporu kesinleşir ve kasadaki tüm hareketler kilitlenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              admin.endWorkDay();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gün başarıyla kapatıldı ve Z Raporu oluşturuldu!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Evet, Günü Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildZRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
