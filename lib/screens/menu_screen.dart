import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/menu_service.dart';
import '../services/table_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'cart_screen.dart';
import 'order_status_screen.dart';
import 'product_detail_sheet.dart';

/// MenuScreen avec design moderne inspiré de "Bistro de l'Europe"
/// 
/// Caractéristiques :
/// - En-tête avec nom du restaurant et numéro de table
/// - Titre accrocheur "Quel délice vous fera plaisir ?"
/// - Barre de recherche
/// - Filtres de catégories (Tout, Végétarien, Vegan)
/// - Sections de menu avec compteur d'items
/// - Cartes de plats avec images rondes et badges
/// - Navigation bottom bar
class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String tableNumber;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, dynamic>? _restaurantInfo;
  List<Product> _allProducts = [];
  List<String> _categories = [];
  String _selectedFilter = 'Tout';
  String _searchQuery = '';
  String _displayTableNumber = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TableService _tableService = TableService();

  // Palette de couleurs moderne
  static const _primaryOrange = Color(0xFFD2691E);
  static const _lightOrange = Color(0xFFFFF5EE);
  static const _darkText = Color(0xFF2C2C2C);
  static const _lightText = Color(0xFF8E8E8E);
  static const _background = Color(0xFFFAFAFA);
  static const _white = Color(0xFFFFFFFF);
  static const _badgeYellow = Color(0xFFFFD700);
  static const _badgeGreen = Color(0xFF4CAF50);
  static const _shimmerBase = Color(0xFFE0E0E0);
  static const _shimmerHighlight = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _displayTableNumber = widget.tableNumber;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().setTableId(widget.tableNumber);
    });
    _loadData();
    _loadTableInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final menuService = MenuService();
      // Vider uniquement le cache du menu (pas les infos du restaurant)
      menuService.clearMenuCache();
      
      _restaurantInfo = await menuService.getRestaurantInfo(widget.restaurantId);
      _allProducts = await menuService.getMenu(widget.restaurantId);
      _categories = await menuService.getCategories(widget.restaurantId);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppFeedback.showError(context, 'Impossible de charger le menu.');
      }
    }
  }

  /// Charge les informations de la table depuis l'API
  Future<void> _loadTableInfo() async {
    final tableInfo = await _tableService.getTableInfo(widget.tableNumber);
    if (mounted && tableInfo != null) {
      setState(() {
        _displayTableNumber = _tableService.getTableNumber(tableInfo, widget.tableNumber);
      });
    } else if (mounted) {
      // Fallback si l'API échoue
      setState(() {
        if (widget.tableNumber.length > 8 && widget.tableNumber.contains('-')) {
          _displayTableNumber = widget.tableNumber.substring(0, 8).toUpperCase();
        } else {
          _displayTableNumber = widget.tableNumber;
        }
      });
    }
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _allProducts;

    // Filtre par catégorie
    if (_selectedFilter != 'Tout') {
      filtered = filtered.where((p) => p.category == _selectedFilter).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  Map<String, List<Product>> get _productsByCategory {
    final filtered = _filteredProducts;
    final Map<String, List<Product>> grouped = {};

    for (final product in filtered) {
      final category = product.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(product);
    }

    return grouped;
  }

  void _openCart() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => CartScreen(
          restaurantId: widget.restaurantId,
          tableNumber: widget.tableNumber,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppTheme.defaultCurve,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: AppTheme.mediumAnim,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _isLoading ? _buildSkeleton() : _buildContent(),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return _buildCartFAB(cart);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: _primaryOrange,
              backgroundColor: _white,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildMainTitle(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildCategoryFilters(),
                    const SizedBox(height: 24),
                    _buildMenuSections(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final restaurantName = _restaurantInfo?['name'] ?? 'Restaurant';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant,
              color: _white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Table $_displayTableNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _lightText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderButton() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final currentOrder = orderProvider.currentOrder;
        final hasActiveOrder = currentOrder != null &&
            orderProvider.currentStatus != OrderStatus.completed &&
            orderProvider.currentStatus != OrderStatus.cancelled;
        
        return GestureDetector(
          onTap: hasActiveOrder
              ? () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, animation, __) => OrderStatusScreen(
                        orderId: currentOrder!.id,
                        tableNumber: widget.tableNumber,
                        restaurantId: widget.restaurantId,
                      ),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: AppTheme.defaultCurve,
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: AppTheme.mediumAnim,
                    ),
                  );
                }
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _lightOrange,
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: _primaryOrange,
                    size: 22,
                  ),
                ),
                if (hasActiveOrder)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _darkText,
            height: 1.2,
          ),
          children: [
            TextSpan(text: 'Quel délice vous fera\n'),
            TextSpan(
              text: 'plaisir ?',
              style: TextStyle(color: _primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Rechercher un plat...',
            hintStyle: TextStyle(
              color: _lightText.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: _lightText,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _lightText, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    // Créer une liste avec "Tout" en premier, puis les vraies catégories
    final filters = ['Tout', ..._categories];
    
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == _selectedFilter;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primaryOrange : _white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? _primaryOrange : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? _white : _darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuSections() {
    final grouped = _productsByCategory;
    
    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: _lightText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun plat trouvé',
                style: TextStyle(
                  fontSize: 16,
                  color: _lightText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: grouped.entries.map((entry) {
        final category = entry.key;
        final products = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
            ),
            ...products.map((product) => _buildProductCard(product)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductCard(Product product) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final currentQty = cart.getQuantity(product.id);
        
        return GestureDetector(
          onTap: () => showProductDetail(
            context, 
            product, 
            initialQuantity: currentQty > 0 ? currentQty : 1,
          ),
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(45), // Cercle parfait (90/2)
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    cacheManager: CustomCacheManager.instance,
                    placeholder: (_, __) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(_primaryOrange),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: _primaryOrange,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                if (product.badgeLabel != null && product.badgeLabel!.isNotEmpty)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(product.badgeLabel!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.badgeLabel!,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (product.isChefSuggestion)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _badgeGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SANTÉ',
                        style: TextStyle(
                          color: _white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _lightText,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryOrange,
                        ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          final qty = cart.getQuantity(product.id);
                          
                          if (qty == 0) {
                            return GestureDetector(
                              onTap: () {
                                cart.addProduct(product);
                                AppFeedback.showSuccess(
                                  context,
                                  '${product.name} ajouté',
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _primaryOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryOrange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: _white,
                                  size: 20,
                                ),
                              ),
                            );
                          }
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lightOrange,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => cart.removeProduct(product.id),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: _white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: _primaryOrange,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _darkText,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => cart.addProduct(product),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: _primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: _white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Color _getBadgeColor(String badgeLabel) {
    final label = badgeLabel.toLowerCase();
    if (label.contains('populaire')) {
      return _badgeYellow;
    } else if (label.contains('chef') || label.contains('suggestion')) {
      return _primaryOrange;
    } else if (label.contains('nouveau')) {
      return Colors.green;
    } else if (label.contains('vegan') || label.contains('végétarien')) {
      return _badgeGreen;
    }
    return _primaryOrange;
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Accueil',
            isActive: true,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.receipt_long,
            label: 'Suivi commande',
            isActive: false,
            onTap: () {
              // Naviguer vers l'écran de suivi de commande
              final orderProvider = context.read<OrderProvider>();
              final currentOrder = orderProvider.currentOrder;
              
              if (currentOrder != null) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => OrderStatusScreen(
                      orderId: currentOrder.id,
                      tableNumber: widget.tableNumber,
                      restaurantId: widget.restaurantId,
                    ),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: AppTheme.defaultCurve,
                          ),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: AppTheme.mediumAnim,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Aucune commande en cours pour le moment',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _primaryOrange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? _primaryOrange : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? _white : _lightText,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? _primaryOrange : _lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFAB(CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _primaryOrange,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _primaryOrange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: _openCart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: _white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              '${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: _white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${cart.total.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 80,
              color: _shimmerBase,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _shimmerBase,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
