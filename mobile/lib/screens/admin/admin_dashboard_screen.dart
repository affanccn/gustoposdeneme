import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import 'reports_view.dart';
import 'workday_view.dart';
import 'menu_management_view.dart';
import 'tables_and_logs_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAdminData();
    });
  }

  void _showServerSettings() async {
    final currentUrl = await StorageService.getServerUrl();
    final isDemo = await StorageService.isDemoMode();

    if (!mounted) return;
    final urlController = TextEditingController(text: currentUrl);
    bool demoModeVal = isDemo;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Sunucu ve Bağlantı Ayarları',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Next.js Backend API URL',
                  hintText: 'http://192.168.1.100:3000',
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text('Çevrimdışı / Demo Modu'),
                subtitle: const Text('Sunucu olmadan yerel hazır veriyle çalıştır'),
                value: demoModeVal,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setDialogState(() => demoModeVal = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = urlController.text.trim();
                await StorageService.setServerUrl(newUrl);
                await StorageService.setDemoMode(demoModeVal);
                ApiService.instance.updateSettings(baseUrl: newUrl, demoMode: demoModeVal);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();

    final screens = [
      ReportsView(data: admin.reportData),
      const WorkdayView(),
      const MenuManagementView(),
      const TablesAndLogsView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GUSTO YÖNETİCİ PANELİ',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Yetkili: ${auth.currentUser.name}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Sunucu Ayarları
          IconButton(
            tooltip: 'Sunucu ve Bağlantı Ayarları',
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppColors.textSecondary),
            onPressed: _showServerSettings,
          ),

          // Yenile
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => admin.loadAdminData(),
          ),

          // Garson Ekranına Geri Dön
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: ElevatedButton.icon(
              onPressed: () {
                auth.setWaiterMode();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.black),
              label: Text(
                'Garson Ekranı',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
      body: admin.isLoading && admin.reportData == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
            label: 'Raporlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
            label: 'Vardiya / Z',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primary),
            label: 'Menü',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.table_restaurant_rounded, color: AppColors.primary),
            label: 'Masa & Log',
          ),
        ],
      ),
    );
  }
}
