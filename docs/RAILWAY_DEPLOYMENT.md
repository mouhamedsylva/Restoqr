# Configuration Backend Railway

## URL du Backend
Votre backend est déployé sur Railway à l'adresse :
```
https://qr-code-server-production.up.railway.app
```

## Configuration Flutter

Le fichier `lib/config/api_config.dart` a été configuré pour se connecter à votre backend Railway.

### Basculer entre Local et Production

Dans le fichier `lib/config/api_config.dart`, vous pouvez facilement basculer entre le serveur local et Railway :

```dart
// Mode de développement : true pour utiliser localhost, false pour Railway
static const bool useLocalServer = false;  // ← Changez cette valeur
```

- **`useLocalServer = false`** : Utilise le backend Railway (production)
- **`useLocalServer = true`** : Utilise votre serveur local (développement)

## URLs Configurées

### Production (Railway)
- **API Base URL** : `https://qr-code-server-production.up.railway.app/api/v1`
- **WebSocket URL** : `https://qr-code-server-production.up.railway.app`

### Développement (Local)
- **Web** : `http://localhost:3000/api/v1`
- **Android Emulator** : `http://10.0.2.2:3000/api/v1`
- **iOS Simulator** : `http://localhost:3000/api/v1`
- **Appareil Physique** : Utilisez l'IP de votre machine (ex: `http://192.168.1.15:3000/api/v1`)

## Vérification de la Connexion

Pour tester la connexion avec Railway, vous pouvez :

1. **Tester l'API directement** :
   ```bash
   curl https://qr-code-server-production.up.railway.app/api/v1/health
   ```

2. **Lancer l'application Flutter** :
   ```bash
   cd qr-order-client
   flutter run
   ```

3. **Vérifier les logs** :
   - Ouvrez la console de votre application
   - Tentez une connexion (login, récupération de données)
   - Vérifiez que les requêtes pointent vers Railway

## Points Importants

### CORS
Assurez-vous que votre backend Railway autorise les requêtes depuis votre application Flutter. Le backend doit avoir la configuration CORS appropriée.

### HTTPS
Railway fournit automatiquement HTTPS. Votre application Flutter utilisera donc des connexions sécurisées en production.

### Variables d'Environnement
Vérifiez que toutes les variables d'environnement nécessaires sont configurées sur Railway :
- `DATABASE_URL`
- `JWT_SECRET`
- `STRIPE_SECRET_KEY`
- `CLOUDINARY_*` (si utilisé)
- `EMAIL_*` (si utilisé)

## Déploiement de l'Application

### Web
Pour déployer la version web de votre application Flutter :
```bash
flutter build web
```

### Android
Pour créer un APK :
```bash
flutter build apk --release
```

### iOS
Pour créer une version iOS :
```bash
flutter build ios --release
```

## Troubleshooting

### Erreur de connexion
Si vous avez des erreurs de connexion :
1. Vérifiez que l'URL Railway est correcte
2. Testez l'URL dans un navigateur
3. Vérifiez les logs Railway pour voir si les requêtes arrivent
4. Assurez-vous que le backend est bien démarré sur Railway

### Erreur CORS
Si vous avez des erreurs CORS :
1. Vérifiez la configuration CORS dans votre backend
2. Assurez-vous que l'origine de votre application est autorisée
3. Vérifiez les headers dans les requêtes

### Timeout
Si les requêtes timeout :
1. Vérifiez que Railway n'est pas en mode "sleep"
2. Augmentez le timeout dans vos services Flutter si nécessaire
3. Vérifiez la performance de votre backend sur Railway

## Prochaines Étapes

1. ✅ Configuration de l'URL Railway dans Flutter
2. 🔄 Tester la connexion avec l'application
3. 🔄 Vérifier toutes les fonctionnalités (login, commandes, paiements)
4. 🔄 Déployer l'application Flutter (web/mobile)
5. 🔄 Configurer un domaine personnalisé sur Railway (optionnel)
