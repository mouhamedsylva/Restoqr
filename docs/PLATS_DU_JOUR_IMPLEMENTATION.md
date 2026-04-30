# 🍽️ Implémentation des Plats du Jour avec Badges

## Vue d'ensemble

L'application Flutter affiche maintenant **uniquement les plats du jour** (isDishOfDay = true) avec leurs **badges personnalisés** au lieu des catégories traditionnelles.

## Modifications apportées

### 1. Modèle Product (`lib/models/product.dart`)

Ajout de nouveaux champs :
```dart
final bool isDishOfDay;
final String? badgeLabel;
final String? badgeColor;
```

### 2. Service Menu (`lib/services/menu_service.dart`)

Nouvelles méthodes :
- `getDishesOfDay()` - Récupère uniquement les plats du jour
- `getBadges()` - Récupère la liste des badges uniques

### 3. Écran Menu (`lib/screens/menu_screen.dart`)

**Changements majeurs :**
- ✅ Affichage des **badges** au lieu des catégories
- ✅ Filtrage par **badgeLabel** au lieu de category
- ✅ Chargement uniquement des **plats du jour** (isDishOfDay = true)
- ✅ Affichage du badge sur chaque carte produit
- ✅ Support des couleurs personnalisées pour les badges
- ✅ Titre "Plats du Jour" au lieu de "Le Menu"

## Structure des badges

### Badges disponibles (exemples)

| Badge | Couleur | Code Hex | Usage |
|-------|---------|----------|-------|
| Nouveau | Vert | #10B981 | Nouveaux plats |
| Populaire | Orange | #F59E0B | Plats les plus commandés |
| Végétarien | Vert clair | #22C55E | Plats végétariens |
| Chef | Rouge | #EF4444 | Spécialités du chef |
| Spécialité | Violet | #8B5CF6 | Plats signature |
| Dessert | Rose | #EC4899 | Desserts |
| Frais | Cyan | #06B6D4 | Produits frais du jour |

## Base de données

### Script de seed

Pour ajouter des plats du jour avec badges :

```bash
cd qr-order-api
node seed-dishes-of-day.js
```

Ce script :
1. Met à jour les 4 plats existants avec des badges
2. Ajoute 3 nouveaux plats du jour
3. Configure isDishOfDay = true pour tous

### Structure SQL

```sql
-- Colonnes dans menu_items
isDishOfDay TINYINT(1) DEFAULT 0
badgeLabel VARCHAR(255) NULL
badgeColor VARCHAR(255) NULL
```

## Affichage dans l'application

### Onglets de filtrage

Au lieu des catégories (Entrées, Plats, Desserts), l'application affiche :
- **Tout** (tous les plats du jour)
- **Nouveau** (plats avec badge "Nouveau")
- **Populaire** (plats avec badge "Populaire")
- **Végétarien** (plats avec badge "Végétarien")
- etc.

### Cartes produits

Chaque carte affiche :
- Image du plat
- Badge coloré en bas à gauche (si badgeLabel existe)
- Badge "✦" en haut à gauche (si isPopular)
- Nom, description, prix
- Contrôles de quantité

## API Backend

### Endpoint utilisé

```
GET /api/v1/restaurants/{restaurantId}
```

**Réponse attendue :**
```json
{
  "id": "...",
  "name": "Restaurant Demo",
  "categories": [
    {
      "name": "Plats principaux",
      "items": [
        {
          "id": "...",
          "name": "Burger Classique",
          "price": 12.50,
          "isDishOfDay": true,
          "badgeLabel": "Nouveau",
          "badgeColor": "#10B981",
          ...
        }
      ]
    }
  ]
}
```

## Avantages de cette approche

✅ **Flexibilité** : Les badges peuvent être changés dynamiquement  
✅ **Personnalisation** : Couleurs personnalisées par badge  
✅ **Filtrage intuitif** : Les clients filtrent par type de plat (Nouveau, Végétarien, etc.)  
✅ **Mise en avant** : Les plats du jour sont mis en valeur  
✅ **Pas de données mock** : Tout vient de l'API  

## Tester l'application

1. **Démarrer le backend** :
   ```bash
   cd qr-order-api
   npm run start:dev
   ```

2. **Insérer les plats du jour** :
   ```bash
   node seed-dishes-of-day.js
   ```

3. **Lancer l'app Flutter** :
   ```bash
   cd qr-order-client
   flutter run -d chrome  # ou -d ios / -d android
   ```

4. **Résultat attendu** :
   - Onglets avec les badges (Tout, Nouveau, Populaire, etc.)
   - Liste des plats du jour uniquement
   - Badges colorés sur chaque carte
   - Filtrage fonctionnel par badge

## Prochaines étapes possibles

- 🔄 Ajouter un système de rotation automatique des plats du jour
- 📅 Planifier les plats du jour par date
- 🎨 Interface admin pour gérer les badges
- 📊 Analytics sur les plats du jour les plus populaires
- 🔔 Notifications push pour les nouveaux plats du jour

## Notes importantes

⚠️ **Données mock supprimées** : L'application ne contient plus de données en dur  
⚠️ **Dépendance API** : L'application nécessite que le backend soit démarré  
⚠️ **Plats du jour uniquement** : Seuls les plats avec `isDishOfDay = true` sont affichés  
