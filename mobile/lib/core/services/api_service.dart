import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../models/table.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../models/report.dart';
import '../../models/customer.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String _baseUrl = 'http://localhost:3000';
  bool _useDemoMode = true;

  Future<void> init() async {
    _baseUrl = await StorageService.getServerUrl();
    _useDemoMode = await StorageService.isDemoMode();
  }

  void updateSettings({String? baseUrl, bool? demoMode}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (demoMode != null) _useDemoMode = demoMode;
  }

  // ===================== MOCK VERİ TABANI (STANDALONE) =====================
  final List<PosTable> _mockTables = [
    PosTable(id: 't-1', name: 'Masa 1', area: 'Salon', status: 'EMPTY', sortOrder: 1),
    PosTable(
      id: 't-2',
      name: 'Masa 2',
      area: 'Salon',
      status: 'OCCUPIED',
      sortOrder: 2,
      activeOrderId: 'ord-2',
      activeOrderTotal: 340.0,
      activeOrderPaid: 0.0,
      activeItemCount: 3,
      activeOrderCreatedAt: DateTime.now().subtract(const Duration(minutes: 38)),
    ),
    PosTable(
      id: 't-3',
      name: 'Masa 3',
      area: 'Salon',
      status: 'BILL_REQUESTED',
      sortOrder: 3,
      activeOrderId: 'ord-3',
      activeOrderTotal: 580.0,
      activeOrderPaid: 200.0,
      activeItemCount: 4,
      activeOrderCreatedAt: DateTime.now().subtract(const Duration(minutes: 52)),
    ),
    PosTable(id: 't-4', name: 'Masa 4', area: 'Salon', status: 'EMPTY', sortOrder: 4),
    PosTable(
      id: 't-5',
      name: 'Teras 1',
      area: 'Teras',
      status: 'OCCUPIED',
      sortOrder: 5,
      activeOrderId: 'ord-5',
      activeOrderTotal: 210.0,
      activeOrderPaid: 0.0,
      activeItemCount: 2,
      activeOrderCreatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    PosTable(id: 't-6', name: 'Teras 2', area: 'Teras', status: 'EMPTY', sortOrder: 6),
    PosTable(id: 't-7', name: 'Teras 3', area: 'Teras', status: 'EMPTY', sortOrder: 7),
    PosTable(
      id: 't-8',
      name: 'Bahçe 1',
      area: 'Bahçe',
      status: 'OCCUPIED',
      sortOrder: 8,
      activeOrderId: 'ord-8',
      activeOrderTotal: 720.0,
      activeOrderPaid: 0.0,
      activeItemCount: 6,
      activeOrderCreatedAt: DateTime.now().subtract(const Duration(minutes: 75)),
    ),
    PosTable(id: 't-9', name: 'Bahçe 2', area: 'Bahçe', status: 'EMPTY', sortOrder: 9),
    PosTable(id: 't-10', name: 'Bar 1', area: 'Bar', status: 'EMPTY', sortOrder: 10),
    PosTable(
      id: 't-11',
      name: 'Bar 2',
      area: 'Bar',
      status: 'BILL_REQUESTED',
      sortOrder: 11,
      activeOrderId: 'ord-11',
      activeOrderTotal: 180.0,
      activeOrderPaid: 0.0,
      activeItemCount: 2,
      activeOrderCreatedAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
  ];

  final List<Customer> _mockCustomers = [
    Customer(id: 'c-1', name: 'Ahmet Çetin (Şirket)', phone: '0532 111 2233', balance: 1450.0),
    Customer(id: 'c-2', name: 'Avukat Mehmet Bey', phone: '0544 555 6677', balance: 820.0),
    Customer(id: 'c-3', name: 'Gusto Personel Hesabı', phone: '0505 999 8877', balance: 0.0),
  ];

  final List<Category> _mockCategories = [
    Category(id: 'cat-1', name: 'Kahveler & Sıcak', sortOrder: 1),
    Category(id: 'cat-2', name: 'Soğuk İçecekler', sortOrder: 2),
    Category(id: 'cat-3', name: 'Burgerler & Izgara', sortOrder: 3),
    Category(id: 'cat-4', name: 'Makarnalar & Salata', sortOrder: 4),
    Category(id: 'cat-5', name: 'Tatlılar & Fırın', sortOrder: 5),
    Category(id: 'cat-6', name: 'Nargile & İkram', sortOrder: 6),
  ];

  final List<Product> _mockProducts = [
    Product(
      id: 'p-1',
      categoryId: 'cat-1',
      name: 'Espresso',
      price: 65.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-1', name: 'Double Shot', price: 25.0),
        Modifier(id: 'm-2', name: 'Sütlü', price: 10.0),
      ],
    ),
    Product(
      id: 'p-2',
      categoryId: 'cat-1',
      name: 'Caffe Latte',
      price: 95.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-3', name: 'Yulaf Sütü', price: 20.0),
        Modifier(id: 'm-4', name: 'Karamel Şurup', price: 15.0),
        Modifier(id: 'm-5', name: 'Vanilya Şurup', price: 15.0),
      ],
    ),
    Product(
      id: 'p-3',
      categoryId: 'cat-1',
      name: 'Türk Kahvesi',
      price: 60.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-6', name: 'Sade', price: 0.0),
        Modifier(id: 'm-7', name: 'Orta', price: 0.0),
        Modifier(id: 'm-8', name: 'Şekerli', price: 0.0),
        Modifier(id: 'm-9', name: 'Damla Sakızlı', price: 15.0),
      ],
    ),
    Product(
      id: 'p-4',
      categoryId: 'cat-2',
      name: 'Iced Americano',
      price: 85.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-10', name: 'Buzsuz', price: 0.0),
        Modifier(id: 'm-11', name: 'Ekstra Shot', price: 25.0),
      ],
    ),
    Product(
      id: 'p-5',
      categoryId: 'cat-2',
      name: 'Limonata (Ev Yapımı)',
      price: 80.0,
      modifiers: [
        Modifier(id: 'm-12', name: 'Naneli', price: 10.0),
        Modifier(id: 'm-13', name: 'Çilekli', price: 15.0),
      ],
    ),
    Product(
      id: 'p-6',
      categoryId: 'cat-3',
      name: 'Gusto Burger',
      price: 260.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-14', name: 'Ekstra Cheddar', price: 30.0),
        Modifier(id: 'm-15', name: 'Çift Köfte', price: 85.0),
        Modifier(id: 'm-16', name: 'Karamelize Soğan', price: 20.0),
        Modifier(id: 'm-17', name: 'Trüflü Mayonez', price: 25.0),
      ],
    ),
    Product(
      id: 'p-7',
      categoryId: 'cat-3',
      name: 'Tavuk Şnitzel',
      price: 220.0,
      modifiers: [
        Modifier(id: 'm-18', name: 'Patates Püresi', price: 0.0),
        Modifier(id: 'm-19', name: 'Parmesanlı Sos', price: 25.0),
      ],
    ),
    Product(
      id: 'p-8',
      categoryId: 'cat-4',
      name: 'Penne Arrabbiata',
      price: 190.0,
      modifiers: [
        Modifier(id: 'm-20', name: 'Az Acılı', price: 0.0),
        Modifier(id: 'm-21', name: 'Ekstra Parmesan', price: 25.0),
      ],
    ),
    Product(
      id: 'p-9',
      categoryId: 'cat-5',
      name: 'San Sebastian Cheesecake',
      price: 140.0,
      isFavorite: true,
      modifiers: [
        Modifier(id: 'm-22', name: 'Belçika Çikolatası', price: 30.0),
        Modifier(id: 'm-23', name: 'Frambuaz Sos', price: 25.0),
      ],
    ),
    Product(
      id: 'p-10',
      categoryId: 'cat-5',
      name: 'Sufle',
      price: 130.0,
      modifiers: [
        Modifier(id: 'm-24', name: 'Vanilyalı Dondurma', price: 25.0),
      ],
    ),
  ];

  final Map<String, PosOrder> _mockOrders = {
    'ord-2': PosOrder(
      id: 'ord-2',
      tableId: 't-2',
      totalAmount: 340.0,
      paidAmount: 0.0,
      status: 'ACTIVE',
      createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
      items: [
        OrderItem(
          id: 'item-201',
          productId: 'p-2',
          productName: 'Caffe Latte',
          unitPrice: 95.0,
          quantity: 2.0,
          note: 'Biri vanilyalı olsun',
          selectedModifiers: [{'name': 'Vanilya Şurup', 'price': 15.0}],
        ),
        OrderItem(
          id: 'item-202',
          productId: 'p-9',
          productName: 'San Sebastian Cheesecake',
          unitPrice: 140.0,
          quantity: 1.0,
          selectedModifiers: [{'name': 'Belçika Çikolatası', 'price': 30.0}],
        ),
      ],
    ),
    'ord-3': PosOrder(
      id: 'ord-3',
      tableId: 't-3',
      totalAmount: 580.0,
      paidAmount: 200.0,
      status: 'ACTIVE',
      createdAt: DateTime.now().subtract(const Duration(minutes: 52)),
      items: [
        OrderItem(
          id: 'item-301',
          productId: 'p-6',
          productName: 'Gusto Burger',
          unitPrice: 260.0,
          quantity: 2.0,
          selectedModifiers: [{'name': 'Ekstra Cheddar', 'price': 30.0}],
        ),
      ],
      payments: [
        Payment(
          id: 'pay-301',
          amount: 200.0,
          paymentMethod: 'CASH',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ],
    ),
  };

  // ===================== API İŞLEMLERİ =====================

  // 1. PIN Girişi
  Future<UserSession> loginWithPin(String pin) async {
    if (_useDemoMode) {
      if (pin == '1234') {
        return UserSession(id: 'usr-admin', name: 'Patron / Yönetici', role: 'ADMIN');
      } else if (pin == '0000') {
        return UserSession(id: 'usr-waiter-1', name: 'Ahmet Yılmaz', role: 'WAITER');
      } else if (pin == '1111') {
        return UserSession(id: 'usr-waiter-2', name: 'Mehmet Demir', role: 'WAITER');
      }
      return UserSession(id: 'usr-$pin', name: 'Personel ($pin)', role: 'WAITER');
    }

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return UserSession.fromJson(jsonDecode(res.body));
      } else {
        throw Exception(jsonDecode(res.body)['error'] ?? 'Giriş başarısız.');
      }
    } catch (_) {
      // Fallback
      if (pin == '1234') {
        return UserSession(id: 'usr-admin', name: 'Yönetici (Çevrimdışı)', role: 'ADMIN');
      }
      return UserSession(id: 'usr-waiter', name: 'Garson ($pin)', role: 'WAITER');
    }
  }

  // 2. Masaları Getir
  Future<List<PosTable>> getTables() async {
    if (_useDemoMode) {
      return List.from(_mockTables);
    }

    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/tables')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => PosTable.fromJson(e)).toList();
      }
    } catch (_) {}

    return List.from(_mockTables);
  }

  // 3. Kategorileri Getir
  Future<List<Category>> getCategories() async {
    if (_useDemoMode) {
      return List.from(_mockCategories);
    }

    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/categories')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Category.fromJson(e)).toList();
      }
    } catch (_) {}

    return List.from(_mockCategories);
  }

  // 4. Ürünleri Getir
  Future<List<Product>> getProducts() async {
    if (_useDemoMode) {
      return List.from(_mockProducts);
    }

    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/admin/products')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Product.fromJson(e)).toList();
      }
    } catch (_) {}

    return List.from(_mockProducts);
  }

  // 5. Masanın Aktif Siparişini Getir
  Future<PosOrder?> getTableOrder(String tableId) async {
    if (_useDemoMode) {
      final table = _mockTables.firstWhere((t) => t.id == tableId, orElse: () => PosTable(id: '', name: '', area: '', status: ''));
      if (table.activeOrderId != null && _mockOrders.containsKey(table.activeOrderId)) {
        return _mockOrders[table.activeOrderId];
      }
      return null;
    }

    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/orders?tableId=$tableId')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null && data['id'] != null) {
          return PosOrder.fromJson(data);
        }
      }
    } catch (_) {}

    final table = _mockTables.firstWhere((t) => t.id == tableId, orElse: () => PosTable(id: '', name: '', area: '', status: ''));
    if (table.activeOrderId != null && _mockOrders.containsKey(table.activeOrderId)) {
      return _mockOrders[table.activeOrderId];
    }
    return null;
  }

  // 6. Masaya Sipariş Gönder (Mutfak / Adisyon)
  Future<PosOrder> sendOrder(String tableId, List<OrderItem> items, String waiterUserId, {String? note}) async {
    if (_useDemoMode) {
      final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
      double total = 0.0;
      for (var item in items) {
        total += item.totalPrice;
      }

      final newOrder = PosOrder(
        id: orderId,
        tableId: tableId,
        totalAmount: total,
        paidAmount: 0.0,
        status: 'ACTIVE',
        note: note,
        items: items,
        createdAt: DateTime.now(),
      );

      _mockOrders[orderId] = newOrder;

      // Masayı güncelle
      final idx = _mockTables.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        final current = _mockTables[idx];
        _mockTables[idx] = current.copyWith(
          status: 'OCCUPIED',
          activeOrderId: orderId,
          activeOrderTotal: (current.activeOrderTotal + total),
          activeItemCount: current.activeItemCount + items.length,
          activeOrderCreatedAt: current.activeOrderCreatedAt ?? DateTime.now(),
        );
      }
      return newOrder;
    }

    try {
      final payload = {
        'tableId': tableId,
        'waiterUserId': waiterUserId,
        'items': items.map((i) => i.toJson()).toList(),
        'note': note,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return PosOrder.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    // Fallback to local
    return sendOrder(tableId, items, waiterUserId, note: note);
  }

  // 7. Ödeme Al (Parçalı veya Tam)
  Future<bool> processPayment({
    required String tableId,
    required double amount,
    required String paymentMethod,
    String? customerId,
  }) async {
    if (_useDemoMode) {
      final idx = _mockTables.indexWhere((t) => t.id == tableId);
      if (idx == -1) return false;
      final table = _mockTables[idx];

      final newPaid = table.activeOrderPaid + amount;
      final isFullyPaid = newPaid >= table.activeOrderTotal - 0.01;

      if (isFullyPaid) {
        _mockTables[idx] = table.copyWith(
          status: 'EMPTY',
          activeOrderId: null,
          activeOrderTotal: 0.0,
          activeOrderPaid: 0.0,
          activeItemCount: 0,
        );
        if (table.activeOrderId != null) {
          _mockOrders.remove(table.activeOrderId);
        }
      } else {
        _mockTables[idx] = table.copyWith(
          activeOrderPaid: newPaid,
        );
        if (table.activeOrderId != null && _mockOrders.containsKey(table.activeOrderId)) {
          final ord = _mockOrders[table.activeOrderId]!;
          final newPayments = List<Payment>.from(ord.payments)..add(
            Payment(
              id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
              amount: amount,
              paymentMethod: paymentMethod,
              createdAt: DateTime.now(),
            ),
          );
          _mockOrders[table.activeOrderId!] = PosOrder(
            id: ord.id,
            tableId: ord.tableId,
            totalAmount: ord.totalAmount,
            discountAmount: ord.discountAmount,
            paidAmount: newPaid,
            status: ord.status,
            note: ord.note,
            items: ord.items,
            payments: newPayments,
            createdAt: ord.createdAt,
          );
        }
      }
      return true;
    }

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/orders/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tableId': tableId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'customerId': customerId,
        }),
      ).timeout(const Duration(seconds: 5));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 8. Hesap İstendi Durumu
  Future<void> requestBill(String tableId) async {
    final idx = _mockTables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      _mockTables[idx] = _mockTables[idx].copyWith(status: 'BILL_REQUESTED');
    }
  }

  // 9. Masa Taşıma / Birleştirme
  Future<bool> transferTable(String sourceTableId, String targetTableId) async {
    final sIdx = _mockTables.indexWhere((t) => t.id == sourceTableId);
    final tIdx = _mockTables.indexWhere((t) => t.id == targetTableId);
    if (sIdx == -1 || tIdx == -1) return false;

    final source = _mockTables[sIdx];
    final target = _mockTables[tIdx];

    // Hedef masaya aktar
    _mockTables[tIdx] = target.copyWith(
      status: 'OCCUPIED',
      activeOrderId: source.activeOrderId,
      activeOrderTotal: target.activeOrderTotal + source.activeOrderTotal,
      activeOrderPaid: target.activeOrderPaid + source.activeOrderPaid,
      activeItemCount: target.activeItemCount + source.activeItemCount,
      activeOrderCreatedAt: target.activeOrderCreatedAt ?? source.activeOrderCreatedAt,
    );

    // Kaynak masayı boşalt
    _mockTables[sIdx] = source.copyWith(
      status: 'EMPTY',
      activeOrderId: null,
      activeOrderTotal: 0.0,
      activeOrderPaid: 0.0,
      activeItemCount: 0,
    );
    return true;
  }

  // 9.1 Kısmi Ürün Aktarma
  Future<bool> partialTransferTable(
    String sourceTableId,
    String targetTableId,
    List<Map<String, dynamic>> itemsToMove,
  ) async {
    final sIdx = _mockTables.indexWhere((t) => t.id == sourceTableId);
    final tIdx = _mockTables.indexWhere((t) => t.id == targetTableId);
    if (sIdx == -1 || tIdx == -1) return false;

    final source = _mockTables[sIdx];
    final target = _mockTables[tIdx];

    if (source.activeOrderId == null || !_mockOrders.containsKey(source.activeOrderId)) {
      return false;
    }

    final sOrder = _mockOrders[source.activeOrderId]!;
    double movedAmount = 0.0;
    List<OrderItem> remainingItems = [];
    List<OrderItem> transferredItems = [];

    for (var item in sOrder.items) {
      final moveMatch = itemsToMove.firstWhere(
        (m) => m['orderItemId'] == item.id,
        orElse: () => {},
      );

      if (moveMatch.isNotEmpty) {
        final double qtyToMove = (moveMatch['quantityToMove'] as num).toDouble();
        if (qtyToMove >= item.quantity) {
          transferredItems.add(item);
          movedAmount += item.totalPrice;
        } else {
          final movedPart = OrderItem(
            id: 'item-${DateTime.now().millisecondsSinceEpoch}',
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: qtyToMove,
            note: item.note,
            selectedModifiers: item.selectedModifiers,
          );
          transferredItems.add(movedPart);
          movedAmount += movedPart.totalPrice;

          item.quantity -= qtyToMove;
          remainingItems.add(item);
        }
      } else {
        remainingItems.add(item);
      }
    }

    // Kaynak masayı güncelle
    if (remainingItems.isEmpty) {
      _mockTables[sIdx] = source.copyWith(
        status: 'EMPTY',
        activeOrderId: null,
        activeOrderTotal: 0.0,
        activeOrderPaid: 0.0,
        activeItemCount: 0,
      );
      _mockOrders.remove(source.activeOrderId);
    } else {
      final newTotal = (source.activeOrderTotal - movedAmount).clamp(0.0, double.infinity);
      _mockTables[sIdx] = source.copyWith(
        activeOrderTotal: newTotal,
        activeItemCount: remainingItems.length,
      );
      _mockOrders[source.activeOrderId!] = PosOrder(
        id: sOrder.id,
        tableId: source.id,
        totalAmount: newTotal,
        discountAmount: sOrder.discountAmount,
        paidAmount: sOrder.paidAmount,
        status: sOrder.status,
        note: sOrder.note,
        items: remainingItems,
        payments: sOrder.payments,
        createdAt: sOrder.createdAt,
      );
    }

    // Hedef masayı güncelle
    final targetOrderId = target.activeOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final existingTargetOrder = target.activeOrderId != null ? _mockOrders[target.activeOrderId] : null;

    final List<OrderItem> newTargetItems = existingTargetOrder != null
        ? [...existingTargetOrder.items, ...transferredItems]
        : transferredItems;

    _mockOrders[targetOrderId] = PosOrder(
      id: targetOrderId,
      tableId: target.id,
      totalAmount: target.activeOrderTotal + movedAmount,
      paidAmount: target.activeOrderPaid,
      status: 'ACTIVE',
      items: newTargetItems,
      createdAt: target.activeOrderCreatedAt ?? DateTime.now(),
    );

    _mockTables[tIdx] = target.copyWith(
      status: 'OCCUPIED',
      activeOrderId: targetOrderId,
      activeOrderTotal: target.activeOrderTotal + movedAmount,
      activeItemCount: newTargetItems.length,
      activeOrderCreatedAt: target.activeOrderCreatedAt ?? DateTime.now(),
    );

    return true;
  }

  // 9.2 İndirim Uygula (% veya Sabit Tutar)
  Future<bool> applyDiscount({
    required String tableId,
    required String discountType, // 'percentage' | 'amount'
    required double value,
  }) async {
    final idx = _mockTables.indexWhere((t) => t.id == tableId);
    if (idx == -1) return false;
    final table = _mockTables[idx];
    if (table.activeOrderId == null || !_mockOrders.containsKey(table.activeOrderId)) {
      return false;
    }

    final order = _mockOrders[table.activeOrderId]!;
    double discountCalc = 0.0;
    if (discountType == 'percentage') {
      discountCalc = (order.totalAmount * (value / 100)).clamp(0.0, order.totalAmount);
    } else {
      discountCalc = value.clamp(0.0, order.totalAmount);
    }

    final newTotal = (order.totalAmount - discountCalc).clamp(0.0, double.infinity);

    _mockOrders[table.activeOrderId!] = PosOrder(
      id: order.id,
      tableId: order.tableId,
      totalAmount: newTotal,
      discountAmount: order.discountAmount + discountCalc,
      paidAmount: order.paidAmount,
      status: order.status,
      note: order.note,
      items: order.items,
      payments: order.payments,
      createdAt: order.createdAt,
    );

    _mockTables[idx] = table.copyWith(activeOrderTotal: newTotal);
    return true;
  }

  // 9.3 Ürün Kalem İşlemi (İkram veya İptal)
  Future<bool> applyItemAction({
    required String tableId,
    required String orderItemId,
    required String action, // 'complimentary' | 'cancel'
    String? cancelReason,
  }) async {
    final idx = _mockTables.indexWhere((t) => t.id == tableId);
    if (idx == -1) return false;
    final table = _mockTables[idx];
    if (table.activeOrderId == null || !_mockOrders.containsKey(table.activeOrderId)) {
      return false;
    }

    final order = _mockOrders[table.activeOrderId]!;
    final itemIdx = order.items.indexWhere((i) => i.id == orderItemId);
    if (itemIdx == -1) return false;

    final item = order.items[itemIdx];

    if (action == 'complimentary') {
      item.status = 'COMPLIMENTARY';
    } else if (action == 'cancel') {
      item.status = 'CANCELLED';
      item.cancelReason = cancelReason ?? 'Müşteri vazgeçti';
    }

    // Toplamı yeniden hesapla
    double newTotal = 0.0;
    for (var it in order.items) {
      if (it.isActive) {
        newTotal += it.totalPrice;
      }
    }

    _mockOrders[table.activeOrderId!] = PosOrder(
      id: order.id,
      tableId: order.tableId,
      totalAmount: newTotal,
      discountAmount: order.discountAmount,
      paidAmount: order.paidAmount,
      status: order.status,
      note: order.note,
      items: order.items,
      payments: order.payments,
      createdAt: order.createdAt,
    );

    _mockTables[idx] = table.copyWith(activeOrderTotal: newTotal);
    return true;
  }

  // 9.4 Cari Müşterileri Getir
  Future<List<Customer>> getCustomers() async {
    if (_useDemoMode) {
      return List.from(_mockCustomers);
    }
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/admin/customers')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Customer.fromJson(e)).toList();
      }
    } catch (_) {}
    return List.from(_mockCustomers);
  }

  // 10. Yönetici Analiz Raporları
  Future<AdminReportData> getAdminReports() async {
    if (_useDemoMode) {
      double openRev = 0.0;
      for (var t in _mockTables) {
        openRev += t.remainingAmount;
      }

      return AdminReportData(
        closedRevenue: 14850.0,
        openTablesRevenue: openRev,
        totalDiscount: 420.0,
        totalCancelled: 260.0,
        totalOrdersCount: 64,
        paymentMethods: {
          'Nakit': 6200.0,
          'Kredi Kartı': 7150.0,
          'Yemek Kartı': 1100.0,
          'Cari / Veresiye': 400.0,
        },
        topProducts: [
          TopProductItem(productName: 'Gusto Burger', quantity: 28, totalAmount: 7280.0),
          TopProductItem(productName: 'Caffe Latte', quantity: 42, totalAmount: 3990.0),
          TopProductItem(productName: 'San Sebastian', quantity: 19, totalAmount: 2660.0),
          TopProductItem(productName: 'Iced Americano', quantity: 24, totalAmount: 2040.0),
          TopProductItem(productName: 'Türk Kahvesi', quantity: 30, totalAmount: 1800.0),
        ],
        hourlyRevenue: [
          HourlyRevenueItem(hour: '11:00', amount: 850.0),
          HourlyRevenueItem(hour: '12:00', amount: 2100.0),
          HourlyRevenueItem(hour: '13:00', amount: 3400.0),
          HourlyRevenueItem(hour: '14:00', amount: 2800.0),
          HourlyRevenueItem(hour: '15:00', amount: 1600.0),
          HourlyRevenueItem(hour: '16:00', amount: 1950.0),
          HourlyRevenueItem(hour: '17:00', amount: 2150.0),
        ],
      );
    }

    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/admin/reports')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return AdminReportData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    return getAdminReports();
  }

  // 11. Denetim Logları
  Future<List<AuditLogItem>> getAuditLogs() async {
    return [
      AuditLogItem(
        id: 'log-1',
        actionType: 'DISCOUNT_APPLIED',
        description: 'Masa 3 için %10 personel indirimi uygulandı.',
        actorName: 'Yönetici (Admin)',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      AuditLogItem(
        id: 'log-2',
        actionType: 'TABLE_TRANSFER',
        description: 'Masa 1 siparişi Teras 2 masasına taşındı.',
        actorName: 'Ahmet Yılmaz',
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      AuditLogItem(
        id: 'log-3',
        actionType: 'ITEM_CANCEL',
        description: 'Penne Arrabbiata (Mutfak hatası sebebiyle iptal edildi).',
        actorName: 'Mehmet Demir',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      ),
      AuditLogItem(
        id: 'log-4',
        actionType: 'COMPLIMENTARY',
        description: 'Türk Kahvesi ikram edildi.',
        actorName: 'Yönetici (Admin)',
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      ),
    ];
  }

  // 12. Ürün Ekle / Güncelle
  Future<bool> saveProduct(Product product) async {
    final idx = _mockProducts.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _mockProducts[idx] = product;
    } else {
      _mockProducts.add(product);
    }
    return true;
  }

  // 13. Kategori Ekle
  Future<bool> saveCategory(Category category) async {
    final idx = _mockCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _mockCategories[idx] = category;
    } else {
      _mockCategories.add(category);
    }
    return true;
  }

  // 14. Masa Ekle
  Future<bool> saveTable(PosTable table) async {
    final idx = _mockTables.indexWhere((t) => t.id == table.id);
    if (idx != -1) {
      _mockTables[idx] = table;
    } else {
      _mockTables.add(table);
    }
    return true;
  }
}
