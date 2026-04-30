import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? specialInstructions; // note / instructions spéciales (mutable)

  CartItem({
    required this.product,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => product.price * quantity;

  bool get hasNote =>
      specialInstructions != null && specialInstructions!.trim().isNotEmpty;

  CartItem copyWith({int? quantity, String? specialInstructions}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}