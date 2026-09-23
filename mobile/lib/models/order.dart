import 'dart:convert';

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  double quantity;
  String? note;
  String status; // "ACTIVE", "COMPLIMENTARY", "CANCELLED", "PAID"
  String? cancelReason;
  List<Map<String, dynamic>> selectedModifiers;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.note,
    this.status = 'ACTIVE',
    this.cancelReason,
    this.selectedModifiers = const [],
  });

  bool get isComplimentary => status == 'COMPLIMENTARY';
  bool get isCancelled => status == 'CANCELLED';
  bool get isPaid => status == 'PAID';
  bool get isActive => status == 'ACTIVE';

  double get modifiersTotal {
    double total = 0.0;
    for (var m in selectedModifiers) {
      total += (m['price'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  double get effectiveUnitPrice => isComplimentary ? 0.0 : (unitPrice + modifiersTotal);
  double get totalPrice => effectiveUnitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> mods = [];
    if (json['selectedModifiers'] != null) {
      if (json['selectedModifiers'] is String) {
        try {
          final decoded = jsonDecode(json['selectedModifiers']);
          if (decoded is List) {
            mods = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        } catch (_) {}
      } else if (json['selectedModifiers'] is List) {
        mods = (json['selectedModifiers'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      note: json['note']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      cancelReason: json['cancelReason']?.toString(),
      selectedModifiers: mods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'note': note,
      'status': status,
      'cancelReason': cancelReason,
      'selectedModifiers': selectedModifiers,
    };
  }
}

class Payment {
  final String id;
  final double amount;
  final String paymentMethod; // "CASH", "CREDIT_CARD", "MEAL_CARD", "CARI"
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.createdAt,
  });

  String get methodTitle {
    switch (paymentMethod) {
      case 'CASH':
        return 'Nakit';
      case 'CREDIT_CARD':
        return 'Kredi Kartı';
      case 'MEAL_CARD':
        return 'Yemek Kartı';
      case 'CARI':
        return 'Cari / Veresiye';
      default:
        return paymentMethod;
    }
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PosOrder {
  final String id;
  final String tableId;
  final double totalAmount;
  final double discountAmount;
  final double paidAmount;
  final String status; // "ACTIVE", "PAID", "CANCELLED"
  final String? note;
  final List<OrderItem> items;
  final List<Payment> payments;
  final DateTime createdAt;

  PosOrder({
    required this.id,
    required this.tableId,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.paidAmount = 0.0,
    required this.status,
    this.note,
    this.items = const [],
    this.payments = const [],
    required this.createdAt,
  });

  double get remainingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    List<Payment> payments = [];
    if (json['payments'] != null && json['payments'] is List) {
      payments = (json['payments'] as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return PosOrder(
      id: json['id']?.toString() ?? '',
      tableId: json['tableId']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      note: json['note']?.toString(),
      items: items,
      payments: payments,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
