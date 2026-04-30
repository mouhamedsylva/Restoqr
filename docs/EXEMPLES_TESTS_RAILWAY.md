# Exemples de Tests avec Railway

## Tests de Connexion

### 1. Test Simple avec curl

```bash
# Test de base - Liste des restaurants
curl https://qr-code-server-production.up.railway.app/api/v1/restaurants

# Test avec formatage JSON (si jq installé)
curl https://qr-code-server-production.up.railway.app/api/v1/restaurants | jq

# Test de la documentation Swagger
curl https://qr-code-server-production.up.railway.app/api/docs
```

### 2. Test d'Authentification

```bash
# Inscription
curl -X POST https://qr-code-server-production.up.railway.app/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "firstName": "Test",
    "lastName": "User",
    "role": "customer"
  }'

# Connexion
curl -X POST https://qr-code-server-production.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'

# Réponse attendue:
# {
#   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": { ... }
# }
```

### 3. Test avec Token JWT

```bash
# Remplacez YOUR_TOKEN par le token reçu lors de la connexion
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Récupérer le profil utilisateur
curl https://qr-code-server-production.up.railway.app/api/v1/users/profile \
  -H "Authorization: Bearer $TOKEN"

# Récupérer les commandes
curl https://qr-code-server-production.up.railway.app/api/v1/orders \
  -H "Authorization: Bearer $TOKEN"
```

## Tests dans Flutter

### 1. Test de Connexion Simple

Créez un fichier `test_connection.dart` :

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';

