import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  final Map<String, StreamController<OrderStatus>> _statusControllers = {};
  IO.Socket? _socket;

  /// Crée une nouvelle commande sur le backend
  Future<Order> createOrder({
    required String restaurantId,
    required String tableNumber,
    required List<CartItem> cartItems,
    String type = 'DINE_IN',
    String? customerName,
    String? note,
  }) async {
    print('🔵 Creating order...');
    print('   Restaurant ID: $restaurantId');
    print('   Table ID: $tableNumber');
    print('   Items count: ${cartItems.length}');
    
    final requestBody = {
      'restaurantId': restaurantId,
      'tableId': tableNumber,
      'type': type,
      'items': cartItems.map((item) => {
        'menuItemId': item.product.id,
        'quantity': item.quantity,
        if (item.hasNote && item.specialInstructions != null && item.specialInstructions!.isNotEmpty) 
          'notes': item.specialInstructions,
      }).toList()
    };
    
    // Add optional fields
    if (customerName != null && customerName.isNotEmpty) {
      requestBody['customerName'] = customerName;
    }
    if (note != null && note.isNotEmpty) {
      requestBody['note'] = note;
    }
    
    print('📤 Request body: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('✅ Order created successfully');
      return Order.fromJson(json);
    } else {
      print('❌ Error creating order: ${response.body}');
      throw Exception('Erreur lors de la création de commande: ${response.body}');
    }
  }

  /// Stream de statut en temps réel via Socket.IO
  Stream<OrderStatus> watchOrderStatus(String orderId) {
    if (_statusControllers.containsKey(orderId)) {
      return _statusControllers[orderId]!.stream;
    }

    final controller = StreamController<OrderStatus>.broadcast(
      onListen: () => _initSocket(orderId),
      onCancel: () {
        _socket?.disconnect();
        _statusControllers.remove(orderId);
      },
    );
    
    _statusControllers[orderId] = controller;

    // Fetch initial state
    getOrder(orderId).then((order) {
      if (order != null && !controller.isClosed) {
        controller.add(order.status);
      }
    });

    return controller.stream;
  }

  void _initSocket(String orderId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {
      print('Connected to Socket.io for order: $orderId');
    });

    _socket?.on('orderStatusUpdated', (data) {
      if (data != null && data['orderId'] == orderId) {
        final newStatusStr = data['status'] as String;
        final newStatus = OrderStatus.fromString(newStatusStr);
        if (_statusControllers.containsKey(orderId)) {
          _statusControllers[orderId]!.add(newStatus);
        }
      }
    });
  }

  /// Récupère une commande par ID
  Future<Order?> getOrder(String orderId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'));
    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Annule une commande (uniquement expérimental ou via API si permis)
  Future<bool> cancelOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'CANCELLED'}),
    );
    return response.statusCode == 200;
  }

  /// Met à jour les informations du client (nom et email)
  Future<bool> updateCustomerInfo(
    String orderId, {
    String? customerName,
    String? customerEmail,
  }) async {
    final body = <String, dynamic>{};
    if (customerName != null) body['customerName'] = customerName;
    if (customerEmail != null) body['customerEmail'] = customerEmail;

    if (body.isEmpty) return false;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/customer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return response.statusCode == 200;
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    for (final ctrl in _statusControllers.values) {
      ctrl.close();
    }
    _statusControllers.clear();
  }
}