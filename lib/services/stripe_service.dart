import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StripeService {
  static bool _initialized = false;

  /// Initialise le SDK Stripe — à appeler une seule fois au démarrage
  /// Stripe n'est disponible que sur mobile (iOS/Android)
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Stripe n'est pas supporté sur le web, on initialise uniquement sur mobile
    if (!kIsWeb) {
      Stripe.publishableKey = ApiConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    }
    
    _initialized = true;
  }

  /// Crée un PaymentIntent côté backend et retourne le clientSecret
  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required String restaurantId,
    required String orderId,
  }) async {
    // Vérifier que nous sommes sur mobile
    if (kIsWeb) {
      throw UnsupportedError('Le paiement Stripe n\'est disponible que sur mobile');
    }
    
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

  /// Présente la feuille de paiement Stripe native et confirme le paiement
  /// Disponible uniquement sur mobile (iOS/Android)
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
    String? customerEmail,
  }) async {
    // Vérifier que nous sommes sur mobile
    if (kIsWeb) {
      return PaymentResult(
        success: false,
        paymentIntentId: '',
        status: 'failed',
        errorMessage: 'Le paiement Stripe n\'est disponible que sur mobile',
      );
    }
    
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
}

class PaymentResult {
  final bool success;
  final String paymentIntentId;
  final String status;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.paymentIntentId,
    required this.status,
    this.errorMessage,
  });
}
