// // ignore: avoid_web_libraries_in_flutter
// import 'dart:async';
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
// // ignore: avoid_web_libraries_in_flutter
// import 'dart:js' as js;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// // ignore: avoid_web_libraries_in_flutter, undefined_prefixed_name
// import 'dart:ui_web' as ui_web;
// import '../config/api_config.dart';

// const _amber = Color(0xFFC8901A);
// const _amberLight = Color(0xFFE8A83A);
// const _bg = Color(0xFFFFFDF7);
// const _textPrimary = Color(0xFF1A1714);
// const _textSecond = Color(0xFF6B6350);

// class StripePaymentWeb extends StatefulWidget {
//   final String clientSecret;
//   final double amount;
//   final Function(Map<String, String>? billingDetails) onSuccess;
//   final Function(String) onError;
//   final VoidCallback onCancel;

//   const StripePaymentWeb({
//     super.key,
//     required this.clientSecret,
//     required this.amount,
//     required this.onSuccess,
//     required this.onError,
//     required this.onCancel,
//   });

//   @override
//   State<StripePaymentWeb> createState() => _StripePaymentWebState();
// }

// class _StripePaymentWebState extends State<StripePaymentWeb> {
//   bool _isProcessing = false;
//   String? _errorMessage;
//   final String _viewId = 'stripe-payment-element-${DateTime.now().millisecondsSinceEpoch}';
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   bool _isStripeReady = false;
//   bool _showPayButton = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeStripeElement();
    
//     // Écouter les changements dans les champs
//     _emailController.addListener(_checkFormCompletion);
//     _nameController.addListener(_checkFormCompletion);
//   }

//   @override
//   void dispose() {
//     _emailController.removeListener(_checkFormCompletion);
//     _nameController.removeListener(_checkFormCompletion);
//     _emailController.dispose();
//     _nameController.dispose();
//     super.dispose();
//   }

//   void _checkFormCompletion() {
//     final email = _emailController.text.trim();
//     final name = _nameController.text.trim();
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
//     setState(() {
//       // Afficher le bouton si email et nom sont valides
//       _showPayButton = email.isNotEmpty && 
//                        name.isNotEmpty && 
//                        emailRegex.hasMatch(email);
//     });
//   }

//   void _initializeStripeElement() {
//     // Enregistrer la vue pour le Payment Element
//     // ignore: undefined_prefixed_name
//     ui_web.platformViewRegistry.registerViewFactory(
//       _viewId,
//       (int viewId) {
//         final container = html.DivElement()
//           ..id = 'payment-element-container'
//           ..style.width = '100%'
//           ..style.height = '100%';

//         // Initialiser Stripe Elements
//         _setupStripeElements(container);

//         return container;
//       },
//     );
//   }

//   void _setupStripeElements(html.DivElement container) {
//     // Attendre que Stripe soit chargé
//     Future.delayed(const Duration(milliseconds: 500), () {
//       try {
//         // Vérifier que Stripe est disponible
//         if (js.context['Stripe'] == null) {
//           if (kDebugMode) {
//             print('[Stripe] Stripe.js not loaded');
//           }
//           setState(() {
//             _errorMessage = 'Stripe n\'est pas chargé. Veuillez rafraîchir la page.';
//           });
//           return;
//         }

//         if (kDebugMode) {
//           print('[Stripe] Initializing Stripe Elements');
//           print('  Publishable Key: ${ApiConfig.stripePublishableKey.substring(0, 20)}...');
//         }

//         // Créer l'instance Stripe
//         final stripe = js.context.callMethod('Stripe', [
//           ApiConfig.stripePublishableKey
//         ]);

//         // Créer les Elements
//         final elements = stripe.callMethod('elements', [
//           js.JsObject.jsify({
//             'clientSecret': widget.clientSecret,
//             'appearance': {
//               'theme': 'stripe',
//               'variables': {
//                 'colorPrimary': '#C8901A',
//                 'colorBackground': '#FFFDF7',
//                 'colorText': '#1A1714',
//                 'colorDanger': '#df1b41',
//                 'fontFamily': 'system-ui, sans-serif',
//                 'spacingUnit': '4px',
//                 'borderRadius': '12px',
//               },
//             },
//           })
//         ]);

