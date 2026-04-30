enum OrderStatus {
  pending('En attente', 0),
  preparing('En préparation', 1),
  ready('Prêt !', 2),
  completed('Terminée', 3),
  cancelled('Annulée', -1);

  final String label;
  final int step;
  const OrderStatus(this.label, this.step);

  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'menuItemId': productId,  // Note: Backend requires menuItemId, not productId
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['menuItem'] != null ? json['menuItem']['id'] : json['menuItemId'] ?? '',
      productName: json['menuItem'] != null ? json['menuItem']['name'] : json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unitPrice'] != null ? double.tryParse(json['unitPrice'].toString()) ?? 0.0 : 0.0,
    );
  }
}

class Order {
  final String id;
  final String restaurantId;
  final String? tableNumber;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;
  final double total;
  final String? type;
  final String? customerName;
  final String? note;
  final double taxRate;
  final bool isTaxIncluded;

  Order({
    required this.id,
    required this.restaurantId,
    this.tableNumber,
    required this.items,
    this.status = OrderStatus.pending,
    required this.createdAt,
    required this.total,
    this.type,
    this.customerName,
    this.note,
    this.taxRate = 0.10,
    this.isTaxIncluded = false,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => isTaxIncluded ? 0.0 : subtotal * taxRate;

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      restaurantId: restaurantId,
      tableNumber: tableNumber,
      items: items,
      status: status ?? this.status,
      createdAt: createdAt,
      total: total,
      type: type,
      customerName: customerName,
      note: note,
      taxRate: taxRate,
      isTaxIncluded: isTaxIncluded,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList();
    }
    
    return Order(
      id: json['id'] ?? '',
      restaurantId: json['restaurantId'] ?? json['restaurant']?['id'] ?? '',
      tableNumber: json['tableNumber'] ?? json['table']?['number']?.toString(),
      items: parsedItems,
      status: OrderStatus.fromString(json['status'] ?? 'PENDING'),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      total: json['totalPrice'] != null ? double.tryParse(json['totalPrice'].toString()) ?? 0.0 : 0.0,
      type: json['type'],
      customerName: json['customerName'],
      note: json['note'],
      taxRate: json['taxRate'] != null ? double.tryParse(json['taxRate'].toString()) ?? 0.10 : 0.10,
      isTaxIncluded: json['isTaxIncluded'] ?? false,
    );
  }
}