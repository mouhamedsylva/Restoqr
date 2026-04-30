import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

class QROrderApp extends StatelessWidget {
  const QROrderApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        // Splash screen avec les infos du restaurant
        home: const SplashScreen(
          restaurantId: 'b18ba2cd-f3a6-4334-8ac3-c5eac13e5adc',
          tableId: '33a2819a-f50f-47e0-a406-428b57c7b20c',
        ),
        /* 
        onGenerateRoute: (settings) {
          // ... (code de vérification mis en commentaire)
        },
        */
      ),
    );
  }
}
