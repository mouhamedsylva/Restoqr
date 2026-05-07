import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/notification_service.dart';
import '../services/order_persistence_service.dart';
import '../services/table_service.dart';
import '../utils/app_feedback.dart';
import 'menu_screen.dart';

// Palette de couleurs moderne
const _primaryOrange = Color(0xFFD2691E);
const _lightOrange = Color(0xFFFFF5EE);
const _darkText = Color(0xFF2C2C2C);
const _lightText = Color(0xFF8E8E8E);
const _background = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _success = Color(0xFF22C55E);
const _error = Color(0xFFEF4444);

class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  final String tableNumber;
  final String restaurantId;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.tableNumber,
    required this.restaurantId,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with TickerProviderStateMixin {
  late StreamSubscription<OrderStatus> _statusSubscription;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  OrderStatus _status = OrderStatus.pending;
  bool _isStreamActive = true;
  bool _showDetails = false;
  NotificationService? _notificationService;
  String _displayTableNumber = '';
  final TableService _tableService = TableService();

  @override
  void initState() {
    super.initState();
    _displayTableNumber = widget.tableNumber;
    _loadTableInfo();

    // Animation de pulsation pour l'image
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de fade pour les transitions
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _startStatusStream();
  }

  void _startStatusStream() {
    final orderProvider = context.read<OrderProvider>();
    final statusStream = orderProvider.watchStatus(widget.orderId);
    
    _statusSubscription = statusStream.listen((status) {
      if (!mounted) return;
      _onStatusChanged(status);
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _isStreamActive = false);
    });

    _notificationService = NotificationService();
    _notificationService!.startListening(statusStream, context);
  }

  void _onStatusChanged(OrderStatus newStatus) {
    if (newStatus == _status) return;

    // Animation de transition
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _status = newStatus);
      _fadeController.forward();
    });
    
    // Nettoyer la session si terminée ou annulée
    if (newStatus == OrderStatus.completed || newStatus == OrderStatus.cancelled) {
      OrderPersistenceService.clearActiveOrder();
      _pulseController.stop();
      _pulseController.animateTo(1.0);
    }
  }

  Future<void> _refreshStatus() async {
    final orderProvider = context.read<OrderProvider>();
    final status = await orderProvider.getOrderStatus(widget.orderId);
    if (status != null && mounted) {
      _onStatusChanged(status);
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

  @override
  void dispose() {
    _statusSubscription.cancel();
    _notificationService?.stopListening();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Commande #${widget.orderId.substring(0, 8).toUpperCase()}',
          style: TextStyle(
            color: _lightText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isStreamActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildLiveIndicator(),
            ),
          IconButton(
            icon: Icon(Icons.restaurant, color: _primaryOrange),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuScreen(
                    restaurantId: widget.restaurantId,
                    tableNumber: widget.tableNumber,
                  ),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        color: _primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildStatusImage(),
                const SizedBox(height: 32),
                _buildStatusTitle(),
                const SizedBox(height: 8),
                _buildStatusDescription(),
                const SizedBox(height: 48),
                _buildTimeline(),
                const SizedBox(height: 32),
                _buildDetailsSection(),
                // Afficher le bouton "Nouvelle commande" uniquement si terminée ou annulée
                if (_status == OrderStatus.completed || _status == OrderStatus.cancelled) ...[
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: _success,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusImage() {
    final shouldPulse = _status != OrderStatus.completed && 
                        _status != OrderStatus.cancelled &&
                        _status != OrderStatus.ready;

    return AnimatedBuilder(
      animation: shouldPulse ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image circulaire de fond
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  _getStatusImageUrl(),
                ),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor().withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          // Badge de statut
          Positioned(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        _getMainTitle(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _darkText,
        ),
      ),
    );
  }

  Widget _buildStatusDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        _getMainDescription(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: _lightText,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'status': OrderStatus.pending, 'label': 'Reçue', 'desc': '12:45 • Cuisine informée'},
      {'status': OrderStatus.preparing, 'label': 'En préparation', 'desc': 'Le Chef s\'occupe de vous'},
      {'status': OrderStatus.ready, 'label': 'Prête', 'desc': 'Attente du service'},
      {'status': OrderStatus.completed, 'label': 'Servie', 'desc': 'Bon appétit !'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final stepStatus = step['status'] as OrderStatus;
          final isDone = _status.step > stepStatus.step;
          final isCurrent = _status.step == stepStatus.step;
          final isLast = index == steps.length - 1;

          return _buildTimelineStep(
            label: step['label'] as String,
            description: step['desc'] as String,
            isDone: isDone,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String label,
    required String description,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isDone
        ? _primaryOrange
        : isCurrent
            ? _primaryOrange
            : _lightText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur circulaire
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone || isCurrent ? _primaryOrange : _white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone || isCurrent ? _primaryOrange : _lightText.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isDone || isCurrent
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
                child: isDone
                    ? const Icon(Icons.check, color: _white, size: 20)
                    : isCurrent
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: _white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Icon(Icons.access_time, color: _lightText, size: 18),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDone ? _primaryOrange : _lightText.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Texte
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDone || isCurrent ? _darkText : _lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: _lightText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _showDetails ? _primaryOrange : _lightText.withOpacity(0.2),
            width: _showDetails ? 2 : 1,
          ),
          boxShadow: _showDetails
              ? [
                  BoxShadow(
                    color: _primaryOrange.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: _primaryOrange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Détails de la commande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _darkText,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _showDetails ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.keyboard_arrow_down, color: _lightText),
                ),
              ],
            ),
            if (_showDetails) ...[
              const SizedBox(height: 16),
              Divider(color: _lightText.withOpacity(0.2)),
              const SizedBox(height: 16),
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  final order = orderProvider.currentOrder;
                  if (order == null) {
                    return Text(
                      'Chargement...',
                      style: TextStyle(color: _lightText),
                    );
                  }
                  return Column(
                    children: [
                      _buildDetailRow('Table', _displayTableNumber),
                      _buildDetailRow('Heure', TimeOfDay.now().format(context)),
                      _buildDetailRow(
                        'Total',
                        '${order.total.toStringAsFixed(2)} €',
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _lightText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_status == OrderStatus.cancelled) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _error.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: _error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commande annulée',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Si vous aviez déjà effectué le paiement, un remboursement sera traité automatiquement sous 3 à 5 jours ouvrés.',
              style: TextStyle(
                fontSize: 13,
                color: _lightText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(
                        restaurantId: widget.restaurantId,
                        tableNumber: widget.tableNumber,
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'NOUVELLE COMMANDE',
                  style: TextStyle(
                    color: _white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pour les commandes terminées
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MenuScreen(
                  restaurantId: widget.restaurantId,
                  tableNumber: widget.tableNumber,
                ),
              ),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'NOUVELLE COMMANDE',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusImageUrl() {
    switch (_status) {
      case OrderStatus.pending:
        return 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400&q=80';
      case OrderStatus.preparing:
        return 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=400&q=80';
      case OrderStatus.ready:
        return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80';
      case OrderStatus.completed:
        return 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80';
      case OrderStatus.cancelled:
        return 'https://images.unsplash.com/photo-1495195134817-aeb325a55b65?w=400&q=80';
    }
  }

  String _getStatusIcon() {
    switch (_status) {
      case OrderStatus.pending:
        return '📋';
      case OrderStatus.preparing:
        return '🍳';
      case OrderStatus.ready:
        return '✅';
      case OrderStatus.completed:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  String _getStatusLabel() {
    switch (_status) {
      case OrderStatus.pending:
        return 'EN ATTENTE';
      case OrderStatus.preparing:
        return 'EN PRÉPARATION';
      case OrderStatus.ready:
        return 'PRÊTE';
      case OrderStatus.completed:
        return 'SERVIE';
      case OrderStatus.cancelled:
        return 'ANNULÉE';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case OrderStatus.pending:
        return _primaryOrange;
      case OrderStatus.preparing:
        return _primaryOrange;
      case OrderStatus.ready:
        return _success;
      case OrderStatus.completed:
        return _success;
      case OrderStatus.cancelled:
        return _error;
    }
  }

  String _getMainTitle() {
    switch (_status) {
      case OrderStatus.pending:
        return 'Commande reçue';
      case OrderStatus.preparing:
        return 'Votre festin arrive...';
      case OrderStatus.ready:
        return 'C\'est prêt !';
      case OrderStatus.completed:
        return 'Bon appétit !';
      case OrderStatus.cancelled:
        return 'Commande annulée';
    }
  }

  String _getMainDescription() {
    switch (_status) {
      case OrderStatus.pending:
        return 'Nous avons bien reçu votre commande et elle est en cours de validation.';
      case OrderStatus.preparing:
        return 'Le chef apporte la touche finale à votre sélection.';
      case OrderStatus.ready:
        return 'Votre commande est prête et sera servie dans quelques instants.';
      case OrderStatus.completed:
        return 'Votre commande a été servie. Profitez de votre repas !';
      case OrderStatus.cancelled:
        return 'Votre commande a été annulée. Contactez le restaurant pour plus d\'informations.';
    }
  }
}
