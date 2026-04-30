import 'package:flutter/foundation.dart';

class ApiConfig {
  // Version de l'API
  static const String apiVersion = '/api/v1';
  
  // URL de base selon l'environnement
  // En mode web (ou navigateur), on utilise localhost
  // En mode émulateur Android, c'est 10.0.2.2
  // Remplacez cette IP par l'adresse réseau de votre machine 
  // si vous testez sur un vrai téléphone connecté au même WiFi (ex: 'http://192.168.1.15:3000')
  static String get baseUrl {
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
