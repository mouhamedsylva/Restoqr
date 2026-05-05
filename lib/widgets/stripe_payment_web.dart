// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter, undefined_prefixed_name
import 'dart:ui_web' as ui_web;
import '../config/api_config.dart';

const _amber = Color(0xFFC8901A);
const _amberLight = Color(0xFFE8A83A);
const _bg = Color(0xFFFFFDF7);
const _textPrimary = Color(0xFF1A1714);
const _textSecond = Color(0xFF6B6350);

class StripePaymentWeb extends StatefulWidget {
  final String clientSecret;
  final double amount;
  final Function(Map<String, String>? billingDetails) onSuccess;
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeStripeElement();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _initializeStripeElement() {
    // Enregistrer la vue pour le Payment Element
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
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
          if (kDebugMode) {
            print('[Stripe] Stripe.js not loaded');
          }
          setState(() {
            _errorMessage = 'Stripe n\'est pas chargé. Veuillez rafraîchir la page.';
          });
          return;
        }

        if (kDebugMode) {
          print('[Stripe] Initializing Stripe Elements');
          print('  Publishable Key: ${ApiConfig.stripePublishableKey.substring(0, 20)}...');
        }

        // Créer l'instance Stripe
        final stripe = js.context.callMethod('Stripe', [
          ApiConfig.stripePublishableKey
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

        // Créer le Payment Element avec options (sans Link)
        final paymentElement = elements.callMethod('create', [
          'payment',
          js.JsObject.jsify({
            'layout': {
              'type': 'tabs',
              'defaultCollapsed': false,
              'radios': false,
              'spacedAccordionItems': false,
            },
            'paymentMethodOrder': ['card', 'bancontact'],
            'wallets': {
              'applePay': 'never',
              'googlePay': 'never',
            },
            'link': {
              'enabled': false,
            },
            'fields': {
              'billingDetails': {
                'email': 'never',
                'name': 'never',
                'phone': 'never',
                'address': 'auto',
              }
            },
            'terms': {
              'card': 'never',
              'bancontact': 'never',
            },
          })
        ]);

        // Monter le Payment Element
        paymentElement.callMethod('mount', ['#payment-element-container']);

        if (kDebugMode) {
          print('[Stripe] Payment Element mounted successfully');
        }

        // Stocker les références pour plus tard
        js.context['stripeInstance'] = stripe;
        js.context['elementsInstance'] = elements;
      } catch (e) {
        debugPrint('Erreur lors de l\'initialisation de Stripe: $e');
        if (kDebugMode) {
          print('[Stripe] Initialization error: $e');
        }
        setState(() {
          _errorMessage = 'Erreur lors de l\'initialisation du paiement.';
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;

    // Validation des champs
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
      });
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre nom complet';
      });
      return;
    }

    // Validation basique de l'email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Veuillez entrer un email valide';
      });
      return;
    }

    if (kDebugMode) {
      print('[Stripe] Starting payment submission');
      print('[Stripe] Email: ${_emailController.text.trim()}');
      print('[Stripe] Name: ${_nameController.text.trim()}');
    }

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
        final errorMessage = error['message'] ?? 'Erreur de paiement';
        
        if (kDebugMode) {
          print('[Stripe] Payment error: $errorMessage');
        }
        
        setState(() {
          _errorMessage = errorMessage;
          _isProcessing = false;
        });
        widget.onError(errorMessage);
      } else {
        // Paiement réussi
        if (kDebugMode) {
          print('[Stripe] Payment successful');
        }
        
        // Utiliser les billing details des champs personnalisés
        final billingDetails = <String, String>{
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
        };
        
        if (kDebugMode) {
          print('[Stripe] Billing details: $billingDetails');
        }
        
        widget.onSuccess(billingDetails);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Stripe] Exception during payment: $e');
      }
      
      setState(() {
        _errorMessage = 'Une erreur est survenue: $e';
        _isProcessing = false;
      });
      widget.onError(_errorMessage!);
    }
  }

  Future<Map<String, dynamic>> _confirmPayment(dynamic stripe, dynamic elements) async {
    final completer = Completer<Map<String, dynamic>>();
    
    try {
      if (kDebugMode) {
        print('[Stripe] Confirming payment...');
      }

      // Créer un callback JavaScript pour gérer le résultat
      js.context['handleStripeResult'] = (result) {
        if (kDebugMode) {
          print('[Stripe] Payment result received');
          print('[Stripe] Result: ${js.context.callMethod('JSON.stringify', [result])}');
        }
        
        try {
          // Convertir le résultat JS en Map Dart
          final resultMap = _jsObjectToMap(result);
          
          if (resultMap['error'] != null) {
            final error = resultMap['error'] as Map<String, dynamic>;
            if (kDebugMode) {
              print('[Stripe] Payment error: ${error['message']}');
            }
            completer.complete({
              'error': {
                'message': error['message'] ?? 'Erreur de paiement',
              }
            });
          } else if (resultMap['paymentIntent'] != null) {
            final paymentIntent = resultMap['paymentIntent'] as Map<String, dynamic>;
            final status = paymentIntent['status'];
            
            if (kDebugMode) {
              print('[Stripe] Payment status: $status');
              print('[Stripe] Payment method: ${paymentIntent['payment_method']}');
            }
            
            if (status == 'succeeded' || status == 'processing') {
              completer.complete({
                'paymentIntent': {
                  'status': status,
                  'payment_method': paymentIntent['payment_method'],
                  'id': paymentIntent['id'],
                },
              });
            } else {
              completer.complete({
                'error': {
                  'message': 'Le paiement n\'a pas abouti. Statut: $status',
                }
              });
            }
          } else {
            completer.complete({
              'error': {
                'message': 'Réponse invalide de Stripe',
              }
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('[Stripe] Error processing result: $e');
          }
          completer.complete({
            'error': {
              'message': 'Erreur lors du traitement du résultat: $e',
            }
          });
        }
      };

      // Récupérer les billing details depuis les contrôleurs
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();

      // Appeler confirmPayment avec le callback et les billing details
      js.context.callMethod('eval', ['''
        (async function() {
          try {
            const stripe = window.stripeInstance;
            const elements = window.elementsInstance;
            
            const result = await stripe.confirmPayment({
              elements: elements,
              confirmParams: {
                return_url: window.location.href,
                payment_method_data: {
                  billing_details: {
                    email: "$email",
                    name: "$name",
                  }
                }
              },
              redirect: 'if_required',
            });
            
            window.handleStripeResult(result);
          } catch (error) {
            window.handleStripeResult({ error: { message: error.message } });
          }
        })();
      ''']);

      // Attendre le résultat avec un timeout de 30 secondes
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (kDebugMode) {
            print('[Stripe] Payment confirmation timeout');
          }
          return {
            'error': {
              'message': 'Le paiement a pris trop de temps. Veuillez réessayer.',
            }
          };
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Stripe] Payment confirmation error: $e');
      }
      return {
        'error': {
          'message': e.toString(),
        }
      };
    }
  }

  // Convertir un JsObject en Map Dart
  Map<String, dynamic> _jsObjectToMap(dynamic jsObject) {
    if (jsObject == null) return {};
    
    try {
      final jsonString = js.context.callMethod('JSON.stringify', [jsObject]);
      // Parse le JSON en Dart
      final Map<String, dynamic> result = {};
      
      // Extraire les propriétés principales
      if (js.context.callMethod('eval', ['typeof $jsObject.error !== "undefined"'])) {
        final error = jsObject['error'];
        if (error != null) {
          result['error'] = {
            'message': error['message']?.toString() ?? 'Erreur inconnue',
          };
        }
      }
      
      if (js.context.callMethod('eval', ['typeof $jsObject.paymentIntent !== "undefined"'])) {
        final pi = jsObject['paymentIntent'];
        if (pi != null) {
          result['paymentIntent'] = {
            'id': pi['id']?.toString(),
            'status': pi['status']?.toString(),
            'payment_method': pi['payment_method']?.toString(),
          };
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[Stripe] Error converting JS object: $e');
      }
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9, // 90% de la hauteur de l'écran
        maxWidth: screenWidth > 600 ? 500 : screenWidth, // Largeur max sur desktop
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header fixe avec bouton de fermeture
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEDE8D8), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        'Entrez vos informations de paiement',
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          color: _textSecond,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isProcessing ? null : widget.onCancel,
                  icon: const Icon(Icons.close_rounded),
                  color: _textSecond,
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Champ Email
                  Text(
                    'Email',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      hintText: 'votre@email.com',
                      hintStyle: GoogleFonts.lora(
                        fontSize: 14,
                        color: _textSecond.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _amber, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Champ Nom complet
                  Text(
                    'Nom complet',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Jean Dupont',
                      hintStyle: GoogleFonts.lora(
                        fontSize: 14,
                        color: _textSecond.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _amber, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Element avec hauteur flexible
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 400,
                      maxHeight: 600,
                    ),
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
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
