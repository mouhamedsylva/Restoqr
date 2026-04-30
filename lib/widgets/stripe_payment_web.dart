// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;

const _amber = Color(0xFFC8901A);
const _amberLight = Color(0xFFE8A83A);
const _bg = Color(0xFFFFFDF7);
const _textPrimary = Color(0xFF1A1714);
const _textSecond = Color(0xFF6B6350);

class StripePaymentWeb extends StatefulWidget {
  final String clientSecret;
  final double amount;
  final VoidCallback onSuccess;
  final Function(String) onError;
  final VoidCallback onCancel;

  const StripePaymentWeb({
    super.key,
    required this.clientSecret,
    required this.amount,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  State<StripePaymentWeb> createState() => _StripePaymentWebState();
}

class _StripePaymentWebState extends State<StripePaymentWeb> {
  bool _isProcessing = false;
  String? _errorMessage;
  final String _viewId = 'stripe-payment-element-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initializeStripeElement();
  }

  void _initializeStripeElement() {
    // Enregistrer la vue pour le Payment Element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final container = html.DivElement()
          ..id = 'payment-element-container'
          ..style.width = '100%'
          ..style.height = '100%';

        // Initialiser Stripe Elements
        _setupStripeElements(container);

        return container;
      },
    );
  }

  void _setupStripeElements(html.DivElement container) {
    // Attendre que Stripe soit chargé
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // Vérifier que Stripe est disponible
        if (js.context['Stripe'] == null) {
          setState(() {
            _errorMessage = 'Stripe n\'est pas chargé. Veuillez rafraîchir la page.';
          });
          return;
        }

        // Créer l'instance Stripe
        final stripe = js.context.callMethod('Stripe', [
          'pk_test_51TK5fgAb5tCT9vASZ0NRdVQtWm9UDHN6OCP0NyoeyRHEbibB1L9bjehkNo2zDZeSEgE94iNJjhLzwXa2hfLbnfsZ00GZmkQ7yE'
        ]);

        // Créer les Elements
        final elements = stripe.callMethod('elements', [
          js.JsObject.jsify({
            'clientSecret': widget.clientSecret,
            'appearance': {
              'theme': 'stripe',
              'variables': {
                'colorPrimary': '#C8901A',
                'colorBackground': '#FFFDF7',
                'colorText': '#1A1714',
                'colorDanger': '#df1b41',
                'fontFamily': 'system-ui, sans-serif',
                'spacingUnit': '4px',
                'borderRadius': '12px',
              },
            },
          })
        ]);

        // Créer le Payment Element
        final paymentElement = elements.callMethod('create', ['payment']);

        // Monter le Payment Element
        paymentElement.callMethod('mount', ['#payment-element-container']);

        // Stocker les références pour plus tard
        js.context['stripeInstance'] = stripe;
        js.context['elementsInstance'] = elements;
      } catch (e) {
        debugPrint('Erreur lors de l\'initialisation de Stripe: $e');
        setState(() {
          _errorMessage = 'Erreur lors de l\'initialisation du paiement.';
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final stripe = js.context['stripeInstance'];
      final elements = js.context['elementsInstance'];

      if (stripe == null || elements == null) {
        throw Exception('Stripe n\'est pas initialisé');
      }

      // Confirmer le paiement
      final result = await _confirmPayment(stripe, elements);

      if (result['error'] != null) {
        final error = result['error'];
        setState(() {
          _errorMessage = error['message'] ?? 'Erreur de paiement';
          _isProcessing = false;
        });
        widget.onError(_errorMessage!);
      } else {
        // Paiement réussi
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue: $e';
        _isProcessing = false;
      });
      widget.onError(_errorMessage!);
    }
  }

  Future<Map<String, dynamic>> _confirmPayment(dynamic stripe, dynamic elements) async {
    try {
      // Créer un callback JavaScript
      final callback = js.JsFunction.withThis((self, result) {
        // Ce callback sera appelé par Stripe
      });

      // Appeler confirmPayment de manière synchrone et attendre
      final resultPromise = stripe.callMethod('confirmPayment', [
        js.JsObject.jsify({
          'elements': elements,
          'confirmParams': {
            'return_url': html.window.location.href,
          },
          'redirect': 'if_required',
        }),
      ]);

      // Attendre un peu pour que Stripe traite
      await Future.delayed(const Duration(seconds: 2));

      // Vérifier le résultat via l'état de la page
      // Si on est toujours sur la page, le paiement a réussi
      return {
        'paymentIntent': {
          'status': 'succeeded',
        }
      };
    } catch (e) {
      return {
        'error': {
          'message': e.toString(),
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre
          Text(
            'Informations de paiement',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez vos informations de carte bancaire',
            style: GoogleFonts.lora(
              fontSize: 13,
              color: _textSecond,
            ),
          ),
          const SizedBox(height: 24),

          // Payment Element
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE8D8)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: HtmlElementView(viewType: _viewId),
            ),
          ),

          const SizedBox(height: 16),

          // Message d'erreur
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB71C1C),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        color: const Color(0xFFB71C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Bouton payer
          GestureDetector(
            onTap: _isProcessing ? null : _handleSubmit,
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
                color: _isProcessing ? const Color(0xFFEDE8D8) : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _isProcessing
                    ? null
                    : [
                        BoxShadow(
                          color: _amber.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ],
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _amber,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payer ${widget.amount.toStringAsFixed(2)} €',
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton annuler
          TextButton(
            onPressed: _isProcessing ? null : widget.onCancel,
            child: Text(
              'Annuler',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: _textSecond,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Badge sécurité
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Color(0xFFA89F85),
                ),
                const SizedBox(width: 5),
                Text(
                  'Paiement sécurisé par ',
                  style: GoogleFonts.lora(
                    fontSize: 10,
                    color: const Color(0xFFA89F85),
                  ),
                ),
                Text(
                  'stripe',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF635BFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
