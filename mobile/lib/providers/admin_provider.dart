import 'package:flutter/material.dart';
import '../models/report.dart';
import '../models/product.dart';
import '../models/table.dart';
import '../core/services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminReportData? _reportData;
  List<AuditLogItem> _auditLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Vardiya / Gün İşlemleri Durumu
  bool _isWorkDayOpen = true;
  DateTime _workDayStartTime = DateTime.now().subtract(const Duration(hours: 6));

  AdminReportData? get reportData => _reportData;
  List<AuditLogItem> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isWorkDayOpen => _isWorkDayOpen;
  DateTime get workDayStartTime => _workDayStartTime;

  Future<void> loadAdminData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rep = await ApiService.instance.getAdminReports();
      final logs = await ApiService.instance.getAuditLogs();
      _reportData = rep;
      _auditLogs = logs;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vardiya Başlat (Gün Başı)
  void startWorkDay() {
    _isWorkDayOpen = true;
    _workDayStartTime = DateTime.now();
    notifyListeners();
  }

  // Vardiya Kapat (Gün Sonu / Z Raporu)
  void endWorkDay() {
    _isWorkDayOpen = false;
    notifyListeners();
  }

  // Ürün Ekle / Güncelle
  Future<bool> saveProduct(Product product) async {
    final success = await ApiService.instance.saveProduct(product);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  // Kategori Ekle
  Future<bool> saveCategory(Category category) async {
    final success = await ApiService.instance.saveCategory(category);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  // Masa Ekle
  Future<bool> saveTable(PosTable table) async {
    final success = await ApiService.instance.saveTable(table);
    if (success) {
      notifyListeners();
    }
    return success;
  }
}
