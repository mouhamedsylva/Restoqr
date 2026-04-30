import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service pour synchroniser les actions du panier avec le backend.
class CartApiService {
  /// Supprime un article du panier côté API.
  /// DELETE /api/v1/cart/:tableId/item/:menuItemId
  static Future<void> removeItem({
    required String tableId,
    required String menuItemId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/cart/$tableId/item/$menuItemId',
      );
      final response = await http.delete(uri);
      if (response.statusCode != 200) {
        // On log mais on ne bloque pas l'UI — le panier local reste la source de vérité
        print('[CartApi] removeItem error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[CartApi] removeItem exception: $e');
    }
  }

  /// Vide entièrement le panier côté API.
  /// DELETE /api/v1/cart/:tableId/clear
  static Future<void> clearCart({required String tableId}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/cart/$tableId/clear',
      );
      final response = await http.delete(uri);
      if (response.statusCode != 200) {
        print('[CartApi] clearCart error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[CartApi] clearCart exception: $e');
    }
  }
}
