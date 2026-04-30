import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de test pour vérifier la connexion avec le backend Railway
/// 
/// Usage: dart run test_railway_connection.dart
void main() async {
  const String railwayUrl = 'https://qr-code-server-production.up.railway.app';
  const String apiVersion = '/api/v1';
  
  print('🚀 Test de connexion avec Railway...\n');
  print('URL: $railwayUrl$apiVersion\n');
  
  // Test 1: Health check
  await testHealthCheck(railwayUrl, apiVersion);
  
  // Test 2: Récupération des restaurants
  await testGetRestaurants(railwayUrl, apiVersion);
  
  print('\n✅ Tests terminés !');
}

Future<void> testHealthCheck(String baseUrl, String apiVersion) async {
  print('📡 Test 1: Health Check');
  print('   Endpoint: $baseUrl$apiVersion/health');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl$apiVersion/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('   ✅ Backend accessible !');
      try {
        final data = json.decode(response.body);
        print('   Réponse: $data');
      } catch (e) {
        print('   Réponse: ${response.body}');
      }
    } else {
      print('   ⚠️  Status inattendu: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Erreur: $e');
  }
  print('');
}

Future<void> testGetRestaurants(String baseUrl, String apiVersion) async {
  print('📡 Test 2: Récupération des restaurants');
  print('   Endpoint: $baseUrl$apiVersion/restaurants');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl$apiVersion/restaurants'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('   ✅ Endpoint accessible !');
      try {
        final data = json.decode(response.body);
        if (data is List) {
          print('   Nombre de restaurants: ${data.length}');
          if (data.isNotEmpty) {
            print('   Premier restaurant: ${data[0]['name'] ?? 'N/A'}');
          }
        } else {
          print('   Réponse: $data');
        }
      } catch (e) {
        print('   Erreur de parsing: $e');
      }
    } else if (response.statusCode == 404) {
      print('   ⚠️  Endpoint non trouvé (404)');
    } else {
      print('   ⚠️  Status: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Erreur: $e');
  }
  print('');
}
