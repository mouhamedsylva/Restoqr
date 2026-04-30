import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StripeService {
  static bool _initialized = false;

  /// Initialise le SDK Stripe — à appeler une seule fois au démarrage
  /// Application web uniquement - Stripe.js est chargé via index.html
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Sur web, Stripe.js est chargé via index.html
    // Aucune initialisation nécessaire côté Dart
    
    _initialized = true;
  }

  /// Crée un PaymentIntent côté backend et retourne le clientSecret
  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required String restaurantId,
    required String orderId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'restaurantId': restaurantId,
        'orderId': orderId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final secret = data['clientSecret'] as String?;
      if (secret == null || secret.isEmpty) {
        throw Exception('clientSecret manquant dans la réponse');
      }
      return secret;
    } else {
      throw Exception('Erreur PaymentIntent: ${response.statusCode} ${response.body}');
    }
  }

  /// Présente la feuille de paiement Stripe (web uniquement)
  /// Affiche un dialog avec le Payment Element de Stripe.js
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
    // Application web uniquement
    return PaymentResult(
      success: false,
      paymentIntentId: clientSecret.split('_secret_').first,
      status: 'requires_web_payment',
      errorMessage: null,
      clientSecret: clientSecret,
    );
  }
}

class PaymentResult {
  final bool success;
  final String paymentIntentId;
  final String status;
  final String? errorMessage;
  final String? clientSecret; // Pour le paiement web

  const PaymentResult({
    required this.success,
    required this.paymentIntentId,
    required this.status,
    this.errorMessage,
    this.clientSecret,
  });
}