//         // Créer le Payment Element avec options (sans Link)
//         final paymentElement = elements.callMethod('create', [
//           'payment',
//           js.JsObject.jsify({
//             'layout': {
//               'type': 'tabs',
//               'defaultCollapsed': false,
//               'radios': false,
//               'spacedAccordionItems': false,
//             },
//             'paymentMethodOrder': ['card', 'bancontact'],
//             'wallets': {
//               'applePay': 'never',
//               'googlePay': 'never',
//             },
//             'fields': {
//               'billingDetails': {
//                 'email': 'never',
//                 'name': 'never',
//                 'phone': 'never',
//                 'address': 'auto',
//               }
//             },
//             'terms': {
//               'card': 'never',
//               'bancontact': 'never',
//             },
//           })
//         ]);

//         // Monter le Payment Element
//         paymentElement.callMethod('mount', ['#payment-element-container']);

//         if (kDebugMode) {
//           print('[Stripe] Payment Element mounted successfully');
//         }

//         // Écouter les changements du Payment Element via JavaScript
//         Future.delayed(const Duration(milliseconds: 1000), () {
//           try {
//             js.context.callMethod('eval', ['''
//               (function() {
//                 try {
//                   const elements = window.elementsInstance;
//                   if (!elements) {
//                     console.error('[Stripe] Elements instance not found');
//                     return;
//                   }
                  
//                   // Créer un observer pour détecter quand l'élément est monté
//                   const checkElement = setInterval(function() {
//                     const paymentElement = document.querySelector('#payment-element-container iframe');
//                     if (paymentElement) {
//                       clearInterval(checkElement);
//                       console.log('[Stripe] Payment Element iframe detected');
                      
//                       // Simuler que Stripe est prêt après un délai
//                       setTimeout(function() {
//                         if (window.onStripeElementChange) {
//                           window.onStripeElementChange(false);
//                         }
//                       }, 500);
//                     }
//                   }, 100);
                  
//                   // Timeout après 5 secondes
//                   setTimeout(function() {
//                     clearInterval(checkElement);
//                   }, 5000);
//                 } catch (e) {
//                   console.error('[Stripe] Error setting up listener:', e);
//                 }
//               })();
//             ''']);
//           } catch (e) {
//             if (kDebugMode) {
//               print('[Stripe] Error setting up change listener: $e');
//             }
//           }
//         });

//         // Créer le callback Dart
//         js.context['onStripeElementChange'] = (bool isComplete) {
//           if (kDebugMode) {
//             print('[Stripe] Payment Element changed: $isComplete');
//           }
//           if (mounted) {
//             setState(() {
//               _isStripeReady = isComplete;
//               _checkFormCompletion();
//             });
//           }
//         };

//         // Stocker les références pour plus tard
//         js.context['stripeInstance'] = stripe;
//         js.context['elementsInstance'] = elements;
//       } catch (e) {
//         debugPrint('Erreur lors de l\'initialisation de Stripe: $e');
//         if (kDebugMode) {
//           print('[Stripe] Initialization error: $e');
//         }
//         setState(() {
//           _errorMessage = 'Erreur lors de l\'initialisation du paiement.';
//         });
//       }
//     });
//   }

//   Future<void> _handleSubmit() async {
//     if (_isProcessing) return;

//     // Validation des champs
//     if (_emailController.text.trim().isEmpty) {
//       setState(() {
//         _errorMessage = 'Veuillez entrer votre email';
//       });
//       return;
//     }

//     if (_nameController.text.trim().isEmpty) {
//       setState(() {
//         _errorMessage = 'Veuillez entrer votre nom complet';
//       });
//       return;
//     }

