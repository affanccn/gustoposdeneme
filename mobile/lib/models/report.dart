class AdminReportData {
  final double closedRevenue;
  final double openTablesRevenue;
  final double totalDiscount;
  final double totalCancelled;
  final int totalOrdersCount;
  final Map<String, double> paymentMethods;
  final List<TopProductItem> topProducts;
  final List<HourlyRevenueItem> hourlyRevenue;

  AdminReportData({
    required this.closedRevenue,
    required this.openTablesRevenue,
    required this.totalDiscount,
    required this.totalCancelled,
    required this.totalOrdersCount,
    required this.paymentMethods,
    required this.topProducts,
    required this.hourlyRevenue,
  });

  double get totalPotentialRevenue => closedRevenue + openTablesRevenue;

  factory AdminReportData.fromJson(Map<String, dynamic> json) {
    Map<String, double> pm = {};
    if (json['paymentMethods'] != null && json['paymentMethods'] is Map) {
      json['paymentMethods'].forEach((k, v) {
        pm[k.toString()] = (v as num).toDouble();
      });
    }

    List<TopProductItem> tops = [];
    if (json['topProducts'] != null && json['topProducts'] is List) {
      tops = (json['topProducts'] as List)
          .map((t) => TopProductItem.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    List<HourlyRevenueItem> hours = [];
    if (json['hourlyRevenue'] != null && json['hourlyRevenue'] is List) {
      hours = (json['hourlyRevenue'] as List)
          .map((h) => HourlyRevenueItem.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    return AdminReportData(
      closedRevenue: (json['closedRevenue'] as num?)?.toDouble() ?? 0.0,
      openTablesRevenue: (json['openTablesRevenue'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0.0,
      totalCancelled: (json['totalCancelled'] as num?)?.toDouble() ?? 0.0,
      totalOrdersCount: (json['totalOrdersCount'] as num?)?.toInt() ?? 0,
      paymentMethods: pm,
      topProducts: tops,
      hourlyRevenue: hours,
    );
  }
}

class TopProductItem {
  final String productName;
  final int quantity;
  final double totalAmount;

  TopProductItem({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HourlyRevenueItem {
  final String hour;
  final double amount;

  HourlyRevenueItem({
    required this.hour,
    required this.amount,
  });

  factory HourlyRevenueItem.fromJson(Map<String, dynamic> json) {
    return HourlyRevenueItem(
      hour: json['hour']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AuditLogItem {
  final String id;
  final String actionType;
  final String description;
  final String actorName;
  final DateTime createdAt;

  AuditLogItem({
    required this.id,
    required this.actionType,
    required this.description,
    required this.actorName,
    required this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id']?.toString() ?? '',
      actionType: json['actionType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actorName: json['actorUser']?['name']?.toString() ?? json['actorName']?.toString() ?? 'Sistem',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
