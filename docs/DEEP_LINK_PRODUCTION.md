# Deep Linking — Mise en production

Ce document explique comment configurer le deep linking pour que scanner un QR code avec l'appareil photo natif ouvre directement l'application cliente sur la bonne table.

## Contexte

Le QR code généré encode une URL de ce format :
```
https://qr-order-client.web.app/menu?restaurantId=<id>&tableId=<id>
```

En développement, `main.dart` bypasse le routing avec des IDs hardcodés. En production, il faut :
1. Configurer le deep linking Android et iOS
2. Déployer l'app web sur le domaine encodé dans les QR codes
3. Activer le routing dynamique dans `main.dart`

---

## Étape 1 — Choisir et fixer l'URL de production

Dans `qr-order-api/src/modules/tables/tables.service.ts`, remplacer :
```ts
const CLIENT_APP_URL = 'https://qr-order-client.web.app';
```
par ton domaine réel, par exemple :
```ts
const CLIENT_APP_URL = 'https://menu.monrestaurant.com';
```

> Tous les QR codes déjà générés devront être régénérés si tu changes ce domaine.

---

## Étape 2 — Android : Deep Link

### 2.1 Modifier `AndroidManifest.xml`

Dans `android/app/src/main/AndroidManifest.xml`, ajouter un `intent-filter` dans l'activité principale :

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...>

    <!-- Launcher existant -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Deep link HTTP/HTTPS -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data
            android:scheme="https"
            android:host="menu.monrestaurant.com"
            android:pathPrefix="/menu"/>
    </intent-filter>

</activity>
```

### 2.2 Fichier de vérification Android (App Links)

Pour que Android vérifie que tu possèdes le domaine, héberger ce fichier sur ton serveur :

**URL** : `https://menu.monrestaurant.com/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.tonapp.qr_order_client",
    "sha256_cert_fingerprints": ["AA:BB:CC:..."]
  }
}]
```

Pour obtenir le fingerprint SHA-256 de ton keystore :
```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

---

## Étape 3 — iOS : Universal Links

### 3.1 Modifier `Info.plist`

Dans `ios/Runner/Info.plist`, ajouter :

```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

### 3.2 Fichier de vérification iOS (Associated Domains)

Dans Xcode → Runner → Signing & Capabilities → ajouter **Associated Domains** :
```
applinks:menu.monrestaurant.com
```

Héberger ce fichier sur ton serveur :

**URL** : `https://menu.monrestaurant.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAMID.com.tonapp.qr_order_client",
      "paths": ["/menu*"]
    }]
  }
}
```

---

## Étape 4 — Flutter : Activer le routing dynamique

Dans `lib/main.dart`, remplacer le home hardcodé par un routing basé sur l'URL :

```dart
child: MaterialApp(
  title: 'QR Order - Client',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.theme,
  // Écran de chargement par défaut (avant de recevoir le deep link)
  home: const SplashScreen(),
  onGenerateRoute: (settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri != null && uri.path == '/menu') {
      final restaurantId = uri.queryParameters['restaurantId'];
      final tableId = uri.queryParameters['tableId'];
      if (restaurantId != null && tableId != null) {
        return MaterialPageRoute(
          builder: (_) => MenuScreen(
            restaurantId: restaurantId,
            tableNumber: tableId,
          ),
        );
      }
    }
    // Fallback
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  },
),
```

### Gérer le deep link à l'ouverture de l'app

Ajouter le package `app_links` dans `pubspec.yaml` :
```yaml
dependencies:
  app_links: ^6.0.0
```

Dans `main.dart` ou un widget racine, écouter les liens entrants :
```dart
import 'package:app_links/app_links.dart';

final appLinks = AppLinks();

// Lien qui a ouvert l'app (cold start)
final initialLink = await appLinks.getInitialLink();
if (initialLink != null) {
  _handleLink(initialLink);
}

// Liens reçus pendant que l'app tourne (warm start)
appLinks.uriLinkStream.listen((uri) {
  _handleLink(uri);
});

void _handleLink(Uri uri) {
  final restaurantId = uri.queryParameters['restaurantId'];
  final tableId = uri.queryParameters['tableId'];
  if (restaurantId != null && tableId != null) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          restaurantId: restaurantId,
          tableNumber: tableId,
        ),
      ),
    );
  }
}
```

---

## Étape 5 — Déploiement web (optionnel)

Si tu veux que le lien fonctionne aussi dans un navigateur (sans l'app installée) :

```bash
flutter build web --release
# Déployer le dossier build/web/ sur ton hébergeur
```

Configurer le serveur pour rediriger toutes les routes vers `index.html` (SPA routing).

---

## Checklist de mise en production

- [ ] Domaine de production fixé dans `tables.service.ts`
- [ ] QR codes régénérés avec le nouveau domaine
- [ ] `AndroidManifest.xml` mis à jour avec l'intent-filter
- [ ] `assetlinks.json` hébergé sur le domaine
- [ ] `Info.plist` mis à jour (iOS)
- [ ] `apple-app-site-association` hébergé sur le domaine
- [ ] `onGenerateRoute` activé dans `main.dart`
- [ ] Package `app_links` ajouté et configuré
- [ ] App publiée sur Play Store / App Store avec le bon `package_name` / `bundle_id`
- [ ] Test end-to-end : scanner un QR → app s'ouvre sur la bonne table