//     // Validation basique de l'email
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(_emailController.text.trim())) {
//       setState(() {
//         _errorMessage = 'Veuillez entrer un email valide';
//       });
//       return;
//     }

//     if (kDebugMode) {
//       print('[Stripe] Starting payment submission');
//       print('[Stripe] Email: ${_emailController.text.trim()}');
//       print('[Stripe] Name: ${_nameController.text.trim()}');
//     }

//     setState(() {
//       _isProcessing = true;
//       _errorMessage = null;
//     });

//     try {
//       final stripe = js.context['stripeInstance'];
//       final elements = js.context['elementsInstance'];

//       if (stripe == null || elements == null) {
//         throw Exception('Stripe n\'est pas initialisé');
//       }

//       // Confirmer le paiement
//       final result = await _confirmPayment(stripe, elements);

//       if (result['error'] != null) {
//         final error = result['error'];
//         final errorMessage = error['message'] ?? 'Erreur de paiement';
        
//         if (kDebugMode) {
//           print('[Stripe] Payment error: $errorMessage');
//         }
        
//         setState(() {
//           _errorMessage = errorMessage;
//           _isProcessing = false;
//         });
//         widget.onError(errorMessage);
//       } else {
//         // Paiement réussi
//         if (kDebugMode) {
//           print('[Stripe] Payment successful');
//         }
        
//         // Utiliser les billing details des champs personnalisés
//         final billingDetails = <String, String>{
//           'email': _emailController.text.trim(),
//           'name': _nameController.text.trim(),
//         };
        
//         if (kDebugMode) {
//           print('[Stripe] Billing details: $billingDetails');
//         }
        
//         widget.onSuccess(billingDetails);
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('[Stripe] Exception during payment: $e');
//       }
      
//       setState(() {
//         _errorMessage = 'Une erreur est survenue: $e';
//         _isProcessing = false;
//       });
//       widget.onError(_errorMessage!);
//     }
//   }

//   Future<Map<String, dynamic>> _confirmPayment(dynamic stripe, dynamic elements) async {
//     final completer = Completer<Map<String, dynamic>>();
    
//     try {
//       if (kDebugMode) {
//         print('[Stripe] Confirming payment...');
//       }

//       // Créer un callback JavaScript pour gérer le résultat
//       js.context['handleStripeResult'] = (result) {
//         if (kDebugMode) {
//           print('[Stripe] Payment result received');
//           print('[Stripe] Result: ${js.context.callMethod('JSON.stringify', [result])}');
//         }
        
//         try {
//           // Convertir le résultat JS en Map Dart
//           final resultMap = _jsObjectToMap(result);
          
//           if (resultMap['error'] != null) {
//             final error = resultMap['error'] as Map<String, dynamic>;
//             if (kDebugMode) {
//               print('[Stripe] Payment error: ${error['message']}');
//             }
//             completer.complete({
//               'error': {
//                 'message': error['message'] ?? 'Erreur de paiement',
//               }
//             });
//           } else if (resultMap['paymentIntent'] != null) {
//             final paymentIntent = resultMap['paymentIntent'] as Map<String, dynamic>;
//             final status = paymentIntent['status'];
            
//             if (kDebugMode) {
//               print('[Stripe] Payment status: $status');
//               print('[Stripe] Payment method: ${paymentIntent['payment_method']}');
//             }
            
//             if (status == 'succeeded' || status == 'processing') {
//               completer.complete({
//                 'paymentIntent': {
//                   'status': status,
//                   'payment_method': paymentIntent['payment_method'],
//                   'id': paymentIntent['id'],
//                 },
//               });
//             } else {
//               completer.complete({
//                 'error': {
//                   'message': 'Le paiement n\'a pas abouti. Statut: $status',
//                 }
//               });
//             }
//           } else {
//             completer.complete({
//               'error': {
//                 'message': 'Réponse invalide de Stripe',
//               }
//             });
//           }
//         } catch (e) {
//           if (kDebugMode) {
//             print('[Stripe] Error processing result: $e');
//           }
//           completer.complete({
//             'error': {
//               'message': 'Erreur lors du traitement du résultat: $e',
//             }
//           });
//         }
//       };

//       // Récupérer les billing details depuis les contrôleurs
//       final email = _emailController.text.trim();
//       final name = _nameController.text.trim();

//       // Appeler confirmPayment avec le callback et les billing details
//       js.context.callMethod('eval', ['''
//         (async function() {
//           try {
//             const stripe = window.stripeInstance;
//             const elements = window.elementsInstance;
            
//             const result = await stripe.confirmPayment({
//               elements: elements,
//               confirmParams: {
//                 return_url: window.location.href,
//                 payment_method_data: {
//                   billing_details: {
//                     email: "$email",
//                     name: "$name",
//                   }
//                 }
//               },
//               redirect: 'if_required',
//             });
            
//             window.handleStripeResult(result);
//           } catch (error) {
//             window.handleStripeResult({ error: { message: error.message } });
//           }
//         })();
//       ''']);

//       // Attendre le résultat avec un timeout de 30 secondes
//       return await completer.future.timeout(
//         const Duration(seconds: 30),
//         onTimeout: () {
//           if (kDebugMode) {
//             print('[Stripe] Payment confirmation timeout');
//           }
//           return {
//             'error': {
//               'message': 'Le paiement a pris trop de temps. Veuillez réessayer.',
//             }
//           };
//         },
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('[Stripe] Payment confirmation error: $e');
//       }
//       return {
//         'error': {
//           'message': e.toString(),
//         }
//       };
//     }
//   }

//   // Convertir un JsObject en Map Dart
//   Map<String, dynamic> _jsObjectToMap(dynamic jsObject) {
//     if (jsObject == null) return {};
    
//     try {
//       final jsonString = js.context.callMethod('JSON.stringify', [jsObject]);
//       // Parse le JSON en Dart
//       final Map<String, dynamic> result = {};
      
//       // Extraire les propriétés principales
//       if (js.context.callMethod('eval', ['typeof $jsObject.error !== "undefined"'])) {
//         final error = jsObject['error'];
//         if (error != null) {
//           result['error'] = {
//             'message': error['message']?.toString() ?? 'Erreur inconnue',
//           };
//         }
//       }
      
//       if (js.context.callMethod('eval', ['typeof $jsObject.paymentIntent !== "undefined"'])) {
//         final pi = jsObject['paymentIntent'];
//         if (pi != null) {
//           result['paymentIntent'] = {
//             'id': pi['id']?.toString(),
//             'status': pi['status']?.toString(),
//             'payment_method': pi['payment_method']?.toString(),
//           };
//         }
//       }
      
//       return result;
//     } catch (e) {
//       if (kDebugMode) {
//         print('[Stripe] Error converting JS object: $e');
//       }
//       return {};
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
    
//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: screenHeight * 0.88, // Augmenté à 88% pour tout afficher
//         maxWidth: screenWidth > 600 ? 500 : screenWidth * 0.95,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Header compact
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//             decoration: const BoxDecoration(
//               color: _bg,
//               border: Border(
//                 bottom: BorderSide(color: Color(0xFFEDE8D8), width: 1),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Paiement',
//                         style: GoogleFonts.playfairDisplay(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: _textPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Complétez les informations',
//                         style: GoogleFonts.lora(
//                           fontSize: 12,
//                           color: _textSecond,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: _isProcessing ? null : widget.onCancel,
//                   icon: const Icon(Icons.close_rounded),
//                   color: _textSecond,
//                   iconSize: 22,
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                 ),
//               ],
//             ),
//           ),

