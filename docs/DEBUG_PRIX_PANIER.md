# 🐛 Debug - Problème de prix dans le panier

## Symptôme

Quand vous ajoutez un produit au panier, le prix semble augmenter de 1 au lieu de se multiplier correctement.

## Analyse du code

### ✅ Code correct identifié

1. **`CartItem.totalPrice`** (models/cart_item.dart) :
   ```dart
   double get totalPrice => product.price * quantity;
   ```
   ✅ Calcul correct : prix × quantité

2. **`CartProvider.subtotal`** (providers/cart_provider.dart) :
   ```dart
   double get subtotal =>
       _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
   ```
   ✅ Somme correcte de tous les totalPrice

3. **`Product.fromJson`** (models/product.dart) :
   ```dart
   final double parsedPrice = json['price'] != null
       ? double.tryParse(json['price'].toString()) ?? 0.0
       : 0.0;
   ```
   ✅ Parse correctement le prix

## Causes possibles

### 1. Prix dans la base de données = 1

**Vérification :**
```bash
cd qr-order-api
node test-prices.js
```

Si tous les prix sont à 1.00 €, c'est normal que ça augmente de 1 à chaque ajout !

**Solution :** Les prix dans votre BDD sont peut-être tous à 1 €. Vérifiez avec HeidiSQL.

### 2. Problème d'affichage vs calcul réel

Le calcul est peut-être correct mais l'affichage est trompeur.

**Test :**
1. Ajoutez un produit au panier
2. Regardez les logs dans le terminal Flutter (j'ai ajouté des logs de debug)
3. Vérifiez :
   - `Product Price: X.XX`
   - `Quantity: 1 → 2`
   - `Total Price: X.XX`

### 3. Confusion entre prix unitaire et total

Dans le panier, il y a deux prix affichés :
- **Prix unitaire** : `12.50 € / unité`
- **Prix total** : `25.00 €` (pour quantité 2)

Peut-être regardez-vous le mauvais prix ?

## Debug étape par étape

### Étape 1 : Vérifier les prix dans la BDD

```bash
cd qr-order-api
node test-prices.js
```

**Résultat attendu :**
```
📊 Échantillon de 10 plats:

Burger Classique
  Prix: 12.50
  Type: string
  
Pizza Margherita
  Prix: 11.00
  Type: string
```

**Si tous les prix sont à 1.00 :** C'est le problème !

### Étape 2 : Vérifier l'API

Ouvrez dans votre navigateur :
```
http://localhost:3000/api/v1/restaurants/b18ba2cd-f3a6-4334-8ac3-c5eac13e5adc
```

Cherchez un produit et vérifiez son prix dans le JSON.

### Étape 3 : Vérifier les logs Flutter

1. Lancez l'application :
   ```bash
   cd qr-order-client
   flutter run -d chrome
   ```

2. Ajoutez un produit au panier

3. Regardez les logs dans le terminal :
   ```
   🛒 CartProvider.addProduct()
      Product ID: dish-1111-2222-3333-444444444444
      Product Name: Burger Classique
      Product Price: 12.5
      New item added
      Initial quantity: 1
      Initial total: 12.5
      Cart subtotal: 12.5
      Cart total: 13.75
   ```

4. Ajoutez le même produit une 2ème fois :
   ```
   🛒 CartProvider.addProduct()
      Product ID: dish-1111-2222-3333-444444444444
      Product Name: Burger Classique
      Product Price: 12.5
      Quantity: 1 → 2
      Total Price: 25.0
      Cart subtotal: 25.0
      Cart total: 27.5
   ```

### Étape 4 : Interpréter les résultats

**Si `Product Price: 1.0` :**
→ Le problème vient de la BDD, les prix sont tous à 1 €

**Si `Product Price: 12.5` mais `Total Price: 13.5` :**
→ Problème de calcul (mais le code semble correct)

**Si `Product Price: 12.5` et `Total Price: 25.0` :**
→ Le calcul est correct ! Peut-être une confusion d'affichage ?

## Solutions selon le problème

### Si les prix sont à 1 € dans la BDD

Les plats créés par `seed-demo-data.js` ont peut-être des prix incorrects.

**Vérification SQL :**
```sql
SELECT name, price FROM menu_items WHERE id IN (
  'dish-1111-2222-3333-444444444444',
  'dish-2222-3333-4444-555555555555',
  'dish-3333-4444-5555-666666666666',
  'dish-4444-5555-6666-777777777777'
);
```

**Correction :**
```sql
UPDATE menu_items SET price = 12.50 WHERE id = 'dish-1111-2222-3333-444444444444';
UPDATE menu_items SET price = 11.00 WHERE id = 'dish-2222-3333-4444-555555555555';
UPDATE menu_items SET price = 9.50 WHERE id = 'dish-3333-4444-5555-666666666666';
UPDATE menu_items SET price = 13.00 WHERE id = 'dish-4444-5555-6666-777777777777';
```

### Si c'est un problème d'affichage

Vérifiez que vous regardez bien le **prix total** (en gros, à droite) et pas le **prix unitaire** (en petit, en haut).

## Exemple visuel

```
┌─────────────────────────────────────┐
│ 🍔 Burger Classique                 │
│ 12.50 € / unité  ← Prix unitaire    │
│                                     │
│ [-] 2 [+]              25.00 €  ← Total │
└─────────────────────────────────────┘
```

Quand vous passez de quantité 1 à 2 :
- Prix unitaire reste : **12.50 €**
- Prix total passe de : **12.50 €** → **25.00 €**

## Besoin d'aide ?

1. Exécutez `node test-prices.js` et partagez le résultat
2. Partagez les logs Flutter quand vous ajoutez au panier
3. Faites une capture d'écran du panier

Les logs de debug vous diront exactement ce qui se passe ! 🔍
