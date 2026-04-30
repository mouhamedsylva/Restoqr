import '../config/api_config.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isPopular;
  final List<String> tags;
  final bool isActive;
  final List<String> allergens;
  final int? preparationTime;
  final bool isDishOfDay;
  final String? badgeLabel;
  final String? badgeColor;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isPopular = false,
    this.tags = const [],
    this.isActive = true,
    this.allergens = const [],
    this.preparationTime,
    this.isDishOfDay = false,
    this.badgeLabel,
    this.badgeColor,
  });

  factory Product.fromJson(Map<String, dynamic> json, String categoryName) {
    // Parser le prix (souvent renvoyé comme string ou num en SQL/TypeORM)
    final double parsedPrice = json['price'] != null
        ? double.tryParse(json['price'].toString()) ?? 0.0
        : 0.0;

    // Constuire les tags à partir des bagdes/allergens
    List<String> parsedTags = [];
    if (json['badgeLabel'] != null && json['badgeLabel'].toString().isNotEmpty) {
      parsedTags.add(json['badgeLabel']);
    }
    if (json['isDishOfDay'] == true) {
      parsedTags.add('Plat du jour');
    }
    if (json['dietaryLabels'] != null && json['dietaryLabels'] is List) {
      parsedTags.addAll(List<String>.from(json['dietaryLabels']));
    }

    // Parser les allergènes
    List<String> parsedAllergens = [];
    if (json['allergens'] != null && json['allergens'] is List) {
      parsedAllergens = List<String>.from(json['allergens']);
    }

    // Parser l'imageUrl avec fallback
    String imageUrl = json['imageUrl'] ?? '';
    
    // Si c'est un chemin relatif, construire l'URL complète
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
      imageUrl = '$baseUrl$imageUrl';
    }
    
    // Si vide → image Unsplash par nom de plat, puis par catégorie
    if (imageUrl.isEmpty) {
      imageUrl = _fallbackImage(json['name']?.toString() ?? '', categoryName);
    }

    return Product(
      id: json['id'],
      name: json['name'] ?? 'Inconnu',
      description: json['description'] ?? '',
      price: parsedPrice,
      imageUrl: imageUrl,
      category: categoryName,
      isPopular: (json['ordersCount'] ?? 0) > 10 || json['isDishOfDay'] == true || json['isDishOfDay'] == 1,
      tags: parsedTags,
      isActive: json['isActive'] ?? true,
      allergens: parsedAllergens,
      preparationTime: json['preparationTime'] ?? json['prepTime'],
      isDishOfDay: json['isDishOfDay'] == true || json['isDishOfDay'] == 1,
      badgeLabel: json['badgeLabel'],
      badgeColor: json['badgeColor'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Fallback images Unsplash par nom de plat ──────────────────────────────────
const _kImageByName = <String, String>{
  'salade niçoise':          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
  'mousse au chocolat':      'https://images.unsplash.com/photo-1541783245831-57d6fb0926d3?w=400&q=80',
  'steak-frites':            'https://images.unsplash.com/photo-1558030006-450675393462?w=400&q=80',
  'escargots de bourgogne':  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
  'pizza reine':             'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
  'sole meunière':           'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400&q=80',
  'tartare de saumon':       'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&q=80',
  'tarte aux pommes':        'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=400&q=80',
  'cordon bleu':             'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400&q=80',
  'velouté de champignons':  'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&q=80',
  'moules marinières':       'https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=400&q=80',
  'poulet rôti':             'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=400&q=80',
  'entrecôte grillée':       'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&q=80',
  'tagliatelles carbonara':  'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400&q=80',
  "soupe à l'oignon":        'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&q=80',
  'carpaccio de bœuf':       'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&q=80',
  'saumon grillé':           'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&q=80',
  'pizza 4 fromages':        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
  'cabillaud sauce citron':  'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400&q=80',
  'bœuf bourguignon':        'https://images.unsplash.com/photo-1534939561126-855b8675edd7?w=400&q=80',
  'tiramisu':                'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400&q=80',
  'salade de fruits':        'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400&q=80',
  'gaufres':                 'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400&q=80',
  'crème brûlée':            'https://images.unsplash.com/photo-1470124182917-cc6e71b22ecc?w=400&q=80',
  'crêpes':                  'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&q=80',
  'lasagnes':                'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=400&q=80',
  'pizza margherita':        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&q=80',
  'spaghetti bolognaise':    'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400&q=80',
  'risotto aux champignons': 'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400&q=80',
  'salade grecque':          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&q=80',
  'salade césar':            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
  'sorbet citron':           'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=400&q=80',
  'glace vanille':           'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400&q=80',
};

String _fallbackImage(String name, String category) {
  final key = name.toLowerCase().trim();
  if (_kImageByName.containsKey(key)) return _kImageByName[key]!;
  switch (category.toLowerCase()) {
    case 'entrées':  return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80';
    case 'plats':    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80';
    case 'desserts': return 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400&q=80';
    case 'boissons': return 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&q=80';
    default:         return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80';
  }
}
