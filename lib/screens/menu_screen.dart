import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart'; // Pour CustomCacheManager
import '../models/order.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/menu_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'cart_screen.dart';
import 'order_status_screen.dart';
import 'product_detail_sheet.dart';

// ─── Design tokens (blanc + ambre/or) ─────────────────────────────────────────
// À intégrer dans AppTheme si souhaité :
//   background    : #FFFDF7
//   surface       : #FFFFFF
//   surfaceVariant: #FDF6E8
//   primary       : #C8901A   (ambre foncé)
//   primaryLight  : #E8A83A   (ambre clair)
//   primaryGlow   : #C8901A1A (ambre 10 %)
//   secondary     : #D4A017
//   textPrimary   : #1A1714
//   textSecondary : #6B6350
//   textLight     : #A89F85
//   divider       : #EDE8D8
//   shimmerBase   : #F5F0E0
//   shimmerHighlight: #FFFDF7
// ──────────────────────────────────────────────────────────────────────────────

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

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  // ─── Slideshow hero ───────────────────────────────────────────────────────
  static const _heroImages = [
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=900&q=80',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900&q=80', // burger
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=900&q=80', // pizza
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900&q=80',
    'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=900&q=80', // carbonara
    'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=900&q=80',
    'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=900&q=80', // salade césar
    'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=900&q=80',
    'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=900&q=80', // tiramisu
    'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?w=900&q=80',
  ];
  int _heroIndex = 0;
  bool _heroFadeIn = true; // true = image courante visible
  Timer? _heroTimer;

  Map<String, dynamic>? _restaurantInfo;
  List<Product> _allProducts = [];
  List<String> _categories = []; // Catégories pour les onglets en haut
  List<String> _badges = []; // Badges pour les filtres en bas
  String _selectedCategory = 'Tout'; // Catégorie sélectionnée
  String _selectedBadge = ''; // Badge sélectionné (vide = tous)
  String _displayTableNumber = '';
  bool _isLoading = true;
  late ScrollController _scrollController;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  // ─── Recherche ────────────────────────────────────────────────────────────────
  bool _searchActive = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _searchAnimCtrl;
  late Animation<double> _searchWidthAnim;
  late Animation<double> _searchOpacityAnim;

  // ─── Palette locale ──────────────────────────────────────────────────────────
  static const _bg = Color(0xFFFFFDF7);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceVariant = Color(0xFFFDF6E8);
  static const _amber = Color(0xFFC8901A);
  static const _amberLight = Color(0xFFE8A83A);
  static const _amberGlow = Color(0x1AC8901A);
  static const _textPrimary = Color(0xFF1A1714);
  static const _textSecondary = Color(0xFF6B6350);
  static const _textLight = Color(0xFFA89F85);
  static const _divider = Color(0xFFEDE8D8);
  static const _shimmerBase = Color(0xFFF5F0E0);
  static const _shimmerHighlight = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _displayTableNumber = widget.tableNumber;
    _scrollController = ScrollController();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnim,
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    // Recherche
    _searchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchWidthAnim = CurvedAnimation(
      parent: _searchAnimCtrl,
      curve: Curves.easeInOut,
    );
    _searchOpacityAnim = CurvedAnimation(
      parent: _searchAnimCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    // Initialiser le tableId dans le CartProvider pour les appels API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().setTableId(widget.tableNumber);
    });
    _loadData();
    _startHeroSlideshow();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _scrollController.dispose();
    _fabAnimController.dispose();
    _searchAnimCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Fade-out → change → fade-in toutes les 20 s
  void _startHeroSlideshow() {
    _heroTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted) return;
      // Fade out
      setState(() => _heroFadeIn = false);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      // Change image
      setState(() {
        _heroIndex = (_heroIndex + 1) % _heroImages.length;
        _heroFadeIn = true;
      });
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final menuService = MenuService();
      
      // Charger les données depuis l'API
      _restaurantInfo = await menuService.getRestaurantInfo(widget.restaurantId);
      
      // Charger tous les plats actifs
      _allProducts = await menuService.getMenu(widget.restaurantId);
      
      // Charger les catégories pour les onglets en haut
      _categories = await menuService.getCategories(widget.restaurantId);
      
      // Charger les badges depuis le backend pour les filtres en bas
      final badgesData = await menuService.getBadgesFromBackend(widget.restaurantId);
      _badges = badgesData.map((b) => b['label']!).toList();
      
      _displayTableNumber = widget.tableNumber;
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppFeedback.showError(context, 'Impossible de charger le menu. Vérifiez votre connexion.');
      }
    }
  }

  List<Product> get _filteredProducts {
    List<Product> base;
    
    // Filtre par catégorie
    if (_selectedCategory == 'Tout') {
      base = _allProducts;
    } else {
      base = _allProducts.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filtre par badge (si un badge est sélectionné)
    if (_selectedBadge.isNotEmpty) {
      base = base.where((p) => 
        p.badgeLabel != null && p.badgeLabel == _selectedBadge
      ).toList();
    }
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        (p.badgeLabel?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return base;
  }

  List<Product> get _popularProducts =>
      _allProducts.where((p) => p.isPopular).toList();

  void _onBadgeChanged(String badge) {
    setState(() => _selectedBadge = badge);
  }

  void _openSearch() {
    setState(() => _searchActive = true);
    _searchAnimCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchAnimCtrl.reverse().then((_) {
      setState(() {
        _searchActive = false;
        _searchQuery = '';
        _searchCtrl.clear();
      });
    });
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
      backgroundColor: _bg,
      body: _isLoading ? _buildSkeleton() : _buildContent(),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isEmpty) {
            _fabAnimController.reverse();
            return const SizedBox.shrink();
          }
          _fabAnimController.forward();
          return ScaleTransition(
            scale: _fabScaleAnim,
            child: _buildCartFAB(cart),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        // Onglets de catégories en haut
        if (!_searchActive) SliverToBoxAdapter(child: _buildCategoryTabs()),
        // Suggestions du Chef (avec filtres badges intégrés)
        if (!_searchActive && _selectedCategory == 'Tout' && _popularProducts.isNotEmpty)
          SliverToBoxAdapter(child: _buildPopularSection()),
        _buildProductsSection(),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ─── Barre de recherche expansible ───────────────────────────────────────────

  Widget _buildActiveOrderButton() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final currentOrder = orderProvider.currentOrder;
        
        // Si pas de commande en cours, ne rien afficher
        if (currentOrder == null) {
          return const SizedBox.shrink();
        }
        
        // Si la commande est terminée ou annulée, ne pas afficher le bouton
        final status = orderProvider.currentStatus;
        if (status == OrderStatus.completed || status == OrderStatus.cancelled) {
          return const SizedBox.shrink();
        }
        
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () {
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _amber.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône animée
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (0.15 * (0.5 - (value - 0.5).abs())),
                        child: child,
                      );
                    },
                    onEnd: () {
                      // Relancer l'animation en boucle
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Commande\nen cours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchWidthAnim,
      builder: (context, _) {
        final screenW = MediaQuery.of(context).size.width;
        // Largeur : de 38px (icône) à presque tout l'écran
        final width = 38.0 + (screenW - 38.0 - 28.0) * _searchWidthAnim.value;

        return SizedBox(
          width: width,
          height: 38,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              // ── Fond de la barre ──────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: width,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: _searchActive
                        ? _amber.withOpacity(0.5)
                        : _divider,
                    width: 1.5,
                  ),
                  boxShadow: _searchActive
                      ? [
                          BoxShadow(
                            color: _amber.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
              ),

              // ── Champ de texte (visible uniquement quand actif) ───────────
              if (_searchActive)
                Positioned(
                  left: 14,
                  right: 42,
                  child: FadeTransition(
                    opacity: _searchOpacityAnim,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un plat…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: _textLight,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

              // ── Bouton icône (loupe ou croix) ─────────────────────────────
              GestureDetector(
                onTap: _searchActive ? _closeSearch : _openSearch,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _searchActive ? _amber : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      _searchActive ? Icons.close_rounded : Icons.search_rounded,
                      key: ValueKey(_searchActive),
                      size: 18,
                      color: _searchActive ? Colors.white : _textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── SliverAppBar ─────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _buildActiveOrderButton(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildSearchBar(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── Slideshow hero avec crossfade ──────────────────────────────
            AnimatedOpacity(
              opacity: _heroFadeIn ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              child: CachedNetworkImage(
                key: ValueKey(_heroIndex),
                imageUrl: _heroImages[_heroIndex],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_amber, _amberLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // Indicateurs de position (petits dots)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_heroImages.length, (i) {
                  final isActive = i == _heroIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            // Overlay : sombre en haut, très sombre en bas pour le texte
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x33000000), // léger en haut
                    Color(0x00000000), // transparent au milieu
                    Color(0x00000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 1.0],
                ),
              ),
            ),

            // Informations du restaurant
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xEE000000), // quasi-opaque en bas
                      Color(0xAA000000),
                      Color(0x55000000),
                      Color(0x00000000),
                    ],
                    stops: [0.0, 0.45, 0.75, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du restaurant
                    Text(
                      _restaurantInfo?['name'] ?? 'Restaurant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Description
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: _amberLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            (_restaurantInfo?['description'] as String?)
                                    ?.isNotEmpty == true
                                ? _restaurantInfo!['description'] as String
                                : 'Expérience Gastronomique',
                            style: const TextStyle(
                              color: Color(0xFFE8D5A3),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Onglets catégories (en haut) ────────────────────────────────────────────

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (_, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;
            return GestureDetector(
              onTap: () => _onCategoryChanged(category),
              child: AnimatedContainer(
                duration: AppTheme.fastAnim,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? _amber : _surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? _amber : _divider,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _amber.withOpacity(0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedBadge = ''; // Réinitialiser le filtre badge
    });
  }

  // ─── Filtres badges (en bas de "Suggestions du Chef") ────────────────────────

  Widget _buildBadgeFilters() {
    if (_badges.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: _textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Filtrer par badge',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _badges.length + 1, // +1 pour "Tous"
            itemBuilder: (_, index) {
              if (index == 0) {
                // Bouton "Tous"
                final isSelected = _selectedBadge.isEmpty;
                return GestureDetector(
                  onTap: () => _onBadgeChanged(''),
                  child: AnimatedContainer(
                    duration: AppTheme.fastAnim,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? _amber.withOpacity(0.15) : _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _amber : _divider,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tous',
                        style: TextStyle(
                          color: isSelected ? _amber : _textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              final badge = _badges[index - 1];
              final isSelected = badge == _selectedBadge;
              return GestureDetector(
                onTap: () => _onBadgeChanged(badge),
                child: AnimatedContainer(
                  duration: AppTheme.fastAnim,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? _amber.withOpacity(0.15) : _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _amber : _divider,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: isSelected ? _amber : _textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // void _onBadgeChanged(String badge) {
  //   setState(() {
  //     _selectedBadge = badge;
  //   });
  // }

  // ─── Badges (filtres) ─────────────────────────────────────────────────────────

  // ─── Suggestions du Chef ─────────────────────────────────────────────────────

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            children: [
              const Text(
                'Suggestions du Chef',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _amberGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _amber.withOpacity(0.25)),
                ),
                child: const Text(
                  '✦ Sélection',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularProducts.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => showProductDetail(context, _popularProducts[index]),
              child: _PopularCard(product: _popularProducts[index]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Filtres de badges
        _buildBadgeFilters(),
        const SizedBox(height: 8),
        // Séparateur décoratif
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: _divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _amberLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: _divider)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Liste produits ───────────────────────────────────────────────────────────

  Widget _buildProductsSection() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchActive
                      ? Icons.search_off_rounded
                      : Icons.restaurant_menu_rounded,
                  size: 40,
                  color: _textLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchActive
                    ? 'Aucun résultat pour\n"$_searchQuery"'
                    : 'Bientôt disponible',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              if (_searchActive) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _closeSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _amberGlow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _amber.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Effacer la recherche',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _searchActive
                      ? '${products.length} résultat${products.length > 1 ? 's' : ''} pour "$_searchQuery"'
                      : (_selectedBadge == 'Tout' ? 'Le Menu' : _selectedBadge),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => showProductDetail(context, products[index - 1]),
                child: _ProductCard(product: products[index - 1]),
              ),
            );
          },
          childCount: products.length + 1,
        ),
      ),
    );
  }

  // ─── FAB Panier ───────────────────────────────────────────────────────────────

  Widget _buildCartFAB(CartProvider cart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 64,
      decoration: BoxDecoration(
        color: _amber,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _amber.withOpacity(0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCart,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Icône panier
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VOTRE COMMANDE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Total
                Text(
                  '${cart.total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Skeleton ─────────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            backgroundColor: _shimmerBase,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: _shimmerBase),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => Container(
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _shimmerBase,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                childCount: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton icône circulaire ──────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEDE8D8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: const Color(0xFF1A1714),
        ),
      ),
    );
  }
}

// ─── Carte produit (liste) ────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  static const _amber        = Color(0xFFC8901A);
  static const _textPrimary  = Color(0xFF1A1714);
  static const _textSecondary= Color(0xFF6B6350);
  static const _divider      = Color(0xFFEDE8D8);
  static const _surfaceVariant = Color(0xFFFDF6E8);

  // Hauteur fixe pour toutes les cards
  static const double _cardHeight = 110.0;
  static const double _imageWidth = 110.0;

  // Parser une couleur hexadécimale
  static Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      // Fallback sur amber si erreur
    }
    return _amber;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final qty = cart.getQuantity(product.id);
        return SizedBox(
          height: _cardHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Image (largeur fixe, hauteur = card) ──────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                  child: SizedBox(
                    width: _imageWidth,
                    height: _cardHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          cacheManager: CustomCacheManager.instance,
                          maxHeightDiskCache: 400,
                          maxWidthDiskCache: 400,
                          memCacheHeight: 400,
                          memCacheWidth: 400,
                          placeholder: (_, __) => Container(
                            color: _surfaceVariant,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_amber.withOpacity(0.5)),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              Container(color: _surfaceVariant,
                                child: const Icon(Icons.restaurant,
                                    color: Color(0xFFC8901A), size: 32)),
                        ),
                        if (product.isPopular)
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('✦',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 9)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Contenu (flex, hauteur contrainte par SizedBox parent) ─
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nom
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Description
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Prix + contrôle quantité
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _amber,
                              ),
                            ),
                            if (qty == 0)
                              _PremiumAddButton(
                                onTap: () {
                                  cart.addProduct(product);
                                  AppFeedback.showSuccess(
                                    context,
                                    '${product.name} ajouté au panier',
                                  );
                                },
                              )
                            else
                              _PremiumQuantityControl(
                                quantity: qty,
                                onAdd: () => cart.addProduct(product),
                                onRemove: () =>
                                    cart.removeProduct(product.id),
                              ),
                          ],
                        ),
                      ],
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
}

// ─── Carte populaire (carrousel) ──────────────────────────────────────────────

class _PopularCard extends StatelessWidget {
  final Product product;
  const _PopularCard({required this.product});

  static const _amber = Color(0xFFC8901A);
  static const _amberLight = Color(0xFFE8A83A);
  static const _textPrimary = Color(0xFF1A1714);
  static const _divider = Color(0xFFEDE8D8);
  static const _surfaceVariant = Color(0xFFFDF6E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 14, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: _surfaceVariant),
                  ),
                ),
                // Bouton favori
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: _divider),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 14,
                      color: _amber,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Infos
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _amber,
                        ),
                      ),
                      Consumer<CartProvider>(
                        builder: (_, cart, __) => _PremiumAddButton(
                          size: 30,
                          onTap: () => cart.addProduct(product),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton ajouter ───────────────────────────────────────────────────────────

class _PremiumAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  const _PremiumAddButton({required this.onTap, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFC8901A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8901A).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );
  }
}

// ─── Contrôle quantité ────────────────────────────────────────────────────────

class _PremiumQuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PremiumQuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFC8901A).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: onRemove,
            isAdd: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF1A1714),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: onAdd,
            isAdd: true,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.isAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFFC8901A) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: isAdd ? Colors.white : const Color(0xFF6B6350),
        ),
      ),
    );
  }
}