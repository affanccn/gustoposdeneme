import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/waiter/floor_plan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Durum çubuğu ve sistem gezinme çubuğunu koyu temaya uyarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF09090B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await ApiService.instance.init();

  runApp(const GustoPosApp());
}

class GustoPosApp extends StatelessWidget {
  const GustoPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Gusto POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Garson için Kat Planı ve Hızlı Sipariş EKRANI ilk sayfa olarak açılır!
        home: const FloorPlanScreen(),
      ),
    );
  }
}
