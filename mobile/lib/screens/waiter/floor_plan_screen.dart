import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/table.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/numpad_sheet.dart';
import 'pos_order_screen.dart';
import 'checkout_dialog.dart';
import 'transfer_table_dialog.dart';
import '../admin/admin_dashboard_screen.dart';

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().loadInitialData();
    });
  }

  // Yönetici Paneline Geçiş (PIN Korumalı)
  void _openAdminPanel() async {
    final pin = await NumpadSheet.show(
      context,
      title: 'Yönetici Girişi',
      subtitle: 'Yönetim paneline erişmek için PIN girin (Varsayılan: 1234)',
      isPin: true,
    );

    if (pin != null && mounted) {
      final auth = context.read<AuthProvider>();
      final isAuthorized = await auth.verifyAdminPin(pin);

      if (isAuthorized && mounted) {
        auth.setAdminMode();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hatalı PIN veya yönetici yetkiniz bulunmuyor!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Garson Değiştir / Hızlı Kilit
  void _switchWaiter() async {
    final pin = await NumpadSheet.show(
      context,
      title: 'Personel PIN Değiştir',
      subtitle: 'Garson oturumunu değiştirmek için PIN girin',
      isPin: true,
    );

    if (pin != null && mounted) {
      final auth = context.read<AuthProvider>();
      final ok = await auth.loginWithPin(pin);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktif Personel: ${auth.currentUser.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GUSTO POS',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Garson: ${auth.currentUser.name}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Personel Değiştirme Butonu
          IconButton(
            tooltip: 'Personel Değiştir / PIN',
            icon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
            onPressed: _switchWaiter,
          ),

          // Yenileme Butonu
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => pos.loadInitialData(),
          ),

          // Yönetici Paneli Butonu (Ayrı panel geçişi)
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: ElevatedButton.icon(
              onPressed: _openAdminPanel,
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.black),
              label: Text(
                'Yönetici',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: pos.isLoading && pos.tables.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // 1. Özet Metrik Çubuğu
                _buildMetricsBanner(pos),

                // 2. Alan (Bölge) Filtreleme Sekmeleri
                _buildAreaTabs(pos),

                // 3. Masalar Grid Görünümü
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => pos.loadInitialData(),
                    color: AppColors.primary,
                    child: _buildTableGrid(pos),
                  ),
                ),
              ],
            ),
    );
  }

  // Özet İstatistik Çubuğu
  Widget _buildMetricsBanner(PosProvider pos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildMetricItem('Dolu', '${pos.occupiedTablesCount}', AppColors.primary),
          _buildDivider(),
          _buildMetricItem('Hesap', '${pos.billRequestedCount}', AppColors.info),
          _buildDivider(),
          _buildMetricItem('Boş', '${pos.emptyTablesCount}', AppColors.textMuted),
          _buildDivider(),
          _buildMetricItem(
            'Açık',
            '₺${pos.totalOpenRevenue.toStringAsFixed(0)}',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.cardBorder,
    );
  }

  // Alan Sekmeleri (Tümü, Salon, Teras vb.)
  Widget _buildAreaTabs(PosProvider pos) {
    final areas = pos.availableAreas;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: areas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final area = areas[index];
          final isSelected = pos.selectedArea == area;
          return FilterChip(
            label: Text(area),
            selected: isSelected,
            onSelected: (_) => pos.setArea(area),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            checkmarkColor: Colors.black,
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        },
      ),
    );
  }

  // Masalar Grid Görünümü
  Widget _buildTableGrid(PosProvider pos) {
    final tables = pos.filteredTables;

    if (tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Bu alanda masa bulunamadı.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ekran genişliğine göre sütun sayısı (Tablet vs Telefon)
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.95,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableCard(table, pos);
          },
        );
      },
    );
  }

  // Masa Kartı Bileşeni
  Widget _buildTableCard(PosTable table, PosProvider pos) {
    Color cardBorderColor = AppColors.cardBorder;
    Color statusBg = Colors.transparent;

    if (table.isOccupied) {
      cardBorderColor = AppColors.primary.withValues(alpha: 0.6);
      statusBg = AppColors.primary.withValues(alpha: 0.05);
    } else if (table.isBillRequested) {
      cardBorderColor = AppColors.info.withValues(alpha: 0.8);
      statusBg = AppColors.info.withValues(alpha: 0.08);
    }

    return GlassCard(
      backgroundColor: statusBg.withValues(alpha: 0.1),
      borderColor: cardBorderColor,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      onTap: () async {
        await pos.selectTable(table);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PosOrderScreen(table: table),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst Satır: Masa Adı ve Durum Rozeti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      table.area,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.tableStatus(table.status),
            ],
          ),

          // Orta Alan: Süre ve Ürün Sayısı
          if (!table.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    table.durationString.isNotEmpty ? table.durationString : 'Yeni',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${table.activeItemCount} ürün',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 28,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
            ),
          ],

          // Alt Satır: Tutar ve Hızlı Aksiyonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.isEmpty ? 'Masa Boş' : 'Kalan Tutar',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    table.isEmpty ? '₺0.00' : '₺${table.remainingAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: table.isEmpty ? AppColors.textMuted : AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Masa İşlemleri Popup
              if (!table.isEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  onSelected: (val) {
                    if (val == 'pay') {
                      pos.selectTable(table);
                      showDialog(
                        context: context,
                        builder: (_) => CheckoutDialog(table: table),
                      );
                    } else if (val == 'bill') {
                      pos.requestBill(table.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${table.name} için hesap talebi iletildi.')),
                      );
                    } else if (val == 'transfer') {
                      showDialog(
                        context: context,
                        builder: (_) => TransferTableDialog(sourceTable: table),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pay',
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 18, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Ödeme Al'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'bill',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.info),
                          SizedBox(width: 8),
                          Text('Hesap İstendi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'transfer',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Masa Taşı / Birleştir'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
