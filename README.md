# QR Order — Application Client Flutter

Application mobile et web permettant aux clients d'un restaurant de consulter le menu, passer commande et payer directement depuis leur smartphone via un QR Code.  
Construite avec **Flutter** et **Dart**.

---

## Table des matières

- [Présentation](#présentation)
- [Stack technique](#stack-technique)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Démarrage](#démarrage)
- [Structure du projet](#structure-du-projet)
- [Écrans & Fonctionnalités](#écrans--fonctionnalités)
- [Architecture](#architecture)
- [Paiement Stripe](#paiement-stripe)
- [Notifications temps réel](#notifications-temps-réel)
- [Charte graphique](#charte-graphique)
- [Plateformes supportées](#plateformes-supportées)
- [Ce qui reste à implémenter](#ce-qui-reste-à-implémenter)

---

## Présentation

QR Order Client est l'application destinée aux clients du restaurant. En scannant le QR Code présent sur leur table, ils accèdent directement au menu du restaurant, peuvent composer leur commande, ajouter des notes sur chaque article, payer via Stripe et suivre l'avancement de leur commande en temps réel.

**Fonctionnalités principales :**
- Splash screen élégant avec informations du restaurant
- Menu dynamique avec slideshow, catégories et recherche
- Fiche détaillée de chaque plat (options, allergènes, temps de préparation)
- Panier avec notes par article, modification et suppression
- Paiement sécurisé via Stripe (mobile uniquement)
- Suivi de commande en temps réel via WebSocket
- Feedback utilisateur (toasts, modales de confirmation)
- Design mobile-first, palette dorée et ivoire

---

## Stack technique

| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | SDK ^3.11 | Framework UI multiplateforme |
| Dart | ^3.11 | Langage |
| Provider | ^6.1.1 | Gestion d'état |
| HTTP | ^1.2.1 | Requêtes REST |
| Socket.IO Client | ^2.0.3 | WebSocket temps réel |
| Flutter Stripe | ^11.1.0 | Paiement (mobile uniquement) |
| Cached Network Image | ^3.3.0 | Images avec cache |
| Google Fonts | ^6.1.0 | Typographie (Lora, Cormorant Garamond) |
| Shimmer | ^3.0.0 | Skeleton loading |
| Lottie | ^2.7.0 | Animations |
| Mobile Scanner | ^5.0.0 | Scan QR Code |
| Shared Preferences | ^2.2.3 | Persistance locale |

---

## Prérequis

- **Flutter** SDK ≥ 3.11 ([installation](https://docs.flutter.dev/get-started/install))
- **Dart** SDK ≥ 3.11 (inclus avec Flutter)
- Le backend **qr-order-api** démarré et accessible
- Pour le paiement : un compte **Stripe** avec clés test

### Vérifier l'installation Flutter

```bash
flutter doctor
```

---

## Installation

```bash
# Depuis la racine du projet
cd qr-order-client

# Installer les dépendances
flutter pub get
```

---

## Configuration

### URL de l'API — `lib/config/api_config.dart`

Modifiez les URLs selon votre environnement :

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';       // Navigateur web
  } else if (kDebugMode) {
    return 'http://10.0.2.2:3000/api/v1';        // Émulateur Android
    // return 'http://192.168.1.X:3000/api/v1';  // Appareil physique (WiFi)
  } else {
    return 'http://10.0.2.2:3000/api/v1';        // Production
  }
}
```

> **Appareil physique :** remplacez `10.0.2.2` par l'adresse IP locale de votre machine (ex: `192.168.1.15`). L'appareil et la machine doivent être sur le même réseau WiFi.

### Clé Stripe — `lib/config/api_config.dart`

```dart
static const String stripePublishableKey = 'pk_test_...';
```

Remplacez par votre clé **publique** Stripe (`pk_test_...`).

### Restaurant et table — `lib/main.dart`

```dart
home: const SplashScreen(
  restaurantId: 'votre-restaurant-id',
  tableId: 'votre-table-id',
),
```

> En production, ces valeurs doivent provenir du scan du QR Code.

---

## Démarrage

```bash
# Lancer sur navigateur web (développement)
flutter run -d chrome

# Lancer sur émulateur Android
flutter run -d android

# Lancer sur simulateur iOS
flutter run -d ios

# Lister les appareils disponibles
flutter devices
```

---

## Structure du projet

```
lib/
├── config/
│   └── api_config.dart          # URLs API et clé Stripe
├── models/
│   ├── product.dart             # Modèle article du menu
│   ├── cart_item.dart           # Modèle article du panier (avec note)
│   └── order.dart               # Modèle commande et statuts
├── providers/
│   ├── cart_provider.dart       # État du panier + sync API
│   └── order_provider.dart      # État de la commande courante
├── screens/
│   ├── splash_screen.dart       # Écran de démarrage animé
│   ├── menu_screen.dart         # Menu principal avec slideshow
│   ├── product_detail_sheet.dart # Fiche détaillée d'un plat
│   ├── cart_screen.dart         # Panier et récapitulatif
│   ├── payment_screen.dart      # Paiement Stripe
│   ├── order_status_screen.dart # Suivi commande temps réel
│   └── qr_scanner_screen.dart   # Scanner QR Code (à implémenter)
├── services/
│   ├── menu_service.dart        # Chargement menu et restaurant
│   ├── order_service.dart       # Création et suivi commandes
│   ├── stripe_service.dart      # Intégration Stripe
│   ├── cart_api_service.dart    # Sync panier avec backend
│   ├── restaurant_service.dart  # Informations restaurant
│   └── notification_service.dart # Notifications statut commande
├── theme/
│   └── app_theme.dart           # Thème global, couleurs, typographie
├── utils/
│   └── app_feedback.dart        # Toasts et modales de confirmation
└── main.dart                    # Point d'entrée, providers, configuration
```

---

## Écrans & Fonctionnalités

### 🌟 Splash Screen
- Fond ivoire avec halos dorés animés
- Logo du restaurant avec effet flottant
- Nom du restaurant avec shimmer doré animé
- Séparateurs ornementaux (losange + points)
- Badge de numéro de table
- Adresse et téléphone du restaurant
- Barre de progression dorée
- Chargement des données restaurant depuis l'API
- Transition fluide vers le menu

### 🍽️ Menu
- **Slideshow hero** : 10 images en rotation (photos de restaurant + plats)
- **Nom et description** du restaurant en blanc sur dégradé sombre
- **Onglets de catégories** : filtrage par catégorie de menu
- **Recherche expansible** : l'icône loupe s'étend en barre de recherche pleine largeur
  - Filtrage en temps réel sur nom, description et badge
  - Message "Aucun résultat" avec bouton effacer
- **Section "Suggestions du Chef"** : carrousel horizontal des plats populaires
- **Liste des plats** : cartes avec image, nom, description, prix, badge
- **Bouton panier flottant** : total et nombre d'articles, animation d'entrée
- Skeleton loading pendant le chargement

### 📋 Fiche Produit (Bottom Sheet)
- Image hero pleine largeur
- Nom, catégorie, prix total
- Description complète
- Tags (badge, plat du jour, labels diététiques)
- Allergènes
- Temps de préparation
- Options supplémentaires (si disponibles)
- Sélecteur de quantité animé
- **Champ note** : toggle animé pour ajouter des instructions spéciales
  - Exemples : "sans oignons", "allergie aux noix"
  - Compteur 150 caractères
- Bouton "Ajouter au panier" avec total

### 🛒 Panier
- Liste des articles avec image, nom, prix unitaire
- **Note par article** : affichage compact, édition inline
- Contrôles de quantité (+ / -)
- **Suppression avec confirmation** : modale pour swipe et bouton poubelle
- **Vidage avec confirmation** : modale pour le bouton "VIDER"
- Récapitulatif : sous-total et total (sans TVA)
- Bouton "COMMANDER & PAYER"
- Synchronisation des suppressions avec l'API backend

### 💳 Paiement
- Récapitulatif de la commande avec articles et total
- **Sur mobile** : paiement sécurisé via Stripe PaymentSheet
  - Carte bancaire, Apple Pay, Google Pay
  - Thème personnalisé aux couleurs du restaurant
- **Sur web** : message informatif (paiement mobile uniquement)
- Animation de succès après paiement
- Redirection automatique vers le suivi de commande

### 📡 Suivi de Commande
- Référence de commande et heure
- **Carte de statut animée** avec emoji et description
- **Barre de progression** animée
- **Timeline** des étapes (En attente → En préparation → Prêt)
- Indicateur LIVE (WebSocket actif)
- Numéro de table et estimation du temps
- Notifications visuelles et haptiques à chaque changement de statut
- Actions selon le statut (Nouvelle commande, Contacter le restaurant)

---

## Architecture

L'application suit le pattern **Provider** pour la gestion d'état.

### Flux de données

```
API REST (qr-order-api)
        ↓
  MenuService / OrderService / StripeService
        ↓
  CartProvider / OrderProvider
        ↓
  Screens (UI)
        ↑
  WebSocket (Socket.IO) → NotificationService → OrderStatusScreen
```

### Providers enregistrés dans `main.dart`

| Provider | Type | Description |
|----------|------|-------------|
| `MenuService` | Provider | Chargement et cache du menu |
| `OrderService` | Provider | Création et suivi des commandes |
| `StripeService` | Provider | Paiement Stripe |
| `CartProvider` | ChangeNotifier | État du panier |
| `OrderProvider` | ChangeNotifier | État de la commande courante |

---

## Paiement Stripe

### Fonctionnement

```
1. Client appuie sur "COMMANDER & PAYER"
2. OrderProvider.submitOrder() → crée la commande en BDD
3. StripeService.createPaymentIntent() → POST /payments/intent
4. StripeService.presentPaymentSheet() → interface Stripe native
5. Paiement confirmé → CartProvider.clearCart()
6. Navigation vers OrderStatusScreen
```

### Compatibilité

| Plateforme | Paiement | Raison |
|------------|----------|--------|
| iOS | ✅ | flutter_stripe natif |
| Android | ✅ | flutter_stripe natif |
| Web | ❌ | Platform.isIOS non disponible sur web |

### Moyens de paiement acceptés

- Carte bancaire (Visa, Mastercard, Amex)
- Apple Pay (iOS)
- Google Pay (Android)

### Configuration

```dart
// lib/config/api_config.dart
static const String stripePublishableKey = 'pk_test_...'; // Clé PUBLIQUE

// lib/main.dart
await StripeService.initialize(); // Initialisation au démarrage (mobile uniquement)
```

---

## Notifications temps réel

Le suivi de commande utilise **Socket.IO** pour recevoir les mises à jour en temps réel.

### Événements écoutés

| Événement | Action |
|-----------|--------|
| `orderStatusUpdated` | Mise à jour du statut affiché |

### Notifications déclenchées

| Statut | Vibration | Message |
|--------|-----------|---------|
| `PREPARING` | Légère | "Commande acceptée — en préparation" |
| `READY` | Moyenne | "Commande prête !" |
| `CANCELLED` | Forte | "Commande annulée" |

---

## Charte graphique

### Palette principale (Menu & Panier)

| Couleur | Hex | Usage |
|---------|-----|-------|
| Ambre | `#C8901A` | Couleur principale, prix, boutons |
| Ambre clair | `#E8A83A` | Accents, dégradés |
| Ivoire | `#FFFDF7` | Fond principal |
| Crème | `#FDF6E8` | Surfaces secondaires |
| Brun foncé | `#1A1714` | Texte principal |
| Brun moyen | `#6B6350` | Texte secondaire |

### Palette Splash Screen

| Couleur | Hex | Usage |
|---------|-----|-------|
| Ivoire chaud | `#FFFDF7` | Fond |
| Or principal | `#C8901A` | Titre, icônes, bordures |
| Or clair | `#E8A83A` | Shimmer, accents |
| Or pâle | `#F5DFA0` | Halos, dégradés |
| Brun doré | `#3D2B0E` | Textes |

### Typographie

| Police | Usage |
|--------|-------|
| **Lora** | Corps de texte, descriptions, prix |
| **Playfair Display** | Titres principaux |
| **Cormorant Garamond** | Splash screen (élégance) |

---

## Plateformes supportées

| Plateforme | Support | Notes |
|------------|---------|-------|
| Android | ✅ | Complet avec Stripe |
| iOS | ✅ | Complet avec Stripe + Apple Pay |
| Web (Chrome) | ✅ | Sans paiement Stripe |
| Windows | ⚠️ | Non testé |
| macOS | ⚠️ | Non testé |

---

## Ce qui reste à implémenter

| Priorité | Fonctionnalité | Fichier |
|----------|---------------|---------|
| 🔴 Haute | Scanner QR Code | `qr_scanner_screen.dart` (vide) |
| 🔴 Haute | Routing dynamique depuis QR | `main.dart` (IDs hardcodés) |
| 🟡 Moyenne | Historique des commandes de session | Nouvel écran |
| 🟡 Moyenne | Paiement web (Stripe.js) | `stripe_service.dart` |
| 🟠 Basse | Notifications push système | Hors app |
| 🟠 Basse | Mode hors ligne / retry réseau | `menu_service.dart` |
| 🟠 Basse | Internationalisation | Nouveau système |

---

## Licence

Projet privé — Tous droits réservés.
