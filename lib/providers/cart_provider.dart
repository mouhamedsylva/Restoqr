import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/cart_api_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  /// tableId utilisé pour synchroniser avec l'API
  String? _tableId;

  void setTableId(String tableId) {
    _tableId = tableId;
  }

  // ─── Getters ──────────────────────────────────────────────────────────────────

  List<CartItem> get items => List.unmodifiable(_items.values.toList());

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get tax => 0.0; // TVA supprimée

  double get total => subtotal; // Total = Sous-total (sans TVA)

  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  bool contains(String productId) => _items.containsKey(productId);

  // ─── Actions ──────────────────────────────────────────────────────────────────

  /// Ajoute un produit ou incrémente sa quantité
  void addProduct(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  /// Décrémente la quantité ou supprime si elle atteint 0
  void removeProduct(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
    } else {
      _items.remove(productId);
      // Appel API : suppression complète de l'article
      if (_tableId != null) {
        CartApiService.removeItem(tableId: _tableId!, menuItemId: productId);
      }
    }
    notifyListeners();
  }

  /// Supprime complètement un article du panier (swipe ou bouton poubelle)
  void deleteItem(String productId) {
    _items.remove(productId);
    // Appel API
    if (_tableId != null) {
      CartApiService.removeItem(tableId: _tableId!, menuItemId: productId);
    }
    notifyListeners();
  }

  /// Définit directement la quantité d'un produit
  void setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _items.remove(product.id);
      // Appel API : suppression complète
      if (_tableId != null) {
        CartApiService.removeItem(tableId: _tableId!, menuItemId: product.id);
      }
    } else {
      if (_items.containsKey(product.id)) {
        _items[product.id]!.quantity = quantity;
      } else {
        _items[product.id] = CartItem(product: product, quantity: quantity);
      }
    }
    notifyListeners();
  }

  /// Vide entièrement le panier
  void clearCart() {
    _items.clear();
    // Appel API
    if (_tableId != null) {
      CartApiService.clearCart(tableId: _tableId!);
    }
    notifyListeners();
  }

  /// Met à jour la note d'un article
  void updateNote(String productId, String? note) {
    if (!_items.containsKey(productId)) return;
    _items[productId]!.specialInstructions =
        (note != null && note.trim().isEmpty) ? null : note?.trim();
    notifyListeners();
  }

  /// Ajoute un produit avec une note directement
  void addProductWithNote(Product product, {String? note}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
      if (note != null && note.trim().isNotEmpty) {
        _items[product.id]!.specialInstructions = note.trim();
      }
    } else {
      _items[product.id] = CartItem(
        product: product,
        specialInstructions: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      );
    }
    notifyListeners();
  }
}