//           // Contenu SANS scroll - tout visible
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Champ Email compact
//                 Text(
//                   'Email',
//                   style: GoogleFonts.lora(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: _textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 TextField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   enabled: !_isProcessing,
//                   decoration: InputDecoration(
//                     hintText: 'votre@email.com',
//                     hintStyle: GoogleFonts.lora(
//                       fontSize: 13,
//                       color: _textSecond.withOpacity(0.5),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _amber, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                   ),
//                   style: GoogleFonts.lora(
//                     fontSize: 13,
//                     color: _textPrimary,
//                   ),
//                 ),
                
//                 const SizedBox(height: 10),
                
//                 // Champ Nom complet compact
//                 Text(
//                   'Nom complet',
//                   style: GoogleFonts.lora(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: _textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 TextField(
//                   controller: _nameController,
//                   keyboardType: TextInputType.name,
//                   enabled: !_isProcessing,
//                   decoration: InputDecoration(
//                     hintText: 'Jean Dupont',
//                     hintStyle: GoogleFonts.lora(
//                       fontSize: 13,
//                       color: _textSecond.withOpacity(0.5),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _amber, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                   ),
//                   style: GoogleFonts.lora(
//                     fontSize: 13,
//                     color: _textPrimary,
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // Payment Element - hauteur augmentée
//                 Container(
//                   height: 240, // Augmenté de 180 à 240px
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: const Color(0xFFEDE8D8)),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: HtmlElementView(viewType: _viewId),
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 // Message d'erreur compact
//                 if (_errorMessage != null)
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF0F0),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFFFCDD2)),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.error_outline_rounded,
//                           color: Color(0xFFB71C1C),
//                           size: 16,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _errorMessage!,
//                             style: GoogleFonts.lora(
//                               fontSize: 12,
//                               color: const Color(0xFFB71C1C),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                 if (_errorMessage != null) const SizedBox(height: 12),

