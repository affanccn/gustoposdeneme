import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/table.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class TablesAndLogsView extends StatefulWidget {
  const TablesAndLogsView({super.key});

  @override
  State<TablesAndLogsView> createState() => _TablesAndLogsViewState();
}

class _TablesAndLogsViewState extends State<TablesAndLogsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTableDialog() {
    final pos = context.read<PosProvider>();
    final admin = context.read<AdminProvider>();

    final nameController = TextEditingController();
    String area = 'Salon';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Yeni Masa Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Masa Adı', hintText: 'Örn: Masa 5'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: area,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Bölge / Alan'),
                items: ['Salon', 'Teras', 'Bahçe', 'Bar', 'Üst Kat'].map((a) {
                  return DropdownMenuItem(value: a, child: Text(a));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => area = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newTable = PosTable(
                    id: 't-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    area: area,
                    status: 'EMPTY',
                  );
                  await admin.saveTable(newTable);
                  await pos.loadInitialData();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        // Alt Sekmeler: Masalar vs Loglar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(icon: Icon(Icons.table_restaurant_rounded, size: 20), text: 'Masa Yönetimi'),
              Tab(icon: Icon(Icons.security_rounded, size: 20), text: 'Güvenlik & Denetim Logları'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Masa Yönetimi
              _buildTablesTab(pos),

              // 2. Denetim Logları
              _buildLogsTab(admin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTablesTab(PosProvider pos) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTableDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Masa Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pos.tables.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final table = pos.tables[index];
          return GlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(table.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${table.area} • Sıra: ${table.sortOrder}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                StatusBadge.tableStatus(table.status),
                const SizedBox(width: 8),
                if (!table.isEmpty)
                  Text(
                    '₺${table.remainingAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsTab(AdminProvider admin) {
    final logs = admin.auditLogs;
    if (logs.isEmpty) {
      return const Center(child: Text('Kayıtlı log bulunamadı.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(log.createdAt);

        return GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.actionType,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Text(timeStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.description,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'İşlemi Yapan: ${log.actorName}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
