import 'package:flutter/foundation.dart';

class ApiConfig {
  // Version de l'API
  static const String apiVersion = '/api/v1';
  
  // URL du backend Railway (production)
  static const String productionUrl = 'https://qr-code-server-production.up.railway.app';
  
  // Mode de développement : true pour utiliser localhost, false pour Railway
  static const bool useLocalServer = false;
  
  // URL de base selon l'environnement
  static String get baseUrl {
    // Si on utilise le serveur de production Railway
    if (!useLocalServer) {
      return '$productionUrl$apiVersion';
    }
    
    // Sinon, utiliser localhost/émulateur pour le développement
    if (kIsWeb) {
      return 'http://localhost:3000$apiVersion';
    } else if (kDebugMode) {
      // Pour émulateur Android
      return 'http://10.0.2.2:3000$apiVersion';
    } else {
      // Pour appareil physique - à configurer selon votre réseau
      // Exemple: return 'http://192.168.1.15:3000$apiVersion';
      return 'http://10.0.2.2:3000$apiVersion';
    }
  }

  // URL WebSocket (sans le préfixe /api/v1)
  static String get socketUrl {
    // Si on utilise le serveur de production Railway
    if (!useLocalServer) {
      return productionUrl;
    }
    
    // Sinon, utiliser localhost/émulateur pour le développement
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (kDebugMode) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  // Configuration Stripe
  static const String stripePublishableKey = 'pk_test_51TK5fgAb5tCT9vASZ0NRdVQtWm9UDHN6OCP0NyoeyRHEbibB1L9bjehkNo2zDZeSEgE94iNJjhLzwXa2hfLbnfsZ00GZmkQ7yE';
}