//                 // Bouton payer - Apparaît SEULEMENT si email ET nom sont remplis
//                 if (_showPayButton)
//                   GestureDetector(
//                     onTap: _isProcessing ? null : _handleSubmit,
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       height: 52,
//                       decoration: BoxDecoration(
//                         gradient: _isProcessing
//                             ? null
//                             : const LinearGradient(
//                                 colors: [_amberLight, _amber],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                         color: _isProcessing ? const Color(0xFFEDE8D8) : null,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: _isProcessing
//                             ? null
//                             : [
//                                 BoxShadow(
//                                   color: _amber.withOpacity(0.35),
//                                   blurRadius: 12,
//                                   offset: const Offset(0, 4),
//                                 )
//                               ],
//                       ),
//                       child: Center(
//                         child: _isProcessing
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.5,
//                                   color: _amber,
//                                 ),
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(
//                                     Icons.lock_rounded,
//                                     color: Colors.white,
//                                     size: 16,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'Payer ${widget.amount.toStringAsFixed(2)} €',
//                                     style: GoogleFonts.lora(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),

//                 // Message d'indication compact - Affiché si le bouton n'est pas visible
//                 if (!_showPayButton && !_isProcessing)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF8E1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFFFE082)),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.info_outline_rounded,
//                           color: Color(0xFFF57C00),
//                           size: 14,
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: Text(
//                             'Remplissez tous les champs pour voir le bouton',
//                             style: GoogleFonts.lora(
//                               fontSize: 11,
//                               color: const Color(0xFFF57C00),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                 const SizedBox(height: 10),

//                 // Badge sécurité compact
//                 Center(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.lock_outline_rounded,
//                         size: 11,
//                         color: Color(0xFFA89F85),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Paiement sécurisé par ',
//                         style: GoogleFonts.lora(
//                           fontSize: 9,
//                           color: const Color(0xFFA89F85),
//                         ),
//                       ),
//                       Text(
//                         'stripe',
//                         style: GoogleFonts.lora(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w900,
//                           color: const Color(0xFF635BFF),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
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
  final String _viewId =
      'stripe-payment-element-${DateTime.now().millisecondsSinceEpoch}';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _showPayButton = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFormCompletion);
    _nameController.addListener(_checkFormCompletion);
    _registerStripeView();
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkFormCompletion);
    _nameController.removeListener(_checkFormCompletion);
    _emailController.dispose();
    _nameController.dispose();
    js.context['stripeInstance'] = null;
    js.context['elementsInstance'] = null;
    js.context['handleStripeResult'] = null;
    js.context['onStripeElementChange'] = null;
    super.dispose();
  }

  void _checkFormCompletion() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    final valid =
        email.isNotEmpty && name.isNotEmpty && emailRegex.hasMatch(email);
    if (valid != _showPayButton) setState(() => _showPayButton = valid);
  }

  void _registerStripeView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final container = html.DivElement()
          ..id = 'payment-element-container'
          ..style.width = '100%'
          ..style.height = '100%';
        _setupStripeElements();
        return container;
      },
    );
  }

  void _setupStripeElements() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      try {
        if (js.context['Stripe'] == null) {
          setState(() => _errorMessage =
              'Stripe n\'est pas chargé. Rafraîchissez la page.');
          return;
        }

        final stripe =
            js.context.callMethod('Stripe', [ApiConfig.stripePublishableKey]);

        final elements = stripe.callMethod('elements', [
          js.JsObject.jsify({
            'clientSecret': widget.clientSecret,
            'appearance': {
              'theme': 'stripe',
              'variables': {
                'colorPrimary': '#C8901A',
                'colorBackground': '#FFFFFF',
                'colorText': '#1A1714',
                'colorDanger': '#df1b41',
                'fontFamily': 'system-ui, sans-serif',
                'spacingUnit': '4px',
                'borderRadius': '12px',
              },
            },
          })
        ]);

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
            'wallets': {'applePay': 'never', 'googlePay': 'never', 'link': 'never'},
            'fields': {
              'billingDetails': {
                'email': 'never',
                'name': 'never',
                // phone et address collectés par Stripe directement
              }
            },
            'terms': {'card': 'never'},
          })
        ]);

        paymentElement.callMethod('mount', ['#payment-element-container']);

        js.context['stripeInstance'] = stripe;
        js.context['elementsInstance'] = elements;

        if (kDebugMode) print('[Stripe] Elements initialized & mounted');
      } catch (e) {
        if (kDebugMode) print('[Stripe] Init error: $e');
        if (mounted) {
          setState(
              () => _errorMessage = 'Erreur d\'initialisation du paiement.');
        }
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Veuillez entrer un email valide.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre nom complet.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final stripe = js.context['stripeInstance'];
      final elements = js.context['elementsInstance'];

      if (stripe == null || elements == null) {
        throw Exception('Stripe n\'est pas initialisé. Réessayez.');
      }

      final result = await _confirmPayment(email, name);

      if (!mounted) return;

      if (result['error'] != null) {
        final msg = result['error']['message'] ?? 'Erreur de paiement';
        setState(() {
          _errorMessage = msg;
          _isProcessing = false;
        });
        widget.onError(msg);
      } else {
        widget.onSuccess({'email': email, 'name': name});
      }
    } catch (e) {
      if (kDebugMode) print('[Stripe] Submit error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Une erreur est survenue. Réessayez.';
          _isProcessing = false;
        });
        widget.onError(_errorMessage!);
      }
    }
  }

  /// ─── CORRECTION PRINCIPALE ───────────────────────────────────────────────
  /// On stocke le JSON dans window.__stripeResult (string) et on le récupère
  /// en Dart avec js.context['__stripeResult'].toString() — pas de callback
  /// JS→Dart qui cause des problèmes de type.
  Future<Map<String, dynamic>> _confirmPayment(
      String email, String name) async {
    final safeEmail = email.replaceAll('"', '\\"');
    final safeName = name.replaceAll('"', '\\"');

    // Réinitialiser le résultat précédent
    js.context['__stripeResult'] = null;

    js.context.callMethod('eval', ['''
      (async function() {
        try {
          const stripe   = window.stripeInstance;
          const elements = window.elementsInstance;

          const result = await stripe.confirmPayment({
            elements: elements,
            confirmParams: {
              return_url: window.location.href,
              payment_method_data: {
                billing_details: {
                  email: "$safeEmail",
                  name:  "$safeName",
                }
              }
            },
            redirect: 'if_required',
          });

          if (result.error) {
            window.__stripeResult = JSON.stringify({
              error: { message: result.error.message || 'Erreur inconnue' }
            });
          } else if (result.paymentIntent) {
            window.__stripeResult = JSON.stringify({
              paymentIntent: {
                id:             result.paymentIntent.id,
                status:         result.paymentIntent.status,
                payment_method: result.paymentIntent.payment_method,
              }
            });
          } else {
            window.__stripeResult = JSON.stringify({
              error: { message: 'Réponse Stripe inattendue' }
            });
          }
        } catch (err) {
          window.__stripeResult = JSON.stringify({
            error: { message: err.message || 'Exception inattendue' }
          });
        }
      })();
    ''']);

    // Polling sur window.__stripeResult (max 45 s)
    const pollInterval = Duration(milliseconds: 300);
    const maxWait = Duration(seconds: 45);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);
      final raw = js.context['__stripeResult'];
      if (raw != null) {
        final jsonStr = raw.toString();
        if (kDebugMode) print('[Stripe] Raw result: $jsonStr');
        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          return decoded;
        } catch (e) {
          return {'error': <String, dynamic>{'message': 'JSON invalide: $e'}};
        }
      }
    }

    return {
      'error': <String, dynamic>{
        'message': 'Délai dépassé. Vérifiez votre connexion et réessayez.'
      }
    };
  }

  // ─────────────────────────── UI ───────────────────────────

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isProcessing,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.lora(fontSize: 13, color: _textSecond.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEDE8D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _amber, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: GoogleFonts.lora(fontSize: 13, color: _textPrimary),
        ),
      ],
    );
  }

  Widget _buildPaymentElement() {
    return Container(
      height: 340, // assez grand pour carte + bancontact + tous les champs
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE8D8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB71C1C), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.lora(
                  fontSize: 12,
                  color: const Color(0xFFB71C1C),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _handleSubmit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: _isProcessing
              ? null
              : const LinearGradient(
                  colors: [_amberLight, _amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isProcessing ? const Color(0xFFEDE8D8) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isProcessing
              ? null
              : [
                  BoxShadow(
                      color: _amber.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Center(
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
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
                      'Payer ${widget.amount.toStringAsFixed(2)} €',
                      style: GoogleFonts.lora(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFillHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF57C00), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Remplissez votre email et nom pour continuer',
              style:
                  GoogleFonts.lora(fontSize: 11, color: const Color(0xFFF57C00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: _bg,
        border:
            Border(bottom: BorderSide(color: Color(0xFFEDE8D8), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complétez les informations',
                  style: GoogleFonts.lora(fontSize: 12, color: _textSecond),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isProcessing ? null : widget.onCancel,
            icon: const Icon(Icons.close_rounded),
            color: _textSecond,
            iconSize: 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxW = mq.size.width > 600 ? 500.0 : mq.size.width * 0.95;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: _bg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'votre@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        label: 'Nom complet',
                        controller: _nameController,
                        hint: 'Jean Dupont',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentElement(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        _buildErrorBanner(),
                      ],
                      const SizedBox(height: 12),
                      _showPayButton ? _buildPayButton() : _buildFillHint(),
                      const SizedBox(height: 10),
                      // Badge sécurité
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 11, color: Color(0xFFA89F85)),
                            const SizedBox(width: 4),
                            Text('Paiement sécurisé par ',
                                style: GoogleFonts.lora(
                                    fontSize: 9,
                                    color: const Color(0xFFA89F85))),
                            Text('stripe',
                                style: GoogleFonts.lora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF635BFF))),
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
      ),
    );
  }
}