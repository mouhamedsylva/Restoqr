import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  final Map<String, StreamController<OrderStatus>> _statusControllers = {};
  final Map<String, IO.Socket> _sockets = {};
  final Map<String, Timer> _reconnectTimers = {};

  /// Crée une nouvelle commande sur le backend
  Future<Order> createOrder({
    required String restaurantId,
    required String tableNumber,
    required List<CartItem> cartItems,
    String type = 'DINE_IN',
    String? customerName,
    String? note,
  }) async {
    if (kDebugMode) {
      print('🔵 Creating order...');
      print('   Restaurant ID: $restaurantId');
      print('   Table ID: $tableNumber');
      print('   Items count: ${cartItems.length}');
    }
    
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
    
    if (kDebugMode) {
      print('📤 Request body: ${jsonEncode(requestBody)}');
    }
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (kDebugMode) {
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (kDebugMode) {
        print('✅ Order created successfully');
      }
      return Order.fromJson(json);
    } else {
      if (kDebugMode) {
        print('❌ Error creating order: ${response.body}');
      }
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
      onCancel: () => _cleanupSocket(orderId),
    );
    
    _statusControllers[orderId] = controller;

    // Fetch initial state
    getOrder(orderId).then((order) {
      if (order != null && !controller.isClosed) {
        controller.add(order.status);
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('❌ Error fetching initial order status: $error');
      }
    });

    return controller.stream;
  }

  void _initSocket(String orderId) {
    if (_sockets.containsKey(orderId) && _sockets[orderId]!.connected) {
      if (kDebugMode) {
        print('🔌 Socket already connected for order: $orderId');
      }
      return;
    }

    if (kDebugMode) {
      print('🔌 Initializing socket for order: $orderId');
      print('   Socket URL: ${ApiConfig.socketUrl}');
    }

    final socket = IO.io(ApiConfig.socketUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(10000)
        .build()
    );

    _sockets[orderId] = socket;

    socket.onConnect((_) {
      if (kDebugMode) {
        print('✅ Socket connected for order: $orderId');
      }
      // Rejoindre la room de la commande
      socket.emit('joinOrder', orderId);
      
      // Annuler le timer de reconnexion s'il existe
      _reconnectTimers[orderId]?.cancel();
      _reconnectTimers.remove(orderId);
    });

    socket.onConnectError((error) {
      if (kDebugMode) {
        print('❌ Socket connection error for order $orderId: $error');
      }
    });

    socket.onDisconnect((_) {
      if (kDebugMode) {
        print('⚠️ Socket disconnected for order: $orderId');
      }
      // Tenter une reconnexion après 3 secondes
      _scheduleReconnect(orderId);
    });

    socket.on('orderStatusUpdated', (data) {
      if (kDebugMode) {
        print('📨 Received orderStatusUpdated event: $data');
      }
      
      if (data != null && data['orderId'] == orderId) {
        final newStatusStr = data['status'] as String;
        final newStatus = OrderStatus.fromString(newStatusStr);
        
        if (kDebugMode) {
          print('✅ Order status updated: $orderId -> $newStatusStr');
        }
        
        if (_statusControllers.containsKey(orderId) && !_statusControllers[orderId]!.isClosed) {
          _statusControllers[orderId]!.add(newStatus);
        }
      }
    });

    socket.on('joined', (data) {
      if (kDebugMode) {
        print('✅ Successfully joined room: ${data['room']}');
      }
    });

    socket.connect();
  }

  void _scheduleReconnect(String orderId) {
    // Annuler le timer existant s'il y en a un
    _reconnectTimers[orderId]?.cancel();
    
    // Créer un nouveau timer pour la reconnexion
    _reconnectTimers[orderId] = Timer(const Duration(seconds: 3), () {
      if (_sockets.containsKey(orderId) && !_sockets[orderId]!.connected) {
        if (kDebugMode) {
          print('🔄 Attempting to reconnect socket for order: $orderId');
        }
        _sockets[orderId]!.connect();
      }
    });
  }

  void _cleanupSocket(String orderId) {
    if (kDebugMode) {
      print('🧹 Cleaning up socket for order: $orderId');
    }
    
    // Annuler le timer de reconnexion
    _reconnectTimers[orderId]?.cancel();
    _reconnectTimers.remove(orderId);
    
    // Quitter la room et déconnecter le socket
    if (_sockets.containsKey(orderId)) {
      _sockets[orderId]!.emit('leaveOrder', orderId);
      _sockets[orderId]!.disconnect();
      _sockets[orderId]!.dispose();
      _sockets.remove(orderId);
    }
    
    // Fermer le controller
    if (_statusControllers.containsKey(orderId)) {
      _statusControllers[orderId]!.close();
      _statusControllers.remove(orderId);
    }
  }

  /// Récupère une commande par ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
      );
      
      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      }
      
      if (kDebugMode) {
        print('❌ Error fetching order: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception fetching order: $e');
      }
      return null;
    }
  }

  /// Annule une commande (uniquement expérimental ou via API si permis)
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'CANCELLED'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling order: $e');
      }
      return false;
    }
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

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/customer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating customer info: $e');
      }
      return false;
    }
  }

  void dispose() {
    if (kDebugMode) {
      print('🧹 Disposing OrderService...');
    }
    
    // Nettoyer tous les timers
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }
    _reconnectTimers.clear();
    
    // Nettoyer tous les sockets
    for (final entry in _sockets.entries) {
      entry.value.emit('leaveOrder', entry.key);
      entry.value.disconnect();
      entry.value.dispose();
    }
    _sockets.clear();
    
    // Fermer tous les controllers
    for (final ctrl in _statusControllers.values) {
      ctrl.close();
    }
    _statusControllers.clear();
  }
}