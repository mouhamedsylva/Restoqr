import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StripeService {
  static bool _initialized = false;

  /// Initialise le SDK Stripe — à appeler une seule fois au démarrage.
  /// Sur web, Stripe.js est chargé via index.html ; aucune init Dart nécessaire.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Parse les erreurs du backend pour des messages lisibles.
  String _getErrorMessage(int statusCode, String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final message = data['message'];

      switch (statusCode) {
        case 400:
          if (message is List) {
            return 'Données invalides: ${message.join(', ')}';
          }
          return message ?? 'Données de paiement invalides';
        case 401:
          return 'Authentification requise';
        case 402:
          return 'Paiement refusé par votre banque';
        case 404:
          return 'Service de paiement non disponible';
        case 500:
          return 'Erreur serveur. Réessayez dans quelques instants';
        case 503:
          return 'Service temporairement indisponible';
        default:
          return message ?? 'Erreur inattendue ($statusCode)';
      }
    } catch (_) {
      return 'Erreur de communication avec le serveur';
    }
  }

  /// Crée un PaymentIntent côté backend et retourne le clientSecret.
  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required String restaurantId,
    required String orderId,
  }) async {
    if (kDebugMode) {
      print('[Stripe] Creating PaymentIntent:');
      print('  Amount: $amount $currency');
      print('  Order ID: $orderId');
      print('  Restaurant ID: $restaurantId');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/payments/intent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'restaurantId': restaurantId,
              'orderId': orderId,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Le serveur ne répond pas. Vérifiez votre connexion.'),
          );

      if (kDebugMode) {
        print('[Stripe] Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final secret = data['clientSecret'] as String?;

        if (kDebugMode) {
          print('[Stripe] PaymentIntent created successfully');
          if (secret != null && secret.length > 20) {
            print('  Client Secret: ${secret.substring(0, 20)}...');
          }
        }

        if (secret == null || secret.isEmpty) {
          throw Exception('clientSecret manquant dans la réponse');
        }
        return secret;
      } else {
        if (kDebugMode) print('[Stripe] Error response: ${response.body}');
        throw Exception(
            _getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (kDebugMode) print('[Stripe] Exception: $e');
      rethrow;
    }
  }

  /// Crée un PaymentIntent SANS créer de commande.
  /// Les données de commande sont passées dans les metadata.
  Future<String> createPaymentIntentWithoutOrder({
    required double amount,
    required String currency,
    required String restaurantId,
    required String tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (kDebugMode) {
      print('[Stripe] Creating PaymentIntent WITHOUT order:');
      print('  Amount: $amount $currency');
      print('  Restaurant ID: $restaurantId');
      print('  Table ID: $tableId');
      print('  Items: ${items.length}');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/payments/intent-without-order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'restaurantId': restaurantId,
              'tableId': tableId,
              'items': items,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Le serveur ne répond pas. Vérifiez votre connexion.'),
          );

      if (kDebugMode) {
        print('[Stripe] Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final secret = data['clientSecret'] as String?;

        if (kDebugMode) {
          print('[Stripe] PaymentIntent created successfully');
          if (secret != null && secret.length > 20) {
            print('  Client Secret: ${secret.substring(0, 20)}...');
          }
        }

        if (secret == null || secret.isEmpty) {
          throw Exception('clientSecret manquant dans la réponse');
        }
        return secret;
      } else {
        if (kDebugMode) print('[Stripe] Error response: ${response.body}');
        throw Exception(
            _getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (kDebugMode) print('[Stripe] Exception: $e');
      rethrow;
    }
  }

  /// Présente la feuille de paiement Stripe (web uniquement).
  /// Retourne un résultat indiquant que le paiement doit passer par le widget web.
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
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
  final String? clientSecret;

  const PaymentResult({
    required this.success,
    required this.paymentIntentId,
    required this.status,
    this.errorMessage,
    this.clientSecret,
  });
}