import 'package:flutter/material.dart';
import '../models/table.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../core/services/api_service.dart';

class PosProvider extends ChangeNotifier {
  List<PosTable> _tables = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  PosTable? _selectedTable;
  PosOrder? _activeOrder;

  String _selectedArea = 'Tümü';
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;

  // Yeni sipariş sepeti (masaya henüz gönderilmemiş kalemler)
  final List<OrderItem> _cartItems = [];

  List<PosTable> get tables => _tables;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  PosTable? get selectedTable => _selectedTable;
  PosOrder? get activeOrder => _activeOrder;
  List<OrderItem> get cartItems => _cartItems;
  String get selectedArea => _selectedArea;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Kat planı filtreleme
  List<PosTable> get filteredTables {
    if (_selectedArea == 'Tümü') return _tables;
    return _tables.where((t) => t.area.toLowerCase() == _selectedArea.toLowerCase()).toList();
  }

  // Alanlar listesi (Tabs)
  List<String> get availableAreas {
    final areas = <String>{'Tümü'};
    for (var t in _tables) {
      if (t.area.isNotEmpty) areas.add(t.area);
    }
    return areas.toList();
  }

  // Menü filtreleme
  List<Product> get filteredProducts {
    if (_selectedCategoryId == null || _selectedCategoryId == 'ALL') {
      return _products;
    }
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  // İstatistikler
  int get emptyTablesCount => _tables.where((t) => t.isEmpty).length;
  int get occupiedTablesCount => _tables.where((t) => t.isOccupied).length;
  int get billRequestedCount => _tables.where((t) => t.isBillRequested).length;
  double get totalOpenRevenue => _tables.fold(0.0, (acc, t) => acc + t.remainingAmount);

  // Sepet tutarı
  double get cartTotal => _cartItems.fold(0.0, (acc, item) => acc + item.totalPrice);

  // Masa genel toplamı (Mevcut + Yeni sepettekiler)
  double get tableProjectedTotal {
    double current = _activeOrder?.remainingAmount ?? (_selectedTable?.remainingAmount ?? 0.0);
    return current + cartTotal;
  }

  // Verileri Yükle
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final t = await ApiService.instance.getTables();
      final c = await ApiService.instance.getCategories();
      final p = await ApiService.instance.getProducts();

      _tables = t;
      _categories = c;
      _products = p;

      if (_categories.isNotEmpty && _selectedCategoryId == null) {
        _selectedCategoryId = _categories.first.id;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setArea(String area) {
    _selectedArea = area;
    notifyListeners();
  }

  void setCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Masa Seç
  Future<void> selectTable(PosTable table) async {
    _selectedTable = table;
    _cartItems.clear();
    _activeOrder = null;
    notifyListeners();

    try {
      final order = await ApiService.instance.getTableOrder(table.id);
      _activeOrder = order;
      notifyListeners();
    } catch (_) {}
  }

  // Sepete Ekle
  void addToCart(Product product, {List<Modifier> modifiers = const [], String? note}) {
    // Aynı ürün ve aynı modifier kombinasyonu var mı kontrol et
    final modJson = modifiers.map((m) => {'name': m.name, 'price': m.price}).toList();

    int existingIndex = -1;
    for (int i = 0; i < _cartItems.length; i++) {
      if (_cartItems[i].productId == product.id && _cartItems[i].note == note) {
        // Modifier kontrolü
        bool modsMatch = _cartItems[i].selectedModifiers.length == modJson.length;
        if (modsMatch) {
          for (int j = 0; j < modJson.length; j++) {
            if (_cartItems[i].selectedModifiers[j]['name'] != modJson[j]['name']) {
              modsMatch = false;
              break;
            }
          }
        }
        if (modsMatch) {
          existingIndex = i;
          break;
        }
      }
    }

    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += 1.0;
    } else {
      _cartItems.add(OrderItem(
        id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: 1.0,
        note: note,
        selectedModifiers: modJson,
      ));
    }
    notifyListeners();
  }

  // Sepetten Çıkar / Adet Güncelle
  void updateCartQuantity(int index, double delta) {
    if (index >= 0 && index < _cartItems.length) {
      final item = _cartItems[index];
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        item.quantity = newQty;
      }
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Siparişi Masaya Gönder (Mutfak Yazdırma / Onay)
  Future<bool> submitOrder(String waiterUserId, {String? note}) async {
    if (_selectedTable == null || _cartItems.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final order = await ApiService.instance.sendOrder(
        _selectedTable!.id,
        List.from(_cartItems),
        waiterUserId,
        note: note,
      );

      _activeOrder = order;
      _cartItems.clear();

      // Masaları güncelle
      _tables = await ApiService.instance.getTables();
      final updated = _tables.firstWhere((t) => t.id == _selectedTable!.id, orElse: () => _selectedTable!);
      _selectedTable = updated;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Ödeme Al (Nakit, Kredi Kartı, vb. - Parçalı destekli)
  Future<bool> processPayment({
    required double amount,
    required String paymentMethod,
    String? customerId,
  }) async {
    if (_selectedTable == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await ApiService.instance.processPayment(
        tableId: _selectedTable!.id,
        amount: amount,
        paymentMethod: paymentMethod,
        customerId: customerId,
      );

      if (success) {
        _tables = await ApiService.instance.getTables();
        final updated = _tables.firstWhere(
          (t) => t.id == _selectedTable!.id,
          orElse: () => _selectedTable!,
        );
        _selectedTable = updated;
        _activeOrder = await ApiService.instance.getTableOrder(_selectedTable!.id);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hesap İstendi İşareti Koy
  Future<void> requestBill(String tableId) async {
    await ApiService.instance.requestBill(tableId);
    _tables = await ApiService.instance.getTables();
    notifyListeners();
  }

  // Masa Taşıma / Birleştirme
  Future<bool> transferTable(String sourceTableId, String targetTableId) async {
    final success = await ApiService.instance.transferTable(sourceTableId, targetTableId);
    if (success) {
      _tables = await ApiService.instance.getTables();
      if (_selectedTable != null) {
        _selectedTable = _tables.firstWhere(
          (t) => t.id == targetTableId,
          orElse: () => _selectedTable!,
        );
      }
      notifyListeners();
    }
    return success;
  }
}
