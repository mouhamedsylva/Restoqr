import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../main.dart'; // Pour CustomCacheManager
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/app_feedback.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber        = Color(0xFFC8901A);
const _amberLight   = Color(0xFFE8A83A);
const _bg           = Color(0xFFFFFDF7);
const _surface      = Color(0xFFFFFFFF);
const _surfaceVar   = Color(0xFFFDF6E8);
const _textPrimary  = Color(0xFF1A1714);
const _textSecondary= Color(0xFF6B6350);
const _textLight    = Color(0xFFA89F85);
const _divider      = Color(0xFFEDE8D8);

// ── Option model ──────────────────────────────────────────────────────────────
class _ItemOption {
  final String id;
  final String name;
  final double price;
  _ItemOption({required this.id, required this.name, required this.price});
  factory _ItemOption.fromJson(Map<String, dynamic> j) => _ItemOption(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
      );
}

// ── Public entry point ────────────────────────────────────────────────────────
Future<void> showProductDetail(BuildContext context, Product product) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductDetailSheet(product: product),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────────────────
class _ProductDetailSheet extends StatefulWidget {
  final Product product;
  const _ProductDetailSheet({required this.product});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet>
    with TickerProviderStateMixin {
  List<_ItemOption> _options = [];
  bool _loadingOptions = true;
  String? _selectedOptionId;

  // ── Quantité locale avec animation ────────────────────────────────────────
  int _qty = 1;
  late AnimationController _qtyAnimCtrl;
  late Animation<double> _qtyScale;
  bool _lastWasAdd = true;

  // ── Note / instructions spéciales ─────────────────────────────────────────
  final TextEditingController _noteCtrl = TextEditingController();
  bool _showNoteField = false;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
    _qtyAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _qtyScale = CurvedAnimation(
      parent: _qtyAnimCtrl,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.6, end: 1.0));
  }

  @override
  void dispose() {
    _qtyAnimCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _qty++;
      _lastWasAdd = true;
    });
    _qtyAnimCtrl.forward(from: 0);
  }

  void _decrement() {
    if (_qty <= 1) return;
    setState(() {
      _qty--;
      _lastWasAdd = false;
    });
    _qtyAnimCtrl.forward(from: 0);
  }

  Future<void> _fetchOptions() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/menus/items/${widget.product.id}/options'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _options = data.map((j) => _ItemOption.fromJson(j)).toList();
            _loadingOptions = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingOptions = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  double get _totalPrice {
    final base = widget.product.price;
    double optionExtra = 0;
    if (_selectedOptionId != null) {
      final opt = _options.firstWhere(
        (o) => o.id == _selectedOptionId,
        orElse: () => _ItemOption(id: '', name: '', price: 0),
      );
      optionExtra = opt.price;
    }
    return (base + optionExtra) * _qty;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroImage(p),
                  _buildHeader(p),
                  _buildDivider(),
                  if (p.description.isNotEmpty) _buildDescription(p),
                  if (p.tags.isNotEmpty) _buildTags(p),
                  if (p.allergens.isNotEmpty) _buildAllergens(p),
                  _buildNutrition(p),
                  if (!_loadingOptions && _options.isNotEmpty) _buildOptions(),
                  _buildQuantitySelector(),
                  _buildNoteField(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // ── Bottom CTA ────────────────────────────────────────────────────
          _buildCTA(p),
        ],
      ),
    );
  }

  // ── Hero image ──────────────────────────────────────────────────────────────
  Widget _buildHeroImage(Product p) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: p.imageUrl,
              fit: BoxFit.cover,
              cacheManager: CustomCacheManager.instance,
              maxHeightDiskCache: 800,
              maxWidthDiskCache: 800,
              memCacheHeight: 800,
              memCacheWidth: 800,
              placeholder: (_, __) => Container(
                color: _surfaceVar,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_amber.withOpacity(0.5)),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: _surfaceVar,
                child: const Icon(Icons.restaurant, color: _amber, size: 64),
              ),
            ),
          ),
        ),
        // Gradient overlay bas
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_bg, _bg.withOpacity(0)],
              ),
            ),
          ),
        ),
        // Bouton fermer
        Positioned(
          top: 16, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        // Badge populaire
        if (p.isPopular)
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text('Populaire',
                      style: GoogleFonts.lora(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Header : nom + prix ─────────────────────────────────────────────────────
  Widget _buildHeader(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.2,
                    )),
                const SizedBox(height: 4),
                Text(p.category,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: _textLight,
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_totalPrice.toStringAsFixed(2)} €',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ─────────────────────────────────────────────────────────────
  Widget _buildDescription(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Text(
        p.description,
        style: GoogleFonts.lora(
          fontSize: 14,
          color: _textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  // ── Tags (badge, plat du jour, labels diét.) ────────────────────────────────
  Widget _buildTags(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: p.tags.map((tag) {
          final isSpecial = tag == 'Plat du jour';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSpecial
                  ? _amber.withOpacity(0.12)
                  : _surfaceVar,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSpecial ? _amber.withOpacity(0.4) : _divider,
              ),
            ),
            child: Text(
              tag,
              style: GoogleFonts.lora(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSpecial ? _amber : _textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Allergènes ──────────────────────────────────────────────────────────────
  Widget _buildAllergens(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Allergènes', Icons.warning_amber_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: p.allergens.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(a,
                  style: GoogleFonts.lora(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  )),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ── Nutrition (temps de prépa) ───────────────────────────────────────────────
  Widget _buildNutrition(Product p) {
    if (p.preparationTime == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _infoChip(Icons.timer_outlined, '${p.preparationTime} min', 'Préparation'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceVar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _amber),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  )),
              Text(label,
                  style: GoogleFonts.lora(
                    fontSize: 10,
                    color: _textLight,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Options ─────────────────────────────────────────────────────────────────
  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Options', Icons.tune_rounded),
          const SizedBox(height: 10),
          ..._options.map((opt) {
            final selected = _selectedOptionId == opt.id;
            return GestureDetector(
              onTap: () => setState(() =>
                  _selectedOptionId = selected ? null : opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? _amber.withOpacity(0.08)
                      : _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _amber : _divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _amber : Colors.transparent,
                        border: Border.all(
                          color: selected ? _amber : _textLight,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(opt.name,
                          style: GoogleFonts.lora(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          )),
                    ),
                    if (opt.price > 0)
                      Text('+${opt.price.toStringAsFixed(2)} €',
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _amber,
                          )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Sélecteur de quantité animé ─────────────────────────────────────────────
  Widget _buildQuantitySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Quantité', Icons.shopping_basket_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              // Bouton -
              _QtyCircleBtn(
                icon: Icons.remove_rounded,
                enabled: _qty > 1,
                onTap: _decrement,
                filled: false,
              ),
              const SizedBox(width: 20),
              // Chiffre animé
              SizedBox(
                width: 40,
                child: AnimatedBuilder(
                  animation: _qtyAnimCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _qtyScale.value,
                    child: Text(
                      '$_qty',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Bouton +
              _QtyCircleBtn(
                icon: Icons.add_rounded,
                enabled: true,
                onTap: _increment,
                filled: true,
              ),
              const Spacer(),
              // Prix unitaire
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.product.price.toStringAsFixed(2)} € / unité',
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      color: _textLight,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _qtyAnimCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _qtyScale.value,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_totalPrice.toStringAsFixed(2)} €',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Note / instructions spéciales ──────────────────────────────────────────
  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton toggle
          GestureDetector(
            onTap: () => setState(() => _showNoteField = !_showNoteField),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _showNoteField
                    ? _amber.withOpacity(0.08)
                    : _surfaceVar,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _showNoteField ? _amber.withOpacity(0.4) : _divider,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: _showNoteField ? _amber : _textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _noteCtrl.text.isNotEmpty
                          ? _noteCtrl.text
                          : 'Ajouter une note (sans oignons, allergie…)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _noteCtrl.text.isNotEmpty
                            ? _textPrimary
                            : _textLight,
                        fontStyle: _noteCtrl.text.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _showNoteField
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _textLight,
                  ),
                ],
              ),
            ),
          ),

          // Champ de saisie animé
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showNoteField
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _noteCtrl,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 150,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Ex: sans oignons, bien cuit, allergie aux noix…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: _textLight,
                          fontStyle: FontStyle.italic,
                        ),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _amber, width: 1.5),
                        ),
                        counterStyle: TextStyle(
                          fontSize: 11,
                          color: _textLight,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── CTA ─────────────────────────────────────────────────────────────────────
  Widget _buildCTA(Product p) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: _bg,
            border: Border(top: BorderSide(color: _divider)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              final note = _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim();
              for (int i = 0; i < _qty; i++) {
                cart.addProductWithNote(p, note: note);
              }
              Navigator.of(context).pop();
              // Message de succès dans le contexte parent (menu_screen)
              AppFeedback.showSuccess(
                context,
                _qty == 1
                    ? '${p.name} ajouté au panier'
                    : '$_qty × ${p.name} ajoutés au panier',
              );
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_amberLight, _amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _amber.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _qty == 1
                        ? 'Ajouter au panier'
                        : 'Ajouter $_qty au panier',
                    style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_totalPrice.toStringAsFixed(2)} €',
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(color: _divider, height: 1),
      );

  Widget _sectionLabel(String text, IconData icon) => Row(
        children: [
          Icon(icon, size: 15, color: _amber),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 0.3,
              )),
        ],
      );
}

// ── Qty circle button ─────────────────────────────────────────────────────────
class _QtyCircleBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;
  const _QtyCircleBtn({
    required this.icon,
    required this.enabled,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? (enabled ? _amber : _amber.withOpacity(0.4))
              : _surfaceVar,
          border: filled
              ? null
              : Border.all(
                  color: enabled ? _divider : _divider.withOpacity(0.4),
                ),
          boxShadow: filled && enabled
              ? [
                  BoxShadow(
                    color: _amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled
              ? Colors.white
              : (enabled ? _textSecondary : _textLight),
        ),
      ),
    );
  }
}
