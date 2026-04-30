# 🚀 Configuration Railway - Guide Rapide

## ✅ Configuration Terminée !

Votre application Flutter est maintenant connectée au backend Railway.

## URL Backend
```
https://qr-code-server-production.up.railway.app
```

## Basculer entre Local et Production

Éditez `lib/config/api_config.dart` :

```dart
// false = Railway (production)
// true = localhost (développement)
static const bool useLocalServer = false;
```

## Tester l'Application

```bash
flutter run
```

## Vérifier la Connexion

L'application devrait maintenant :
- ✅ Se connecter au backend Railway
- ✅ Récupérer les données des restaurants
- ✅ Permettre la connexion/inscription
- ✅ Créer des commandes
- ✅ Traiter les paiements Stripe

## Endpoints Disponibles

- **API Base :** `https://qr-code-server-production.up.railway.app/api/v1`
- **WebSocket :** `https://qr-code-server-production.up.railway.app`
- **Documentation :** `https://qr-code-server-production.up.railway.app/api/docs`

## En Cas de Problème

### Erreur de connexion
1. Vérifiez que `useLocalServer = false`
2. Testez l'URL dans un navigateur
3. Vérifiez les logs Railway

### Erreur CORS
1. Ajoutez votre domaine dans `APP_CORS_ORIGINS` sur Railway
2. Le backend accepte déjà les requêtes mobiles sans origin

### Timeout
1. Vérifiez que Railway n'est pas en mode "sleep"
2. Attendez quelques secondes (cold start)

## Documentation Complète

- 📖 `docs/RAILWAY_DEPLOYMENT.md` - Guide détaillé
- 📖 `../docs/FLUTTER_RAILWAY_INTEGRATION.md` - Documentation complète
- 🧪 `test_railway_connection.dart` - Script de test

## Test Rapide

```bash
# Tester le backend directement
curl https://qr-code-server-production.up.railway.app/api/v1/restaurants
```

---

**Status :** ✅ Opérationnel  
**Date :** 30 avril 2026
