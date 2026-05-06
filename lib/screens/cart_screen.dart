import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'payment_screen.dart';

// Palette de couleurs moderne
const _primaryOrange = Color(0xFFD2691E);
const _lightOrange = Color(0xFFFFF5EE);
const _darkText = Color(0xFF2C2C2C);
const _lightText = Color(0xFF8E8E8E);
const _background = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _surfaceVariant = Color(0xFFF5F5F5);
const _divider = Color(0xFFE0E0E0);
const _error = Color(0xFFEF4444);

class CartScreen extends StatelessWidget {
  final String restaurantId;
  final String tableNumber;

  const CartScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOTRE PANIER',
              style: TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer<CartProvider>(
              builder: (_, cart, __) => Text(
                '${cart.itemCount} ARTICLE${cart.itemCount > 1 ? 'S' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  color: _lightText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _darkText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => _confirmClear(context, cart),
                      child: Text(
                        'VIDER',
                        style: TextStyle(
                          color: _error,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return _buildEmptyCart(context);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  itemCount: cart.items.length,
                  itemBuilder: (_, index) =>
                      _PremiumCartItemWidget(item: cart.items[index]),
                ),
              ),
              _buildPremiumOrderSummary(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: _divider,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez notre menu et ajoutez vos plats préférés pour commencer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _lightText,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'RETOUR AU MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumOrderSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            label: 'Sous-total',
            value: '${cart.subtotal.toStringAsFixed(2)} €',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: _divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${cart.total.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _proceedToPayment(context, cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                shadowColor: _primaryOrange.withOpacity(0.4),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'COMMANDER & PAYER',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment(BuildContext context, CartProvider cart) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => PaymentScreen(
          restaurantId: restaurantId,
          tableNumber: tableNumber,
          cartItems: cart.items,
          total: cart.total,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: AppTheme.defaultCurve)),
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnim,
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Vider le panier ?',
      message: 'Cette action supprimera tous les articles de votre commande actuelle.',
      confirmLabel: 'Vider',
      cancelLabel: 'Annuler',
      icon: Icons.delete_sweep_rounded,
    );
    if (confirmed && context.mounted) {
      cart.clearCart();
      AppFeedback.showSuccess(context, 'Panier vidé avec succès');
    }
  }
}

class _PremiumCartItemWidget extends StatelessWidget {
  final CartItem item;
  const _PremiumCartItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: _error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await AppFeedback.confirm(
          context,
          title: 'Supprimer cet article ?',
          message: '"${item.product.name}" sera retiré de votre commande.',
          confirmLabel: 'Supprimer',
          cancelLabel: 'Annuler',
          icon: Icons.delete_outline_rounded,
        );
      },
      onDismissed: (_) {
        cart.deleteItem(item.product.id);
        AppFeedback.showSuccess(
          context,
          '${item.product.name} retiré du panier',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40), // Cercle parfait
              child: SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: item.product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.price.toStringAsFixed(2)} € / unité',
                    style: TextStyle(
                      fontSize: 12,
                      color: _lightText,
                    ),
                  ),
                  // ── Note de l'article ──────────────────────────────────
                  _NoteWidget(item: item),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _surfaceVariant,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                item.quantity == 1
                                    ? Icons.delete_outline_rounded
                                    : Icons.remove_rounded,
                                size: 18,
                                color: item.quantity == 1
                                    ? _error
                                    : _darkText,
                              ),
                              onPressed: () async {
                                if (item.quantity == 1) {
                                  final confirmed = await AppFeedback.confirm(
                                    context,
                                    title: 'Supprimer cet article ?',
                                    message: '"${item.product.name}" sera retiré de votre commande.',
                                    confirmLabel: 'Supprimer',
                                    cancelLabel: 'Annuler',
                                    icon: Icons.delete_outline_rounded,
                                  );
                                  if (confirmed && context.mounted) {
                                    cart.removeProduct(item.product.id);
                                    AppFeedback.showSuccess(
                                      context,
                                      '${item.product.name} retiré du panier',
                                    );
                                  }
                                } else {
                                  cart.removeProduct(item.product.id);
                                }
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_rounded,
                                  size: 18, color: _primaryOrange),
                              onPressed: () =>
                                  cart.addProduct(item.product),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget note par article ───────────────────────────────────────────────────

class _NoteWidget extends StatefulWidget {
  final CartItem item;
  const _NoteWidget({required this.item});

  @override
  State<_NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<_NoteWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.item.specialInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<CartProvider>().updateNote(
          widget.item.product.id,
          _ctrl.text,
        );
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.item.hasNote;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: _editing ? _buildEditor() : _buildDisplay(hasNote),
      ),
    );
  }

  Widget _buildDisplay(bool hasNote) {
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: hasNote
              ? _lightOrange
              : _surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasNote
                ? _primaryOrange.withOpacity(0.3)
                : _divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasNote ? Icons.sticky_note_2_rounded : Icons.edit_note_rounded,
              size: 14,
              color: hasNote
                  ? _primaryOrange
                  : _lightText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasNote
                    ? widget.item.specialInstructions!
                    : 'Ajouter une note…',
                style: TextStyle(
                  fontSize: 11.5,
                  color: hasNote ? _darkText : _lightText,
                  fontStyle:
                      hasNote ? FontStyle.normal : FontStyle.italic,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.edit_rounded,
              size: 12,
              color: _lightText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          maxLines: 2,
          maxLength: 150,
          style: TextStyle(fontSize: 13, color: _darkText),
          decoration: InputDecoration(
            hintText: 'Ex: sans oignons, bien cuit…',
            hintStyle: TextStyle(
              fontSize: 12,
              color: _lightText,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: _white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _primaryOrange, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _primaryOrange, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _primaryOrange, width: 1.5),
            ),
            counterStyle: const TextStyle(fontSize: 10),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                _ctrl.text = widget.item.specialInstructions ?? '';
                setState(() => _editing = false);
                FocusScope.of(context).unfocus();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 12,
                  color: _lightText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w500,
            color: isSecondary ? _lightText : _darkText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSecondary ? _lightText : _darkText,
          ),
        ),
      ],
    );
  }
}