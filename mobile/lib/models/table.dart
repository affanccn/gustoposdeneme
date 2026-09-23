class PosTable {
  final String id;
  final String name;
  final String area;
  final String status; // "EMPTY", "OCCUPIED", "BILL_REQUESTED"
  final int sortOrder;
  final String? activeOrderId;
  final double activeOrderTotal;
  final double activeOrderPaid;
  final int activeItemCount;
  final DateTime? activeOrderCreatedAt;

  PosTable({
    required this.id,
    required this.name,
    required this.area,
    required this.status,
    this.sortOrder = 0,
    this.activeOrderId,
    this.activeOrderTotal = 0.0,
    this.activeOrderPaid = 0.0,
    this.activeItemCount = 0,
    this.activeOrderCreatedAt,
  });

  bool get isEmpty => status == 'EMPTY' || activeOrderId == null;
  bool get isOccupied => status == 'OCCUPIED';
  bool get isBillRequested => status == 'BILL_REQUESTED';

  double get remainingAmount => (activeOrderTotal - activeOrderPaid).clamp(0.0, double.infinity);

  String get durationString {
    if (activeOrderCreatedAt == null) return '';
    final diff = DateTime.now().difference(activeOrderCreatedAt!);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk';
    }
    return '${diff.inHours} sa ${diff.inMinutes % 60} dk';
  }

  factory PosTable.fromJson(Map<String, dynamic> json) {
    double total = 0.0;
    double paid = 0.0;
    int itemCount = 0;
    DateTime? createdAt;

    if (json['activeOrder'] != null && json['activeOrder'] is Map) {
      final ord = json['activeOrder'] as Map<String, dynamic>;
      total = (ord['totalAmount'] as num?)?.toDouble() ?? 0.0;
      paid = (ord['paidAmount'] as num?)?.toDouble() ?? 0.0;
      if (ord['items'] is List) {
        itemCount = (ord['items'] as List).length;
      }
      if (ord['createdAt'] != null) {
        createdAt = DateTime.tryParse(ord['createdAt'].toString());
      }
    } else {
      total = (json['activeOrderTotal'] as num?)?.toDouble() ?? 0.0;
      paid = (json['activeOrderPaid'] as num?)?.toDouble() ?? 0.0;
      itemCount = (json['activeItemCount'] as num?)?.toInt() ?? 0;
      if (json['activeOrderCreatedAt'] != null) {
        createdAt = DateTime.tryParse(json['activeOrderCreatedAt'].toString());
      }
    }

    return PosTable(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      area: json['area']?.toString() ?? 'Genel',
      status: json['status']?.toString() ?? 'EMPTY',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      activeOrderId: json['activeOrderId']?.toString(),
      activeOrderTotal: total,
      activeOrderPaid: paid,
      activeItemCount: itemCount,
      activeOrderCreatedAt: createdAt,
    );
  }

  PosTable copyWith({
    String? id,
    String? name,
    String? area,
    String? status,
    int? sortOrder,
    String? activeOrderId,
    double? activeOrderTotal,
    double? activeOrderPaid,
    int? activeItemCount,
    DateTime? activeOrderCreatedAt,
  }) {
    return PosTable(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      activeOrderTotal: activeOrderTotal ?? this.activeOrderTotal,
      activeOrderPaid: activeOrderPaid ?? this.activeOrderPaid,
      activeItemCount: activeItemCount ?? this.activeItemCount,
      activeOrderCreatedAt: activeOrderCreatedAt ?? this.activeOrderCreatedAt,
    );
  }
}
