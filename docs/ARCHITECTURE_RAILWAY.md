# Architecture Flutter ↔ Railway

## Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATION FLUTTER                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              lib/config/api_config.dart                   │  │
│  │                                                            │  │
│  │  useLocalServer = false  ← SWITCH LOCAL/PRODUCTION       │  │
│  │                                                            │  │
│  │  ┌──────────────────┐      ┌──────────────────┐         │  │
│  │  │   Production     │      │   Développement  │         │  │
│  │  │   (Railway)      │      │   (localhost)    │         │  │
│  │  └──────────────────┘      └──────────────────┘         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Services Flutter                       │  │
│  │  • AuthService                                            │  │
│  │  • RestaurantService                                      │  │
│  │  • OrderService                                           │  │
│  │  • PaymentService                                         │  │
│  │  • WebSocketService                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         RAILWAY                                  │
│                                                                   │
│  URL: https://qr-code-server-production.up.railway.app          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    NestJS Backend                         │  │
│  │                                                            │  │
│  │  Préfixe: /api/v1                                         │  │
│  │                                                            │  │
│  │  Endpoints:                                               │  │
│  │  • /api/v1/auth/*                                         │  │
│  │  • /api/v1/restaurants/*                                  │  │
│  │  • /api/v1/menus/*                                        │  │
│  │  • /api/v1/orders/*                                       │  │
│  │  • /api/v1/payments/*                                     │  │
│  │                                                            │  │
│  │  WebSocket: ws://qr-code-server-production.up.railway... │  │
│  │  Swagger: /api/docs                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  PostgreSQL Database                      │  │
│  │  (Railway Managed)                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICES EXTERNES                             │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │    Stripe    │  │  Cloudinary  │  │    Email     │         │
│  │  (Paiements) │  │   (Images)   │  │  (Nodemailer)│         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Flux de Données

### 1. Authentification

```
Flutter App
    │
    │ POST /api/v1/auth/login
    │ { email, password }
    ▼
Railway Backend
    │
    │ Vérification credentials
    │ Génération JWT
    ▼
Flutter App
    │
    │ Stockage token
    │ Utilisation dans headers
    └─► Authorization: Bearer <token>
```

### 2. Récupération des Données

```
Flutter App
    │
    │ GET /api/v1/restaurants
    │ Authorization: Bearer <token>
    ▼
Railway Backend
    │
    │ Vérification JWT
    │ Query PostgreSQL
    ▼
Flutter App
    │
    │ Affichage des données
    └─► UI mise à jour
```

### 3. Création de Commande

```
Flutter App
    │
    │ POST /api/v1/orders
    │ { restaurantId, items, tableId }
    ▼
Railway Backend
    │
    │ Validation
    │ Création en DB
    │ Notification WebSocket
    ▼
Flutter App (Client)     Flutter App (Restaurant)
    │                            │
    │ Confirmation              │ Notification temps réel
    └─► Affichage              └─► Nouvelle commande
```

### 4. Paiement Stripe

```
Flutter App
    │
    │ POST /api/v1/payments/create-payment-intent
    │ { amount, orderId }
    ▼
Railway Backend
    │
    │ Création Payment Intent
    │ Stripe API
    ▼
Flutter App
    │
    │ Affichage Stripe UI
    │ Paiement client
    ▼
Stripe
    │
    │ Webhook
    ▼
Railway Backend
    │
    │ POST /api/v1/payments/webhook
    │ Mise à jour statut commande
    ▼
Flutter App
    │
    │ WebSocket notification
    └─► Confirmation paiement
```

## Configuration des URLs

### Mode Production (Railway)

```dart
// lib/config/api_config.dart
static const bool useLocalServer = false;

// Résultat:
baseUrl = 'https://qr-code-server-production.up.railway.app/api/v1'
socketUrl = 'https://qr-code-server-production.up.railway.app'
```

### Mode Développement (Local)

```dart
// lib/config/api_config.dart
static const bool useLocalServer = true;

// Résultat (Web):
baseUrl = 'http://localhost:3000/api/v1'
socketUrl = 'http://localhost:3000'

// Résultat (Android Emulator):
baseUrl = 'http://10.0.2.2:3000/api/v1'
socketUrl = 'http://10.0.2.2:3000'
```

## Sécurité

### HTTPS
✅ Railway fournit automatiquement HTTPS
✅ Certificat SSL géré par Railway
✅ Redirection HTTP → HTTPS automatique

### CORS
✅ Backend configuré pour accepter :
- Requêtes sans origin (mobile apps)
- localhost et IPs locales
- Origins configurées via `APP_CORS_ORIGINS`

### JWT
✅ Tokens sécurisés
✅ Expiration configurable
✅ Refresh token disponible

### Stripe
✅ Clés publiques/privées séparées
✅ Webhooks sécurisés
✅ Validation des signatures

## Variables d'Environnement Railway

### Essentielles
```env
DATABASE_URL=postgresql://...
JWT_SECRET=votre_secret_jwt
JWT_EXPIRES_IN=7d
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
PORT=3000
```

### Optionnelles
```env
APP_CORS_ORIGINS=https://app.example.com,https://admin.example.com
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=...
EMAIL_PASSWORD=...
EMAIL_FROM=noreply@example.com
```

## Monitoring

### Logs Railway
```bash
# Voir les logs en temps réel
railway logs --follow

# Logs des dernières 24h
railway logs --since 24h
```

### Métriques
- CPU usage
- Memory usage
- Request count
- Response time
- Error rate

### Alertes
- Erreurs 5xx
- Temps de réponse élevé
- Utilisation mémoire excessive

## Déploiement

### Backend (Railway)
```bash
# Automatique via Git
git push origin main

# Railway détecte les changements
# Build et déploiement automatiques
```

### Frontend (Flutter)
```bash
# Web
flutter build web
# Déployer sur Netlify, Vercel, Firebase Hosting...

# Mobile
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Performance

### Cold Start
⚠️ Railway peut avoir un "cold start" (5-10s)
✅ Première requête peut être lente
✅ Requêtes suivantes rapides

### Optimisations
- ✅ Connexion persistante PostgreSQL
- ✅ Cache Redis (optionnel)
- ✅ CDN pour assets statiques
- ✅ Compression gzip

### Scaling
- ✅ Scaling vertical automatique
- ✅ Scaling horizontal (plan Pro)
- ✅ Load balancing (plan Pro)

---

**Architecture :** Flutter (Mobile/Web) ↔ Railway (Backend) ↔ PostgreSQL  
**Protocole :** HTTPS + WebSocket  
**Authentification :** JWT Bearer Token  
**Paiements :** Stripe  
**Status :** ✅ Opérationnel
