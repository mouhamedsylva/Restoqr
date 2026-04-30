import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'order_status_screen.dart';

// Import conditionnel pour le widget web
import '../widgets/stripe_payment_web.dart' if (dart.library.io) '../widgets/stripe_payment_web_stub.dart';

// ── Palette locale ────────────────────────────────────────────────────────────
const _amber       = Color(0xFFC8901A);
const _amberLight  = Color(0xFFE8A83A);
const _bg          = Color(0xFFFFFDF7);
const _surfaceVar  = Color(0xFFFDF6E8);
const _textPrimary = Color(0xFF1A1714);
const _textSecond  = Color(0xFF6B6350);
const _textLight   = Color(0xFFA89F85);
const _divider     = Color(0xFFEDE8D8);

class PaymentScreen extends StatefulWidget {
  final String restaurantId;
  final String tableNumber;
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
    required this.cartItems,
    required this.total,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  // ── Animations succès ────────────────────────────────────────────────────────
  late AnimationController _successCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _fadeAnim;

  bool _isProcessing = false;
  bool _showSuccess  = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.1, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
    ]).animate(_successCtrl);
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _successCtrl,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _successCtrl,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Flux de paiement ─────────────────────────────────────────────────────────
  Future<void> _processPayment() async {
    if (_isProcessing) return;
    
    setState(() { _isProcessing = true; _errorMsg = null; });
    HapticFeedback.mediumImpact();

    try {
      // 1. Créer la commande
      final orderProvider = context.read<OrderProvider>();
      final order = await orderProvider.submitOrder(
        restaurantId: widget.restaurantId,
        tableNumber: widget.tableNumber,
        cartItems: widget.cartItems,
      );
      if (order == null || !mounted) {
        setState(() => _isProcessing = false);
        AppFeedback.showError(context, 'Impossible de créer la commande. Réessayez.');
        return;
      }

      // 2. Créer le PaymentIntent côté backend
      final stripeService = context.read<StripeService>();
      final clientSecret = await stripeService.createPaymentIntent(
        amount: widget.total,
        currency: 'eur',
        restaurantId: widget.restaurantId,
        orderId: order.id,
      );

      // 3. Présenter le paiement (mobile ou web)
      final result = await stripeService.presentPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: 'QR Order',
      );

      if (!mounted) return;

      // 4. Sur web, afficher le formulaire de paiement
      if (kIsWeb && result.status == 'requires_web_payment') {
        _showWebPaymentDialog(clientSecret, order.id);
        setState(() => _isProcessing = false);
        return;
      }

      // 5. Traiter le résultat (mobile)
      if (result.success) {
        HapticFeedback.heavyImpact();
        context.read<CartProvider>().clearCart();
        setState(() { _isProcessing = false; _showSuccess = true; });
        await _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        _navigateToStatus(order.id);
      } else if (result.status == 'canceled') {
        setState(() => _isProcessing = false);
        AppFeedback.showInfo(context, 'Paiement annulé.');
      } else {
        final msg = result.errorMessage ?? 'Le paiement a échoué';
        setState(() { _isProcessing = false; _errorMsg = msg; });
        AppFeedback.showError(context, msg);
      }
    } catch (e) {
      if (!mounted) return;
      const msg = 'Une erreur est survenue. Réessayez.';
      setState(() { _isProcessing = false; _errorMsg = msg; });
      AppFeedback.showError(context, msg);
    }
  }

  void _showWebPaymentDialog(String clientSecret, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: StripePaymentWeb(
            clientSecret: clientSecret,
            amount: widget.total,
            onSuccess: () {
              Navigator.pop(context); // Fermer le dialog
              HapticFeedback.heavyImpact();
              context.read<CartProvider>().clearCart();
              setState(() { _showSuccess = true; });
              _successCtrl.forward().then((_) {
                Future.delayed(const Duration(milliseconds: 1400), () {
                  if (mounted) _navigateToStatus(orderId);
                });
              });
            },
            onError: (error) {
              Navigator.pop(context); // Fermer le dialog
              AppFeedback.showError(context, error);
            },
            onCancel: () {
              Navigator.pop(context); // Fermer le dialog
              AppFeedback.showInfo(context, 'Paiement annulé.');
            },
          ),
        ),
      ),
    );
  }

  void _navigateToStatus(String orderId) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => OrderStatusScreen(
          orderId: orderId,
          tableNumber: widget.tableNumber,
          restaurantId: widget.restaurantId,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: AppTheme.mediumAnim,
      ),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _showSuccess
          ? null
          : AppBar(
              backgroundColor: _bg,
              elevation: 0,
              title: Text('Paiement',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: _textPrimary),
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
              ),
            ),
      body: _showSuccess ? _buildSuccess() : _buildPaymentView(),
    );
  }

  // ── Vue paiement ──────────────────────────────────────────────────────────────
  Widget _buildPaymentView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummary(),
          _buildStripeInfo(),
          if (_errorMsg != null) _buildError(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _buildPayButton(),
          ),
          _buildSecurityBadge(),
        ],
      ),
    );
  }

  // ── Résumé commande ───────────────────────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded, color: _amber, size: 16),
            const SizedBox(width: 8),
            Text('Résumé de la commande',
                style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textSecond,
                    letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 16),
          ...widget.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${item.quantity}',
                          style: GoogleFonts.lora(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _amber)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.product.name,
                        style: GoogleFonts.lora(
                            fontSize: 13.5, color: _textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${item.totalPrice.toStringAsFixed(2)} €',
                      style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSecond)),
                ]),
              )),
          Divider(color: _divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              Text('${widget.total.toStringAsFixed(2)} €',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _amber)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info Stripe ───────────────────────────────────────────────────────────────
  Widget _buildStripeInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceVar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF635BFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Color(0xFF635BFF), 
              size: 24
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement sécurisé par Stripe',
                  style: GoogleFonts.lora(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)
                ),
                const SizedBox(height: 3),
                Text(
                    kIsWeb
                      ? 'Carte bancaire acceptée.\nVos données sont chiffrées SSL.'
                      : 'Carte, Apple Pay, Google Pay acceptés.\nVos données sont chiffrées SSL.',
                    style: GoogleFonts.lora(
                        fontSize: 11.5,
                        color: _textSecond,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB71C1C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMsg!,
                style: GoogleFonts.lora(
                    fontSize: 13,
                    color: const Color(0xFFB71C1C),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Bouton payer ──────────────────────────────────────────────────────────────
  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _processPayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: _isProcessing
              ? null
              : const LinearGradient(
                  colors: [_amberLight, _amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isProcessing ? _divider : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isProcessing
              ? null
              : [
                  BoxShadow(
                      color: _amber.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
        ),
        child: Center(
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _amber),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Payer ${widget.total.toStringAsFixed(2)} €',
                      style: GoogleFonts.lora(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Badge sécurité ────────────────────────────────────────────────────────────
  Widget _buildSecurityBadge() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: _textLight),
          const SizedBox(width: 5),
          Text('Sécurisé par ',
              style: GoogleFonts.lora(fontSize: 10, color: _textLight)),
          Text('stripe',
              style: GoogleFonts.lora(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF635BFF))),
        ],
      ),
    );
  }

  // ── Vue succès ────────────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _successCtrl,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [_amberLight, _amber],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: _amber.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 8)
                    ],
                  ),
                  child: Opacity(
                    opacity: _checkAnim.value,
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 72),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => Opacity(
                opacity: _fadeAnim.value,
                child: Column(
                  children: [
                    Text('Paiement réussi !',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary)),
                    const SizedBox(height: 10),
                    Text('Votre commande est en route vers la cuisine',
                        style: GoogleFonts.lora(
                            fontSize: 14,
                            color: _textSecond)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _surfaceVar,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.table_restaurant_rounded,
                              color: _amber, size: 16),
                          const SizedBox(width: 8),
                          Text('Table ${widget.tableNumber}',
                              style: GoogleFonts.lora(
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
