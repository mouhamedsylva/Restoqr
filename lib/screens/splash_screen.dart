import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../services/restaurant_service.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  final String restaurantId;
  final String tableId;

  const SplashScreen({
    super.key,
    required this.restaurantId,
    required this.tableId,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ─── Palette ivoire & dorée ────────────────────────────────────────────────
  static const Color _bg        = Color(0xFFFFFDF7);
  static const Color _cream     = Color(0xFFFDF6E3);
  static const Color _gold      = Color(0xFFC8901A);
  static const Color _goldLight = Color(0xFFE8A83A);
  static const Color _goldPale  = Color(0xFFF5DFA0);
  static const Color _goldMuted = Color(0xFFD4A84B);
  static const Color _textDark  = Color(0xFF3D2B0E);
  static const Color _textMid   = Color(0xFF7A5C2E);
  static const Color _textLight = Color(0xFFB8924A);
  static const Color _divider   = Color(0xFFEDD9A3);

  // ─── State ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _restaurant;
  bool _hasError   = false;
  bool _navigating = false;

  // ─── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _subCtrl;
  late AnimationController _footerCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  // ─── Animations ────────────────────────────────────────────────────────────
  late Animation<double> _fadeIn;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<Offset>  _titleSlide;
  late Animation<double> _subOpacity;
  late Animation<Offset>  _subSlide;
  late Animation<double> _footerOpacity;
  late Animation<double> _shimmer;
  late Animation<double> _pulse;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRestaurant();
  }

  void _setupAnimations() {
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.65, end: 1.0));

    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _titleOpacity = CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _titleSlide = CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.15), end: Offset.zero));

    _subCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _subOpacity = CurvedAnimation(parent: _subCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _subSlide = CurvedAnimation(parent: _subCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.2), end: Offset.zero));

    _footerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _footerOpacity = CurvedAnimation(parent: _footerCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _shimmer = _shimmerCtrl.drive(Tween(begin: -2.0, end: 3.0));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.5, end: 1.0));

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _float = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: -5.0, end: 5.0));

    // Séquence orchestrée
    _fadeCtrl.forward().then((_) {
      _logoCtrl.forward().then((_) {
        _titleCtrl.forward().then((_) {
          _subCtrl.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _footerCtrl.forward();
            });
          });
        });
      });
    });
  }

  Future<void> _loadRestaurant() async {
    try {
      final service = RestaurantService();
      final info    = await service.getRestaurantInfo(widget.restaurantId);
      if (mounted) {
        setState(() => _restaurant = info);
        await Future.delayed(const Duration(milliseconds: 4000));
        _navigateToMenu();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError   = true;
          _restaurant = null;
        });
      }
    }
  }

  void _navigateToMenu() {
    if (_navigating || !mounted) return;
    _navigating = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (_, __, ___) =>
          MenuScreen(restaurantId: widget.restaurantId, tableNumber: widget.tableId),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ));
  }

  @override
  void dispose() {
    for (final c in [
      _fadeCtrl, _logoCtrl, _titleCtrl, _subCtrl,
      _footerCtrl, _shimmerCtrl, _pulseCtrl, _floatCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  String  get _restaurantName => _restaurant?['name']        as String? ?? '';
  String? get _description    => _restaurant?['description'] as String?;
  String? get _address        => _restaurant?['address']     as String?;
  String? get _phone          => _restaurant?['phoneNumber'] as String?;
  String? get _logoUrl {
    final raw = _restaurant?['logoUrl'] as String?;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/v1'), '');
    return '$base$raw';
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(size),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildOrnamentDivider(),
                  const SizedBox(height: 22),
                  _buildTitle(),
                  const SizedBox(height: 10),
                  _buildSubtitle(),
                  const SizedBox(height: 20),
                  _buildOrnamentDivider(reverse: true),
                  const Spacer(flex: 3),
                  _buildQRCodeBox(),
                  const SizedBox(height: 22),
                  _buildTableBadge(),
                  const SizedBox(height: 16),
                  _buildContactRow(),
                  const SizedBox(height: 32),
                  _buildProgressBar(),
                  const SizedBox(height: 12),
                  _buildStatusLabel(),
                  const SizedBox(height: 44),
                ],
              ),
            ),
            if (_hasError) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  // ─── Fond décoratif ────────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: _bg),
        // Halo doré haut-gauche
        Positioned(
          top: -size.height * 0.12,
          left: -size.width * 0.2,
          child: Container(
            width: size.width * 0.75,
            height: size.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _goldPale.withOpacity(0.55),
                _goldPale.withOpacity(0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Halo doré bas-droite
        Positioned(
          bottom: -size.height * 0.1,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.65,
            height: size.width * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _goldPale.withOpacity(0.45),
                _goldPale.withOpacity(0.10),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Halo central subtil
        Center(
          child: Container(
            width: size.width * 0.85,
            height: size.width * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _goldPale.withOpacity(0.18),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Ligne verticale gauche
        Positioned(
          left: 22,
          top: size.height * 0.12,
          bottom: size.height * 0.12,
          child: Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _gold.withOpacity(0.22),
                  _gold.withOpacity(0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Ligne verticale droite
        Positioned(
          right: 22,
          top: size.height * 0.12,
          bottom: size.height * 0.12,
          child: Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _gold.withOpacity(0.22),
                  _gold.withOpacity(0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Grille de points haut-droite
        Positioned(
          top: size.height * 0.07,
          right: size.width * 0.07,
          child: CustomPaint(
            size: const Size(56, 56),
            painter: _DotGridPainter(color: _gold.withOpacity(0.16)),
          ),
        ),
        // Grille de points bas-gauche
        Positioned(
          bottom: size.height * 0.16,
          left: size.width * 0.06,
          child: CustomPaint(
            size: const Size(56, 56),
            painter: _DotGridPainter(color: _gold.withOpacity(0.16)),
          ),
        ),
      ],
    );
  }

  // ─── Logo flottant ─────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoCtrl, _floatCtrl]),
      builder: (_, __) => Opacity(
        opacity: _logoOpacity.value,
        child: Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.scale(
            scale: _logoScale.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo externe pulsant
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _goldPale.withOpacity(0.45),
                      Colors.transparent,
                    ]),
                  ),
                ),
                // Cercle principal
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cream,
                    border: Border.all(color: _gold.withOpacity(0.55), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.20),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: _goldPale.withOpacity(0.50),
                        blurRadius: 72,
                        spreadRadius: 14,
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: _logoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _logoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _logoIcon(),
                            errorWidget: (_, __, ___) => _logoIcon(),
                          ),
                        )
                      : _logoIcon(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoIcon() => Center(
    child: Icon(Icons.restaurant_rounded, color: _gold, size: 48),
  );

  // ─── Séparateur ornemental ─────────────────────────────────────────────────
  Widget _buildOrnamentDivider({bool reverse = false}) {
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (_, __) => Opacity(
        opacity: _logoOpacity.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: CustomPaint(
            size: const Size(double.infinity, 20),
            painter: _OrnamentDividerPainter(color: _gold, reverse: reverse),
          ),
        ),
      ),
    );
  }

  // ─── Titre avec shimmer doré ───────────────────────────────────────────────
  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleOpacity,
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (_, child) {
            final v  = _shimmer.value;
            final s0 = (v - 1.0).clamp(0.0, 1.0);
            final s1 = v.clamp(0.0, 1.0);
            final s2 = (v + 0.8).clamp(0.0, 1.0);
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _gold, _goldMuted, _goldLight, _goldPale, _goldMuted, _gold
                ],
                stops: [
                  s0, (s0 + s1) / 2, s1,
                  (s1 + s2) / 2, (s1 + s2) / 2 + 0.05, s2,
                ],
              ).createShader(bounds),
              child: child!,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              _restaurantName.isEmpty ? 'Chargement…' : _restaurantName,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: _gold,
                letterSpacing: 2.0,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sous-titre ────────────────────────────────────────────────────────────
  Widget _buildSubtitle() {
    final desc = _description;
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();
    return SlideTransition(
      position: _subSlide,
      child: FadeTransition(
        opacity: _subOpacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              color: _textMid,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.6,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Boîte QR Code premium ─────────────────────────────────────────────────
  Widget _buildQRCodeBox() {
    return FadeTransition(
      opacity: _footerOpacity,
      child: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            border: Border.all(color: _gold.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _goldPale.withOpacity(0.30),
                blurRadius: 48,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond dégradé
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _cream,
                        _goldPale.withOpacity(0.28),
                      ],
                    ),
                  ),
                ),
                // Coins décoratifs
                Positioned(top: 10, left: 10,
                  child: _qrCorner(false, false)),
                Positioned(top: 10, right: 10,
                  child: _qrCorner(true, false)),
                Positioned(bottom: 10, left: 10,
                  child: _qrCorner(false, true)),
                Positioned(bottom: 10, right: 10,
                  child: _qrCorner(true, true)),
                // Contenu centré
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 80,
                        color: _gold.withOpacity(0.85),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MENU DIGITAL',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _textMid,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Coins décoratifs de la boîte QR
  Widget _qrCorner(bool right, bool bottom) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _CornerPainter(
        color: _gold.withOpacity(0.5),
        right: right,
        bottom: bottom,
      ),
    );
  }

  // ─── Badge table ───────────────────────────────────────────────────────────
  Widget _buildTableBadge() {
    String tableDisplay = 'TABLE';
    final tableId = widget.tableId;
    final numberMatch = RegExp(r'\d+').firstMatch(tableId);
    if (numberMatch != null) {
      tableDisplay = 'TABLE  ${numberMatch.group(0)}';
    } else if (tableId.length >= 4) {
      tableDisplay = 'TABLE  ${tableId.substring(0, 4).toUpperCase()}';
    } else {
      tableDisplay = 'TABLE  ${tableId.toUpperCase()}';
    }

    return FadeTransition(
      opacity: _footerOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: _cream,
          border: Border.all(color: _gold.withOpacity(0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_restaurant_rounded, color: _gold, size: 14),
            const SizedBox(width: 10),
            Text(
              tableDisplay,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: _textDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Infos contact ─────────────────────────────────────────────────────────
  Widget _buildContactRow() {
    final items = <Widget>[];
    if (_address != null && _address!.isNotEmpty) {
      items.add(_contactChip(Icons.location_on_outlined, _address!));
    }
    if (items.isNotEmpty && _phone != null && _phone!.isNotEmpty) {
      items.add(Container(
        width: 1, height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: _divider,
      ));
    }
    if (_phone != null && _phone!.isNotEmpty) {
      items.add(_contactChip(Icons.phone_outlined, _phone!));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _footerOpacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      ),
    );
  }

  Widget _contactChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _textLight, size: 12),
      const SizedBox(width: 5),
      Text(
        text,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 12,
          color: _textMid,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );

  // ─── Barre de progression ──────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return FadeTransition(
      opacity: _footerOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72),
        child: Stack(
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _restaurant != null ? 1.0 : 0.35),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOut,
              builder: (_, value, __) => FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [_goldPale, _gold, _goldLight],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Label statut ──────────────────────────────────────────────────────────
  Widget _buildStatusLabel() {
    return FadeTransition(
      opacity: _footerOpacity,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Opacity(
          opacity: _pulse.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusDot(),
              const SizedBox(width: 10),
              Text(
                _restaurant == null ? 'CHARGEMENT DU MENU' : 'BIENVENUE',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 11,
                  color: _textLight,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              _statusDot(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot() => Container(
    width: 5, height: 5,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _gold.withOpacity(0.55),
    ),
  );

  // ─── Erreur ────────────────────────────────────────────────────────────────
  Widget _buildErrorOverlay() {
    return Container(
      color: _bg.withOpacity(0.97),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cream,
                  border: Border.all(color: _gold.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(Icons.wifi_off_rounded, color: _gold, size: 30),
              ),
              const SizedBox(height: 28),
              Text(
                'Connexion impossible',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vérifiez votre connexion et réessayez.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  color: _textMid,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: () {
                  setState(() { _hasError = false; _navigating = false; });
                  _loadRestaurant();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: _cream,
                    border: Border.all(color: _gold.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'RÉESSAYER',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 13,
                      color: _textDark,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

/// Séparateur ornemental avec losange central et lignes dégradées
class _OrnamentDividerPainter extends CustomPainter {
  final Color color;
  final bool  reverse;
  const _OrnamentDividerPainter({required this.color, this.reverse = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width  / 2;
    final lp = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9;

    // Ligne gauche dégradée
    lp.shader = LinearGradient(
      colors: [Colors.transparent, color.withOpacity(0.5), color.withOpacity(0.3)],
    ).createShader(Rect.fromLTWH(0, 0, cx - 14, size.height));
    canvas.drawLine(Offset(0, cy), Offset(cx - 14, cy), lp);

    // Ligne droite dégradée
    lp.shader = LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0.5), Colors.transparent],
    ).createShader(Rect.fromLTWH(cx + 14, 0, cx - 14, size.height));
    canvas.drawLine(Offset(cx + 14, cy), Offset(size.width, cy), lp);

    // Losange central
    lp.shader  = null;
    lp.color   = color.withOpacity(0.85);
    lp.strokeWidth = 1.3;
    const d = 7.0;
    final diamond = Path()
      ..moveTo(cx,     cy - d)
      ..lineTo(cx + d, cy)
      ..lineTo(cx,     cy + d)
      ..lineTo(cx - d, cy)
      ..close();
    canvas.drawPath(diamond, lp);

    // Point central
    canvas.drawCircle(
      Offset(cx, cy), 2.0,
      Paint()..color = color..style = PaintingStyle.fill,
    );

    // Petits points latéraux
    final dotPaint = Paint()
      ..color = color.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 22, cy), 1.5, dotPaint);
    canvas.drawCircle(Offset(cx + 22, cy), 1.5, dotPaint);
    canvas.drawCircle(Offset(cx - 34, cy), 1.0, dotPaint);
    canvas.drawCircle(Offset(cx + 34, cy), 1.0, dotPaint);
  }

  @override
  bool shouldRepaint(_OrnamentDividerPainter old) =>
      old.color != color || old.reverse != reverse;
}

/// Grille de points décoratifs
class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    const spacing = 14.0;
    const radius  = 1.5;
    for (double x = 0; x <= size.width;  x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

/// Coins décoratifs de la boîte QR
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool  right;
  final bool  bottom;
  const _CornerPainter({
    required this.color,
    required this.right,
    required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (!right && !bottom) {
      // haut-gauche
      canvas.drawLine(Offset(w, 0), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
    } else if (right && !bottom) {
      // haut-droite
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!right && bottom) {
      // bas-gauche
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      // bas-droite
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.right != right || old.bottom != bottom;
}