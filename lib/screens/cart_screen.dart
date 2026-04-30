import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'payment_screen.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VOTRE PANIER'),
            Consumer<CartProvider>(
              builder: (_, cart, __) => Text(
                '${cart.itemCount} ARTICLE${cart.itemCount > 1 ? 'S' : ''}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
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
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                      child: const Text(
                        'VIDER',
                        style: TextStyle(
                          color: AppTheme.error,
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
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppTheme.divider,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Votre panier est vide',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez notre menu et ajoutez vos plats préférés pour commencer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('RETOUR AU MENU'),
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
        color: Colors.white,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      letterSpacing: 1.2,
                    ),
              ),
              Text(
                '${cart.total.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: ElevatedButton(
                onPressed: () => _proceedToPayment(context, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'COMMANDER & PAYER',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
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
          color: AppTheme.error,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.price.toStringAsFixed(2)} € / unité',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
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
                          color: AppTheme.surfaceVariant,
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
                                    ? AppTheme.error
                                    : AppTheme.textPrimary,
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
                              icon: const Icon(Icons.add_rounded,
                                  size: 18, color: AppTheme.primary),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
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
              ? const Color(0xFFFDF6E8)
              : const Color(0xFFF5F0E0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasNote
                ? const Color(0xFFC8901A).withOpacity(0.3)
                : const Color(0xFFEDE8D8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasNote ? Icons.sticky_note_2_rounded : Icons.edit_note_rounded,
              size: 14,
              color: hasNote
                  ? const Color(0xFFC8901A)
                  : AppTheme.textLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasNote
                    ? widget.item.specialInstructions!
                    : 'Ajouter une note…',
                style: TextStyle(
                  fontSize: 11.5,
                  color: hasNote ? AppTheme.textPrimary : AppTheme.textLight,
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
              color: AppTheme.textLight,
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
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ex: sans oignons, bien cuit…',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC8901A), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC8901A), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC8901A), width: 1.5),
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
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8901A),
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
            color: isSecondary ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSecondary ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}