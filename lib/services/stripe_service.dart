import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Import conditionnel pour mobile
import 'package:flutter_stripe/flutter_stripe.dart' if (dart.library.html) 'stripe_web_stub.dart';

class StripeService {
  static bool _initialized = false;

  /// Initialise le SDK Stripe — à appeler une seule fois au démarrage
  /// Sur mobile: utilise flutter_stripe
  /// Sur web: utilise Stripe.js via script HTML
  static Future<void> initialize() async {
    if (_initialized) return;
    
    if (!kIsWeb) {
      // Mobile: Initialiser flutter_stripe
      Stripe.publishableKey = ApiConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    }
    // Sur web, Stripe.js est chargé via index.html
    
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

  /// Présente la feuille de paiement Stripe
  /// Sur mobile: utilise la PaymentSheet native
  /// Sur web: redirige vers Stripe Checkout
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
    if (kIsWeb) {
      // Sur web, on utilise Stripe.js avec Payment Element
      return _presentWebPayment(
        clientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        customerEmail: customerEmail,
      );
    } else {
      // Sur mobile, on utilise la PaymentSheet native
      return _presentMobilePayment(
        clientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        customerEmail: customerEmail,
      );
    }
  }

  /// Paiement mobile avec PaymentSheet native
  Future<PaymentResult> _presentMobilePayment({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
    try {
      // 1. Initialiser la PaymentSheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFC8901A),
              background: const Color(0xFFFFFDF7),
              componentBackground: const Color(0xFFFFFFFF),
              componentBorder: const Color(0xFFEDE8D8),
              primaryText: const Color(0xFF1A1714),
              secondaryText: const Color(0xFF6B6350),
              placeholderText: const Color(0xFFA89F85),
            ),
            shapes: const PaymentSheetShape(
              borderRadius: 14,
              borderWidth: 1,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: const Color(0xFFC8901A),
                  text: const Color(0xFFFFFFFF),
                  border: const Color(0xFFC8901A),
                ),
              ),
            ),
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'FR',
            currencyCode: 'eur',
            testEnv: true,
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'FR',
          ),
        ),
      );

      // 2. Présenter la sheet
      await Stripe.instance.presentPaymentSheet();

      return PaymentResult(
        success: true,
        paymentIntentId: clientSecret.split('_secret_').first,
        status: 'succeeded',
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(
          success: false,
          paymentIntentId: '',
          status: 'canceled',
          errorMessage: 'Paiement annulé',
        );
      }
      return PaymentResult(
        success: false,
        paymentIntentId: '',
        status: 'failed',
        errorMessage: e.error.localizedMessage ?? 'Erreur de paiement',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentIntentId: '',
        status: 'failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Paiement web avec Stripe.js
  Future<PaymentResult> _presentWebPayment({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
    try {
      // Sur web, on retourne un résultat spécial qui indique qu'il faut
      // afficher le formulaire de paiement web
      return PaymentResult(
        success: false,
        paymentIntentId: clientSecret.split('_secret_').first,
        status: 'requires_web_payment',
        errorMessage: null,
        clientSecret: clientSecret,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        paymentIntentId: '',
        status: 'failed',
        errorMessage: e.toString(),
      );
    }
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
