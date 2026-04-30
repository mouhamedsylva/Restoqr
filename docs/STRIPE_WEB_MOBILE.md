# Configuration Stripe - Mobile First

## Vue d'ensemble

L'application QR Order utilise Stripe pour les paiements, mais **uniquement sur les plateformes mobiles** (iOS et Android). Le web est supporté pour la navigation et la consultation du menu, mais pas pour les paiements.

## Pourquoi mobile uniquement ?

Le package `flutter_stripe` utilise des APIs natives (Platform.isIOS, Platform.isAndroid) qui ne sont pas disponibles sur le web. Stripe propose une solution web différente (Stripe.js) qui nécessiterait une implémentation séparée.

## Implémentation actuelle

### 1. Service Stripe (`lib/services/stripe_service.dart`)

```dart
static Future<void> initialize() async {
  if (_initialized) return;
  
  // Stripe n'est pas supporté sur le web, on initialise uniquement sur mobile
  if (!kIsWeb) {
    Stripe.publishableKey = ApiConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  
  _initialized = true;
}
```

### 2. Écran de paiement (`lib/screens/payment_screen.dart`)

- Détecte automatiquement si l'utilisateur est sur le web
- Affiche un message informatif : "Le paiement Stripe n'est disponible que sur l'application mobile"
- Empêche le traitement du paiement sur le web

### 3. Interface utilisateur adaptative

L'écran de paiement affiche :
- **Sur mobile** : "Paiement sécurisé par Stripe" avec icône de carte bancaire
- **Sur web** : "Paiement mobile uniquement" avec icône de téléphone

## Tester l'application

### Sur le web (développement)
```bash
flutter run -d chrome
```
✅ Navigation et menu fonctionnent
❌ Le paiement affiche un message d'erreur approprié

### Sur mobile (développement)
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```
✅ Toutes les fonctionnalités, y compris le paiement Stripe

## Solution future pour le web

Si vous souhaitez activer les paiements sur le web, vous devrez :

1. **Utiliser Stripe.js directement** via un package comme `stripe_js` ou `js` interop
2. **Créer une implémentation conditionnelle** :
   - `stripe_service_mobile.dart` pour iOS/Android (flutter_stripe)
   - `stripe_service_web.dart` pour le web (stripe.js)
3. **Utiliser un factory pattern** pour instancier le bon service selon la plateforme

### Exemple de structure

```dart
abstract class StripeService {
  factory StripeService() {
    if (kIsWeb) {
      return StripeServiceWeb();
    } else {
      return StripeServiceMobile();
    }
  }
  
  Future<void> initialize();
  Future<PaymentResult> processPayment(...);
}
```

## Notes importantes

- ⚠️ Ne jamais appeler `Stripe.publishableKey` ou `Stripe.instance` sur le web
- ⚠️ Toujours vérifier `kIsWeb` avant d'utiliser des APIs natives
- ✅ L'application fonctionne parfaitement sur mobile avec tous les moyens de paiement (carte, Apple Pay, Google Pay)
- ✅ L'application web permet de consulter le menu et préparer une commande

## Dépendances

```yaml
dependencies:
  flutter_stripe: ^11.1.0  # Mobile uniquement (iOS/Android)
```

Le package `flutter_stripe` est inclus dans les dépendances mais ne sera utilisé que sur mobile grâce aux conditions `if (!kIsWeb)`.
