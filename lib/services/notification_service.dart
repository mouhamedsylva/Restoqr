import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';

/// Service de gestion des notifications pour les changements de statut de commande
class NotificationService {
  StreamSubscription<OrderStatus>? _subscription;

  /// Commence à écouter les changements de statut pour une commande
  void startListening(Stream<OrderStatus> statusStream, BuildContext context) {
    // Éviter les doublons
    if (_subscription != null) {
      return;
    }

    _subscription = statusStream.listen(
      (status) {
        _handleStatusChange(status, context);
      },
      onError: (error) {
        debugPrint('Error listening to order status: $error');
      },
    );
  }

  /// Arrête d'écouter les changements
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Gère les changements de statut
  void _handleStatusChange(OrderStatus status, BuildContext context) {
    switch (status) {
      case OrderStatus.cancelled:
        _notifyCancellation(context);
        break;
      case OrderStatus.ready:
        _notifyReady(context);
        break;
      case OrderStatus.preparing:
        _notifyPreparing(context);
        break;
      default:
        break;
    }
  }

  /// Notification pour commande annulée
  void _notifyCancellation(BuildContext context) {
    // Vibration forte
    HapticFeedback.heavyImpact();

    // Afficher une notification visuelle
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Commande annulée',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Votre commande a été annulée par le restaurant',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }

    debugPrint('🚫 Order has been cancelled');
  }

  /// Notification pour commande prête
  void _notifyReady(BuildContext context) {
    // Vibration moyenne
    HapticFeedback.mediumImpact();

    // Afficher une notification visuelle
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Commande prête !',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Votre commande est prête à être servie',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }

    debugPrint('✨ Order is ready');
  }

  /// Notification pour commande en préparation
  void _notifyPreparing(BuildContext context) {
    // Vibration légère
    HapticFeedback.lightImpact();

    // Afficher une notification visuelle
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.restaurant_outlined, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Commande acceptée',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Votre commande est en cours de préparation',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }

    debugPrint('🔥 Order is being prepared');
  }

  /// Nettoie les ressources
  void dispose() {
    stopListening();
  }
}
