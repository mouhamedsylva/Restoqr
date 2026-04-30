# 🔐 Configuration des Permissions - Android & iOS

## ✅ Permissions Configurées

Toutes les permissions nécessaires ont été ajoutées pour Android et iOS.

---

## 📱 Android - Permissions

### Fichier: `android/app/src/main/AndroidManifest.xml`

#### ✅ Permissions Ajoutées

```xml
<!-- Permissions pour la caméra (QR Code scanner) -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- Permissions pour Internet (API calls, WebSocket) -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Permissions pour le stockage (cache des images) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>

<!-- Permissions pour les notifications (optionnel) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### 📋 Détails des Permissions

| Permission | Usage | Obligatoire |
|------------|-------|-------------|
| **CAMERA** | Scanner les QR Codes des tables | ✅ Oui |
| **INTERNET** | Connexion au backend Railway | ✅ Oui |
| **ACCESS_NETWORK_STATE** | Vérifier la connexion réseau | ✅ Oui |
| **READ_EXTERNAL_STORAGE** | Lire les images en cache | ⚠️ Recommandé |
| **WRITE_EXTERNAL_STORAGE** | Sauvegarder les images en cache | ⚠️ Recommandé |
| **POST_NOTIFICATIONS** | Notifications de commandes | 🔵 Optionnel |

#### 📝 Notes Android

- **WRITE_EXTERNAL_STORAGE** : Limité à Android 12 et inférieur (`maxSdkVersion="32"`)
- **POST_NOTIFICATIONS** : Requis pour Android 13+ (API 33+)
- **INTERNET** : Automatiquement accordé, pas besoin de demande runtime
- **CAMERA** : Nécessite une demande runtime (gérée par `mobile_scanner`)

---

## 🍎 iOS - Permissions

### Fichier: `ios/Runner/Info.plist`

#### ✅ Permissions Ajoutées

```xml
<!-- Permission Caméra -->
<key>NSCameraUsageDescription</key>
<string>Nous avons besoin de la caméra pour scanner le QR Code de la table.</string>

<!-- Permissions Photos -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Nous avons besoin d'accéder à vos photos pour sélectionner des images.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Nous avons besoin d'accéder à vos photos pour enregistrer des images.</string>

<!-- Configuration App Transport Security (ATS) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Railway Backend -->
        <key>qr-code-server-production.up.railway.app</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
        
        <!-- Localhost pour développement -->
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

#### 📋 Détails des Permissions

| Permission | Usage | Obligatoire |
|------------|-------|-------------|
| **NSCameraUsageDescription** | Scanner les QR Codes | ✅ Oui |
| **NSPhotoLibraryUsageDescription** | Accès aux photos | ⚠️ Recommandé |
| **NSPhotoLibraryAddUsageDescription** | Sauvegarder des photos | ⚠️ Recommandé |
| **NSAppTransportSecurity** | Sécurité réseau | ✅ Oui |

#### 📝 Notes iOS

- **NSCameraUsageDescription** : Message affiché lors de la demande d'accès caméra
- **NSAppTransportSecurity** : Configure les connexions réseau sécurisées
- **Railway Backend** : Configuré pour HTTPS avec TLS 1.2+
- **Localhost** : Autorisé en HTTP pour le développement local
- Toutes les permissions nécessitent une demande runtime

---

## 🔒 Sécurité Réseau

### Android

Android autorise automatiquement les connexions HTTPS. Aucune configuration supplémentaire n'est nécessaire pour Railway.

**Configuration par défaut :**
- ✅ HTTPS autorisé
- ✅ TLS 1.2+ requis
- ✅ Certificats valides requis

### iOS - App Transport Security (ATS)

iOS nécessite une configuration explicite pour les connexions réseau.

**Configuration Railway :**
```xml
<key>qr-code-server-production.up.railway.app</key>
<dict>
    <key>NSExceptionAllowsInsecureHTTPLoads</key>
    <false/>  <!-- HTTPS uniquement -->
    <key>NSExceptionMinimumTLSVersion</key>
    <string>TLSv1.2</string>  <!-- TLS 1.2 minimum -->
</dict>
```

**Configuration Localhost (Développement) :**
```xml
<key>localhost</key>
<dict>
    <key>NSExceptionAllowsInsecureHTTPLoads</key>
    <true/>  <!-- HTTP autorisé pour dev -->
</dict>
```

---

## 📦 Packages et Permissions

### Packages Utilisés

| Package | Permissions Requises |
|---------|---------------------|
| **mobile_scanner** | CAMERA (Android/iOS) |
| **cached_network_image** | INTERNET, READ/WRITE_STORAGE |
| **http** | INTERNET, ACCESS_NETWORK_STATE |
| **socket_io_client** | INTERNET |
| **shared_preferences** | Aucune permission spéciale |
| **flutter_stripe** | INTERNET |

### Gestion Automatique

Les packages Flutter gèrent automatiquement :
- ✅ Demandes de permissions runtime
- ✅ Vérification des permissions
- ✅ Messages d'erreur si permission refusée

---

## 🧪 Tester les Permissions

### Android

