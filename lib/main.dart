import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'services/stripe_service.dart';
import 'screens/menu_screen.dart'; // Import MenuScreen
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Stripe
  await StripeService.initialize();

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style de la barre de statut système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const QROrderApp());
}

/// Extrait les paramètres de l'URL (hash fragment)
/// Format attendu: /#/menu?restaurantId=xxx&tableId=xxx
Map<String, String> _extractUrlParameters() {
  if (kIsWeb) {
    try {
      final fullUrl = html.window.location.href;
      debugPrint('🔍 URL complète: $fullUrl');
      
      final uri = Uri.parse(fullUrl);
      debugPrint('🔍 URI fragment: ${uri.fragment}');
      debugPrint('🔍 URI query: ${uri.query}');
      
      // Vérifier d'abord le fragment (hash)
      if (uri.fragment.isNotEmpty) {
        debugPrint('✓ Fragment trouvé: ${uri.fragment}');
        
        // Le fragment peut être: /menu?restaurantId=xxx&tableId=xxx
        final fragmentParts = uri.fragment.split('?');
        debugPrint('🔍 Fragment parts: $fragmentParts');
        
        if (fragmentParts.length > 1) {
          final queryString = fragmentParts[1];
          debugPrint('🔍 Query string: $queryString');
          
          final params = Uri.splitQueryString(queryString);
          debugPrint('🔍 Params extraits: $params');
          
          if (params.containsKey('restaurantId') && params.containsKey('tableId')) {
            debugPrint('✅ Paramètres trouvés!');
            debugPrint('   - restaurantId: ${params['restaurantId']}');
            debugPrint('   - tableId: ${params['tableId']}');
            return {
              'restaurantId': params['restaurantId']!,
              'tableId': params['tableId']!,
            };
          } else {
            debugPrint('❌ Paramètres manquants dans le fragment');
            debugPrint('   - restaurantId présent: ${params.containsKey('restaurantId')}');
            debugPrint('   - tableId présent: ${params.containsKey('tableId')}');
          }
        } else {
          debugPrint('❌ Pas de query string dans le fragment');
        }
      } else {
        debugPrint('❌ Fragment vide');
      }
      
      // Fallback: vérifier les query parameters normaux
      debugPrint('🔍 Tentative fallback avec query parameters normaux...');
      if (uri.queryParameters.containsKey('restaurantId') && 
          uri.queryParameters.containsKey('tableId')) {
        debugPrint('✅ Paramètres trouvés dans query parameters!');
        return {
          'restaurantId': uri.queryParameters['restaurantId']!,
          'tableId': uri.queryParameters['tableId']!,
        };
      } else {
        debugPrint('❌ Paramètres non trouvés dans query parameters');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'extraction des paramètres URL: $e');
    }
  } else {
    debugPrint('❌ Pas en mode Web');
  }
  
  debugPrint('❌ Aucun paramètre trouvé - Retour map vide');
  return {};
}

class QROrderApp extends StatelessWidget {
  const QROrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Extraire les paramètres de l'URL
    final urlParams = _extractUrlParameters();
    
    return MultiProvider(
      providers: [
        // Services (singletons)
        Provider<MenuService>(create: (_) => MenuService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<StripeService>(create: (_) => StripeService()),

        // Providers avec état
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<OrderService, OrderProvider>(
          create: (ctx) => OrderProvider(ctx.read<OrderService>()),
          update: (_, orderService, previous) =>
              previous ?? OrderProvider(orderService),
        ),
      ],
      child: MaterialApp(
        title: 'QR Order - Client',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        // Splash screen avec les paramètres dynamiques de l'URL
        home: urlParams.containsKey('restaurantId') && urlParams.containsKey('tableId')
            ? SplashScreen(
                restaurantId: urlParams['restaurantId']!,
                tableId: urlParams['tableId']!,
              )
            : const _ErrorScreen(
                message: 'Paramètres manquants dans l\'URL.\n\n'
                    'Format attendu:\n'
                    '/#/menu?restaurantId=xxx&tableId=xxx',
              ),
      ),
    );
  }
}

/// Écran d'erreur affiché quand les paramètres URL sont manquants
class _ErrorScreen extends StatelessWidget {
  final String message;
  
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFDF6E3),
                  border: Border.all(
                    color: const Color(0xFFC8901A).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC8901A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code invalide',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF3D2B0E),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A5C2E),
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 32),
              Text(
                'Veuillez scanner un QR code valide',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB8924A),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
