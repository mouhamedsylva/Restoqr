import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';

enum OrderProviderState { idle, loading, success, error }

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;

  OrderProvider(this._orderService);

  // ─── State ────────────────────────────────────────────────────────────────────
  OrderProviderState _state = OrderProviderState.idle;
  Order? _currentOrder;
  String? _errorMessage;
  OrderStatus _currentStatus = OrderStatus.pending;

  // ─── Getters ──────────────────────────────────────────────────────────────────
  OrderProviderState get state => _state;
  Order? get currentOrder => _currentOrder;
  String? get errorMessage => _errorMessage;
  OrderStatus get currentStatus => _currentStatus;
  bool get isLoading => _state == OrderProviderState.loading;

  // ─── Actions ──────────────────────────────────────────────────────────────────

  /// Soumet la commande au restaurant
  Future<Order?> submitOrder({
    required String restaurantId,
    required String tableNumber,
    required List<CartItem> cartItems,
  }) async {
    _setState(OrderProviderState.loading);

    try {
      final order = await _orderService.createOrder(
        restaurantId: restaurantId,
        tableNumber: tableNumber,
        cartItems: cartItems,
      );
      _currentOrder = order;
      _currentStatus = OrderStatus.pending;
      _setState(OrderProviderState.success);
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(OrderProviderState.error);
      return null;
    }
  }

  /// Écoute les changements de statut en temps réel
  Stream<OrderStatus> watchStatus(String orderId) {
    return _orderService.watchOrderStatus(orderId).map((status) {
      _currentStatus = status;
      notifyListeners();
      return status;
    });
  }

  /// Réinitialise le provider pour une nouvelle commande
  void reset() {
    _state = OrderProviderState.idle;
    _currentOrder = null;
    _errorMessage = null;
    _currentStatus = OrderStatus.pending;
    notifyListeners();
  }

  void _setState(OrderProviderState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _orderService.dispose();
    super.dispose();
  }
}