import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service pour persister l'état des commandes et paiements
class OrderPersistenceService {
  static const String _keyPendingOrder = 'pending_order';
  static const String _keyActiveOrder = 'active_order';
  static const String _keyPaymentInProgress = 'payment_in_progress';

  // ── Sauvegarder une commande en attente de paiement ──────────────────────
  static Future<void> savePendingOrder({
    required String restaurantId,
    required String tableNumber,
    required List<Map<String, dynamic>> cartItems,
    required double total,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'restaurantId': restaurantId,
        'tableNumber': tableNumber,
        'cartItems': cartItems,
        'total': total,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_keyPendingOrder, jsonEncode(data));
      if (kDebugMode) {
        print('[OrderPersistence] Pending order saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error saving pending order: $e');
      }
    }
  }

  // ── Récupérer une commande en attente ────────────────────────────────────
  static Future<Map<String, dynamic>?> getPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyPendingOrder);
      if (data == null) return null;

      final order = jsonDecode(data) as Map<String, dynamic>;
      
      // Vérifier que la commande n'est pas trop ancienne (24h max)
      final timestamp = DateTime.parse(order['timestamp'] as String);
      final now = DateTime.now();
      if (now.difference(timestamp).inHours > 24) {
        await clearPendingOrder();
        return null;
      }

      if (kDebugMode) {
        print('[OrderPersistence] Pending order retrieved');
      }
      return order;
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error getting pending order: $e');
      }
      return null;
    }
  }

  // ── Supprimer la commande en attente ─────────────────────────────────────
  static Future<void> clearPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingOrder);
      if (kDebugMode) {
        print('[OrderPersistence] Pending order cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error clearing pending order: $e');
      }
    }
  }

  // ── Sauvegarder une commande active (payée) ──────────────────────────────
  static Future<void> saveActiveOrder({
    required String orderId,
    required String restaurantId,
    required String tableNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'orderId': orderId,
        'restaurantId': restaurantId,
        'tableNumber': tableNumber,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_keyActiveOrder, jsonEncode(data));
      if (kDebugMode) {
        print('[OrderPersistence] Active order saved: $orderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error saving active order: $e');
      }
    }
  }

  // ── Récupérer la commande active ─────────────────────────────────────────
  static Future<Map<String, dynamic>?> getActiveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyActiveOrder);
      if (data == null) return null;

      final order = jsonDecode(data) as Map<String, dynamic>;
      
      // Vérifier que la commande n'est pas trop ancienne (6h max)
      final timestamp = DateTime.parse(order['timestamp'] as String);
      final now = DateTime.now();
      if (now.difference(timestamp).inHours > 6) {
        await clearActiveOrder();
        return null;
      }

      if (kDebugMode) {
        print('[OrderPersistence] Active order retrieved: ${order['orderId']}');
      }
      return order;
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error getting active order: $e');
      }
      return null;
    }
  }

  // ── Supprimer la commande active ─────────────────────────────────────────
  static Future<void> clearActiveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveOrder);
      if (kDebugMode) {
        print('[OrderPersistence] Active order cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error clearing active order: $e');
      }
    }
  }

  // ── Marquer un paiement en cours ─────────────────────────────────────────
  static Future<void> setPaymentInProgress(bool inProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (inProgress) {
        await prefs.setBool(_keyPaymentInProgress, true);
        await prefs.setString('payment_timestamp', DateTime.now().toIso8601String());
      } else {
        await prefs.remove(_keyPaymentInProgress);
        await prefs.remove('payment_timestamp');
      }
      if (kDebugMode) {
        print('[OrderPersistence] Payment in progress: $inProgress');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error setting payment status: $e');
      }
    }
  }

  // ── Vérifier si un paiement est en cours ─────────────────────────────────
  static Future<bool> isPaymentInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inProgress = prefs.getBool(_keyPaymentInProgress) ?? false;
      
      if (inProgress) {
        // Vérifier que le paiement n'est pas trop ancien (30 min max)
        final timestampStr = prefs.getString('payment_timestamp');
        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          final now = DateTime.now();
          if (now.difference(timestamp).inMinutes > 30) {
            await setPaymentInProgress(false);
            return false;
          }
        }
      }
      
      return inProgress;
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error checking payment status: $e');
      }
      return false;
    }
  }

  // ── Nettoyer toutes les données ──────────────────────────────────────────
  static Future<void> clearAll() async {
    try {
      await clearPendingOrder();
      await clearActiveOrder();
      await setPaymentInProgress(false);
      if (kDebugMode) {
        print('[OrderPersistence] All data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrderPersistence] Error clearing all data: $e');
      }
    }
  }
}
