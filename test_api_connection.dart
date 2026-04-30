import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script de test pour vérifier la connexion à l'API
/// Usage: dart run test_api_connection.dart
void main() async {
  print('🧪 Test de connexion à qr-order-api\n');

  const baseUrl = 'http://localhost:3000/api/v1';
  const restaurantId = 'ea5b4f8c-58e0-46a2-982a-78c7321c0d22';

  // Test 1: Vérifier que l'API répond
  print('📡 Test 1: Connexion à l\'API...');
  try {
    final response = await http.get(Uri.parse('$baseUrl/restaurants/$restaurantId'));
    
    if (response.statusCode == 200) {
      print('✅ API accessible (Status: ${response.statusCode})');
      
      final data = jsonDecode(response.body);
      print('   Restaurant: ${data['name']}');
      print('   ID: ${data['id']}');
      print('   Devise: ${data['currency'] ?? 'EUR'}');
      print('   Langue: ${data['language'] ?? 'fr'}');
      
      // Test 2: Vérifier les catégories
      print('\n📋 Test 2: Chargement du menu...');
      final categories = data['categories'] as List<dynamic>? ?? [];
      print('✅ ${categories.length} catégories trouvées');
      
      int totalItems = 0;
      for (var category in categories) {
        final items = category['items'] as List<dynamic>? ?? [];
        totalItems += items.length;
        print('   - ${category['name']}: ${items.length} items');
      }
      print('   Total: $totalItems produits');
      
      // Test 3: Vérifier les paramètres
      print('\n⚙️  Test 3: Paramètres du restaurant...');
      print('   Couleur primaire: ${data['primaryColor'] ?? 'Non définie'}');
      print('   Couleur secondaire: ${data['secondaryColor'] ?? 'Non définie'}');
      print('   Taxe incluse: ${data['isTaxIncluded'] ?? false}');
      print('   Taux de taxe: ${data['taxRate'] ?? 0.10}');
      
      print('\n✅ Tous les tests sont passés! Le client peut se connecter à l\'API.');
      
    } else {
      print('❌ Erreur: Status ${response.statusCode}');
      print('   Réponse: ${response.body}');
    }
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    print('\n💡 Vérifiez que:');
    print('   1. L\'API est démarrée (npm run start:dev dans qr-order-api)');
    print('   2. L\'API écoute sur le port 3000');
    print('   3. L\'ID du restaurant est correct');
  }
}