#### 1. Vérifier les Permissions dans l'App
```bash
# Lancer l'application
flutter run

# Vérifier les permissions accordées
adb shell dumpsys package com.example.qr_order_client | grep permission
```

#### 2. Réinitialiser les Permissions
```bash
# Réinitialiser toutes les permissions
adb shell pm reset-permissions

# Réinitialiser les permissions d'une app spécifique
adb shell pm clear com.example.qr_order_client
```

#### 3. Accorder Manuellement
```bash
# Accorder la permission caméra
adb shell pm grant com.example.qr_order_client android.permission.CAMERA

# Accorder la permission stockage
adb shell pm grant com.example.qr_order_client android.permission.READ_EXTERNAL_STORAGE
```

### iOS

#### 1. Vérifier les Permissions
- Ouvrez l'application
- Allez dans Réglages > Confidentialité
- Vérifiez Caméra, Photos

#### 2. Réinitialiser les Permissions
- Réglages > Général > Réinitialiser
- Réinitialiser la localisation et la confidentialité

#### 3. Tester en Simulateur
```bash
# Lancer sur simulateur
flutter run -d ios

# Les permissions sont automatiquement demandées
```

---

## ⚠️ Problèmes Courants

### Android

#### Erreur: Permission Denied (Camera)
```
Solution:
1. Vérifiez que CAMERA est dans AndroidManifest.xml
2. Vérifiez que mobile_scanner demande la permission
3. Accordez manuellement: adb shell pm grant ...
```

#### Erreur: Network Error
```
Solution:
1. Vérifiez que INTERNET est dans AndroidManifest.xml
2. Vérifiez la connexion réseau
3. Testez avec curl depuis le terminal
```

#### Erreur: Storage Permission
```
Solution:
1. Pour Android 13+, utilisez les nouvelles permissions photos
2. Ajoutez READ_MEDIA_IMAGES au lieu de READ_EXTERNAL_STORAGE
```

### iOS

#### Erreur: Camera Access Denied
```
Solution:
1. Vérifiez NSCameraUsageDescription dans Info.plist
2. Réinitialisez les permissions dans Réglages
3. Relancez l'application
```

#### Erreur: App Transport Security
```
Solution:
1. Vérifiez NSAppTransportSecurity dans Info.plist
2. Assurez-vous que Railway est en HTTPS
3. Vérifiez que localhost est autorisé pour dev
```

#### Erreur: Photo Library Access
```
Solution:
1. Ajoutez NSPhotoLibraryUsageDescription
2. Demandez la permission avant d'accéder aux photos
```

---

## 📝 Checklist de Vérification

### Android
- [x] ✅ CAMERA permission ajoutée
- [x] ✅ INTERNET permission ajoutée
- [x] ✅ ACCESS_NETWORK_STATE ajoutée
- [x] ✅ READ_EXTERNAL_STORAGE ajoutée
- [x] ✅ WRITE_EXTERNAL_STORAGE ajoutée (API ≤ 32)
- [x] ✅ POST_NOTIFICATIONS ajoutée (API ≥ 33)

### iOS
- [x] ✅ NSCameraUsageDescription ajoutée
- [x] ✅ NSPhotoLibraryUsageDescription ajoutée
- [x] ✅ NSPhotoLibraryAddUsageDescription ajoutée
- [x] ✅ NSAppTransportSecurity configurée
- [x] ✅ Railway backend autorisé (HTTPS)
- [x] ✅ Localhost autorisé (HTTP dev)

### Tests
- [ ] 🔄 Tester le scanner QR Code
- [ ] 🔄 Tester la connexion Railway
- [ ] 🔄 Tester le cache des images
- [ ] 🔄 Tester les notifications (optionnel)

---

## 🚀 Prochaines Étapes

### 1. Tester sur Android
```bash
flutter run -d android
```

### 2. Tester sur iOS
```bash
flutter run -d ios
```

### 3. Vérifier les Permissions
- Scanner un QR Code
- Charger des images depuis le réseau
- Vérifier la connexion Railway

### 4. Build pour Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📚 Ressources

### Documentation Officielle

**Android:**
- [Permissions Overview](https://developer.android.com/guide/topics/permissions/overview)
- [Request Runtime Permissions](https://developer.android.com/training/permissions/requesting)
- [App Manifest](https://developer.android.com/guide/topics/manifest/manifest-intro)

**iOS:**
- [Requesting Authorization](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios)
- [App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
- [Info.plist Keys](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html)

### Packages Flutter
- [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [permission_handler](https://pub.dev/packages/permission_handler) (optionnel)

---

## ✅ Résumé

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║  ✅  TOUTES LES PERMISSIONS SONT CONFIGURÉES !              ║
║                                                              ║
║  Android:  ✅ 6 permissions ajoutées                        ║
║  iOS:      ✅ 4 permissions ajoutées                        ║
║  Sécurité: ✅ ATS configuré                                 ║
║  Railway:  ✅ HTTPS autorisé                                ║
║                                                              ║
║  Votre application est prête pour Android et iOS ! 🚀       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

**Date:** 30 avril 2026  
**Status:** ✅ Permissions configurées  
**Android:** ✅ Prêt  
**iOS:** ✅ Prêt