Future<void> testConnection() async {
  print('🔍 Test de connexion avec Railway...');
  print('URL: ${ApiConfig.baseUrl}');
  
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/restaurants'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    print('✅ Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Données reçues: ${data.length} restaurants');
      print('✅ Connexion Railway réussie !');
    } else {
      print('⚠️  Status inattendu: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

void main() {
  testConnection();
}
```

Exécutez :
```bash
dart run test_connection.dart
```

### 2. Test d'Authentification

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';

Future<String?> testLogin(String email, String password) async {
  print('🔐 Test de connexion...');
  
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final token = data['access_token'];
      print('✅ Connexion réussie !');
      print('Token: ${token.substring(0, 20)}...');
      return token;
    } else {
      print('❌ Erreur: ${response.statusCode}');
      print('Body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Exception: $e');
    return null;
  }
}

void main() async {
  final token = await testLogin('test@example.com', 'Test123!');
  if (token != null) {
    print('✅ Token obtenu avec succès');
  }
}
```

### 3. Test Complet avec Service

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';

class ApiTestService {
  String? _token;
  
  // Test 1: Connexion
  Future<bool> testLogin() async {
    print('\n📝 Test 1: Connexion');
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'test@example.com',
          'password': 'Test123!',
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        print('✅ Connexion réussie');
        return true;
      } else {
        print('❌ Échec: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
  
  // Test 2: Récupération des restaurants
  Future<bool> testGetRestaurants() async {
    print('\n📝 Test 2: Récupération des restaurants');
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurants'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data.length} restaurants récupérés');
        return true;
      } else {
        print('❌ Échec: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
  
  // Test 3: Récupération du profil (avec token)
  Future<bool> testGetProfile() async {
    print('\n📝 Test 3: Récupération du profil');
    
    if (_token == null) {
      print('❌ Pas de token disponible');
      return false;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Profil récupéré: ${data['email']}');
        return true;
      } else {
        print('❌ Échec: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
  
  // Test 4: Création d'une commande
  Future<bool> testCreateOrder(String restaurantId) async {
    print('\n📝 Test 4: Création d\'une commande');
    
    if (_token == null) {
      print('❌ Pas de token disponible');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'restaurantId': restaurantId,
          'items': [
            {
              'menuItemId': 'test-item-id',
              'quantity': 2,
              'price': 15.99,
            }
          ],
          'tableId': 'test-table-id',
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Commande créée: ${data['id']}');
        return true;
      } else {
        print('❌ Échec: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
  
  // Exécuter tous les tests
  Future<void> runAllTests() async {
    print('🚀 Démarrage des tests Railway\n');
    print('URL: ${ApiConfig.baseUrl}\n');
    
    int passed = 0;
    int total = 0;
    
    // Test 1
    total++;
    if (await testLogin()) passed++;
    
    // Test 2
    total++;
    if (await testGetRestaurants()) passed++;
    
    // Test 3
    total++;
    if (await testGetProfile()) passed++;
    
    // Résumé
    print('\n' + '=' * 50);
    print('📊 Résumé des tests');
    print('=' * 50);
    print('✅ Tests réussis: $passed/$total');
    print('❌ Tests échoués: ${total - passed}/$total');
    
    if (passed == total) {
      print('\n🎉 Tous les tests sont passés !');
      print('✅ Votre application Flutter est prête à utiliser Railway');
    } else {
      print('\n⚠️  Certains tests ont échoué');
      print('Vérifiez la configuration et les logs Railway');
    }
  }
}

void main() async {
  final testService = ApiTestService();
  await testService.runAllTests();
}
```

Exécutez :
```bash
dart run test_api_railway.dart
```

## Tests avec Postman

### Collection Postman

Importez cette collection dans Postman :

```json
{
  "info": {
    "name": "QR Order - Railway",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "https://qr-code-server-production.up.railway.app/api/v1"
    },
    {
      "key": "token",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"Test123!\"\n}"
            },
            "url": {
              "raw": "{{baseUrl}}/auth/login",
              "host": ["{{baseUrl}}"],
              "path": ["auth", "login"]
            }
          }
        }
      ]
    },
    {
      "name": "Restaurants",
      "item": [
        {
          "name": "Get All Restaurants",
          "request": {
            "method": "GET",
            "header": [],
            "url": {
              "raw": "{{baseUrl}}/restaurants",
              "host": ["{{baseUrl}}"],
              "path": ["restaurants"]
            }
          }
        }
      ]
    }
  ]
}
```

## Tests de Performance

### Test de Charge Simple

```bash
# Installer Apache Bench (si pas déjà installé)
# Windows: Inclus avec Apache
# Mac: brew install httpd
# Linux: sudo apt-get install apache2-utils

# Test avec 100 requêtes, 10 concurrentes
ab -n 100 -c 10 https://qr-code-server-production.up.railway.app/api/v1/restaurants

# Test avec authentification
ab -n 100 -c 10 -H "Authorization: Bearer YOUR_TOKEN" \
  https://qr-code-server-production.up.railway.app/api/v1/orders
```

### Résultats Attendus

```
Concurrency Level:      10
Time taken for tests:   2.345 seconds
Complete requests:      100
Failed requests:        0
Total transferred:      45678 bytes
Requests per second:    42.64 [#/sec] (mean)
Time per request:       234.5 [ms] (mean)
```

## Monitoring en Temps Réel

### Logs Railway

```bash
# Installer Railway CLI
npm install -g @railway/cli

# Se connecter
railway login

# Voir les logs
railway logs --follow

# Filtrer les erreurs
railway logs --follow | grep ERROR
```

### Métriques

Accédez au dashboard Railway :
```
https://railway.app/project/YOUR_PROJECT_ID
```

Vérifiez :
- ✅ CPU usage < 80%
- ✅ Memory usage < 80%
- ✅ Response time < 500ms
- ✅ Error rate < 1%

## Checklist de Tests

### Tests de Base
- [ ] Backend accessible via HTTPS
- [ ] Endpoint `/api/v1/restaurants` fonctionne
- [ ] Documentation Swagger accessible
- [ ] CORS configuré correctement

### Tests d'Authentification
- [ ] Inscription fonctionne
- [ ] Connexion fonctionne
- [ ] Token JWT valide
- [ ] Refresh token fonctionne

### Tests de Données
- [ ] Récupération des restaurants
- [ ] Récupération des menus
- [ ] Récupération des plats
- [ ] Filtres et recherche fonctionnent

### Tests de Commandes
- [ ] Création de commande
- [ ] Mise à jour du statut
- [ ] Récupération de l'historique
- [ ] Notifications WebSocket

### Tests de Paiements
- [ ] Création Payment Intent
- [ ] Webhook Stripe fonctionne
- [ ] Mise à jour du statut de paiement
- [ ] Gestion des erreurs

### Tests de Performance
- [ ] Temps de réponse < 500ms
- [ ] Cold start < 10s
- [ ] Pas de memory leaks
- [ ] Gestion de la charge

## Dépannage

### Erreur 404
```
❌ Cannot GET /api/v1/endpoint
```
**Solution :** Vérifiez l'URL et le préfixe `/api/v1`

### Erreur 401
```
❌ Unauthorized
```
**Solution :** Vérifiez le token JWT dans le header `Authorization: Bearer <token>`

### Erreur 500
```
❌ Internal Server Error
```
**Solution :** Vérifiez les logs Railway pour voir l'erreur exacte

### Timeout
```
❌ TimeoutException after 10 seconds
```
**Solution :** 
1. Vérifiez que Railway n'est pas en mode "sleep"
2. Attendez le cold start (5-10s)
3. Augmentez le timeout

---

**Documentation :** https://qr-code-server-production.up.railway.app/api/docs  
**Status :** ✅ Prêt pour les tests
