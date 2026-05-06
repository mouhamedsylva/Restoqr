import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_persistence_service.dart';
import 'order_status_screen.dart';
import 'payment_screen.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

const _amber = Color(0xFFC8901A);
const _amberLight = Color(0xFFE8A83A);
const _bg = Color(0xFFFFFDF7);
const _textPrimary = Color(0xFF1A1714);
const _textSecond = Color(0xFF6B6350);

class SessionRecoveryScreen extends StatelessWidget {
  final VoidCallback onDismiss;

  const SessionRecoveryScreen({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _amber),
            ),
          );
        }

        final sessionData = snapshot.data;
        if (sessionData == null) {
          // Pas de session à récupérer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onDismiss();
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_amberLight, _amber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _amber.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        sessionData['type'] == 'active_order'
                            ? Icons.restaurant_menu_rounded
                            : Icons.payment_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Titre
                    Text(
                      sessionData['type'] == 'active_order'
                          ? 'Commande en cours'
                          : 'Paiement en cours',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Message
                    Text(
                      sessionData['type'] == 'active_order'
                          ? 'Vous avez une commande active.\nVoulez-vous la suivre ?'
                          : 'Vous avez un paiement en attente.\nVoulez-vous continuer ?',
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        color: _textSecond,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Informations
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDE8D8)),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.table_restaurant_rounded,
                            'Table',
                            sessionData['tableNumber'] ?? 'N/A',
                          ),
                          if (sessionData['type'] == 'pending_order') ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.euro_rounded,
                              'Montant',
                              '${sessionData['total']?.toStringAsFixed(2) ?? '0.00'} €',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton continuer
                    GestureDetector(
                      onTap: () => _handleContinue(context, sessionData),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_amberLight, _amber],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _amber.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            sessionData['type'] == 'active_order'
                                ? 'Suivre ma commande'
                                : 'Continuer le paiement',
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton annuler
                    TextButton(
                      onPressed: () => _handleDismiss(context),
                      child: Text(
                        'Nouvelle commande',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          color: _textSecond,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _amber, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.lora(
            fontSize: 14,
            color: _textSecond,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _checkSession() async {
    // Vérifier d'abord s'il y a une commande active
    final activeOrder = await OrderPersistenceService.getActiveOrder();
    if (activeOrder != null) {
      return {
        'type': 'active_order',
        'orderId': activeOrder['orderId'],
        'restaurantId': activeOrder['restaurantId'],
        'tableNumber': activeOrder['tableNumber'],
      };
    }

    // Ensuite vérifier s'il y a un paiement en cours
    final paymentInProgress = await OrderPersistenceService.isPaymentInProgress();
    if (paymentInProgress) {
      final pendingOrder = await OrderPersistenceService.getPendingOrder();
      if (pendingOrder != null) {
        return {
          'type': 'pending_order',
          'restaurantId': pendingOrder['restaurantId'],
          'tableNumber': pendingOrder['tableNumber'],
          'cartItems': pendingOrder['cartItems'],
          'total': pendingOrder['total'],
        };
      }
    }

    return null;
  }

  void _handleContinue(BuildContext context, Map<String, dynamic> sessionData) {
    if (sessionData['type'] == 'active_order') {
      // Rediriger vers le suivi de commande
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderStatusScreen(
            orderId: sessionData['orderId'] as String,
            tableNumber: sessionData['tableNumber'] as String,
            restaurantId: sessionData['restaurantId'] as String,
          ),
        ),
      );
    } else {
      // Rediriger vers le paiement
      final cartItemsData = sessionData['cartItems'] as List<dynamic>;
      final cartItems = cartItemsData.map((item) {
        return CartItem(
          product: Product(
            id: item['menuItemId'] as String,
            name: (item['name'] as String?) ?? 'Produit',
            description: (item['description'] as String?) ?? '',
            price: (item['price'] as num?)?.toDouble() ?? 0.0,
            category: (item['category'] as String?) ?? '',
            imageUrl: (item['imageUrl'] as String?) ?? '',
            isActive: true,
          ),
          quantity: item['quantity'] as int,
        );
      }).toList();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            restaurantId: sessionData['restaurantId'] as String,
            tableNumber: sessionData['tableNumber'] as String,
            cartItems: cartItems,
            total: (sessionData['total'] as num).toDouble(),
          ),
        ),
      );
    }
  }

  void _handleDismiss(BuildContext context) async {
    // Nettoyer toutes les données persistées
    await OrderPersistenceService.clearAll();
    onDismiss();
  }
}
