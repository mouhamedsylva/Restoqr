# 🧪 Test des Formats d'URL - Flutter

## 📋 Formats d'URL à Tester

### ✅ Format Correct (Devrait Fonctionner)

```
https://deluxe-florentine-f598b3.netlify.app/#/menu?restaurantId=abc123&tableId=table5
```

**Décomposition:**
- Base: `https://deluxe-florentine-f598b3.netlify.app`
- Hash: `#`
- Route: `/menu`
- Query: `?restaurantId=abc123&tableId=table5`

**Ce que Flutter devrait extraire:**
```dart
{
  'restaurantId': 'abc123',
  'tableId': 'table5'
}
```

---

### ❌ Formats Incorrects (Ne Devraient PAS Fonctionner)

#### 1. Path Parameters
```
https://deluxe-florentine-f598b3.netlify.app/#/menu/abc123/table5
```
❌ Pas de query parameters

#### 2. Sans Hash
```
https://deluxe-florentine-f598b3.netlify.app/menu?restaurantId=abc123&tableId=table5
```
❌ Pas de hash (#)

#### 3. Query avant Hash
```
https://deluxe-florentine-f598b3.netlify.app?restaurantId=abc123&tableId=table5#/menu
```
❌ Query parameters au mauvais endroit

---

## 🔍 Comment Tester

### Méthode 1: Console du Navigateur (Recommandé)

1. Ouvrir l'app Flutter dans le navigateur
2. Ouvrir la console (F12)
3. Chercher les logs qui commencent par 🔍, ✅ ou ❌
4. Vérifier les valeurs extraites

**Logs attendus si ça fonctionne:**
```
🔍 URL complète: https://deluxe-florentine-f598b3.netlify.app/#/menu?restaurantId=abc123&tableId=table5
🔍 URI fragment: /menu?restaurantId=abc123&tableId=table5
✓ Fragment trouvé: /menu?restaurantId=abc123&tableId=table5
🔍 Fragment parts: [/menu, restaurantId=abc123&tableId=table5]
🔍 Query string: restaurantId=abc123&tableId=table5
🔍 Params extraits: {restaurantId: abc123, tableId: table5}
✅ Paramètres trouvés!
   - restaurantId: abc123
   - tableId: table5
```

**Logs si ça ne fonctionne pas:**
```
🔍 URL complète: https://deluxe-florentine-f598b3.netlify.app/#/menu/abc123/table5
🔍 URI fragment: /menu/abc123/table5
✓ Fragment trouvé: /menu/abc123/table5
🔍 Fragment parts: [/menu/abc123/table5]
❌ Pas de query string dans le fragment
❌ Paramètres non trouvés dans query parameters
❌ Aucun paramètre trouvé - Retour map vide
```

---

### Méthode 2: Tester Manuellement

1. **Générer un QR code depuis l'app owner**
2. **Scanner avec une app de lecture QR** (pas le navigateur)
3. **Copier l'URL affichée**
4. **Vérifier le format**

---

### Méthode 3: Tester avec des URLs Directes

Ouvrir ces URLs directement dans le navigateur:

#### Test 1: Format Correct
```
https://deluxe-florentine-f598b3.netlify.app/#/menu?restaurantId=test123&tableId=table1
```
**Résultat attendu:** Menu s'affiche

#### Test 2: Sans Paramètres
```
https://deluxe-florentine-f598b3.netlify.app/#/menu
```
**Résultat attendu:** Erreur "QR Code invalide"

#### Test 3: Avec un seul Paramètre
```
https://deluxe-florentine-f598b3.netlify.app/#/menu?restaurantId=test123
```
**Résultat attendu:** Erreur "QR Code invalide"

---

## 🐛 Debugging

### Vérifier l'URL Actuelle

Ouvrir la console et taper:
```javascript
console.log('URL:', window.location.href);
console.log('Hash:', window.location.hash);
console.log('Fragment:', window.location.hash.substring(1));
```

---

### Vérifier les Paramètres Extraits

Dans le code Flutter, les logs de debug afficheront:
```
🔍 URL complète: [l'URL complète]
🔍 URI fragment: [le fragment après #]
🔍 Params extraits: [les paramètres]
```

---

## 📊 Tableau de Compatibilité

| Format d'URL | Fragment | Query String | Fonctionne? |
|--------------|----------|--------------|-------------|
| `/#/menu?restaurantId=x&tableId=y` | `/menu?restaurantId=x&tableId=y` | `restaurantId=x&tableId=y` | ✅ OUI |
| `/#/menu/x/y` | `/menu/x/y` | (vide) | ❌ NON |
| `/menu?restaurantId=x&tableId=y` | (vide) | `restaurantId=x&tableId=y` | ⚠️ Fallback |
| `?restaurantId=x&tableId=y#/menu` | `/menu` | (vide) | ❌ NON |

---

## 🔧 Si les Paramètres Ne Sont Pas Extraits

### Vérification 1: Format de l'URL

L'URL doit être:
```
https://[domaine]/#/menu?restaurantId=[id]&tableId=[id]
```

**Vérifier:**
- ✅ Présence du `#`
- ✅ `/menu` après le `#`
- ✅ `?` après `/menu`
- ✅ `restaurantId=` et `tableId=` présents

---

### Vérification 2: Logs de Debug

Chercher dans la console:
```
❌ Fragment vide
❌ Pas de query string dans le fragment
❌ Paramètres manquants dans le fragment
```

Ces messages indiquent où le problème se situe.

---

### Vérification 3: QR Code Généré

1. Scanner le QR code avec une app de lecture
2. Copier l'URL
3. Vérifier qu'elle correspond au format correct

---

## 🎯 Résolution des Problèmes

### Problème: "Fragment vide"

**Cause:** L'URL n'a pas de hash (#)

**Solution:** Vérifier que l'app owner génère l'URL avec `/#/menu`

---

### Problème: "Pas de query string dans le fragment"

**Cause:** Le fragment ne contient pas de `?`

**Exemple:** `/#/menu/abc123/table5` au lieu de `/#/menu?restaurantId=abc123&tableId=table5`

**Solution:** Corriger la génération d'URL dans l'app owner

---

### Problème: "Paramètres manquants dans le fragment"

**Cause:** Les paramètres `restaurantId` ou `tableId` ne sont pas présents

**Exemple:** `/#/menu?id=abc123` (manque `restaurantId` et `tableId`)

**Solution:** Vérifier les noms des paramètres dans l'app owner

---

## 📝 Checklist de Vérification

- [ ] L'URL contient `#`
- [ ] L'URL contient `/menu` après le `#`
- [ ] L'URL contient `?` après `/menu`
- [ ] L'URL contient `restaurantId=`
- [ ] L'URL contient `tableId=`
- [ ] Les logs de debug s'affichent dans la console
- [ ] Les paramètres sont extraits correctement
- [ ] Le menu s'affiche

---

## 🚀 Prochaines Étapes

1. **Rebuilder le Flutter** (si modifications)
   ```bash
   cd qr-order-client
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Redéployer sur Netlify**
   - Uploader le dossier `build/web`

3. **Tester avec un QR code réel**
   - Générer depuis l'app owner
   - Scanner avec mobile
   - Vérifier les logs

---

**Date:** 30 avril 2026  
**Version:** Avec logs de debug améliorés
