import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'menu_screen.dart';

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
  late AnimationController _progressController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;

  OrderStatus _status = OrderStatus.pending;
  bool _isStreamActive = true;
  NotificationService? _notificationService;

  final Map<OrderStatus, String> _estimatedTime = {
    OrderStatus.pending: '~15 min',
    OrderStatus.preparing: '~10 min',
    OrderStatus.ready: 'Maintenant',
    OrderStatus.completed: 'Finalisée',
    OrderStatus.cancelled: '-',
  };

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: _statusToProgress(OrderStatus.pending)).animate(
      CurvedAnimation(parent: _progressController, curve: AppTheme.defaultCurve),
    );

    _progressController.forward();
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

    // Démarrer le service de notifications
    _notificationService = NotificationService();
    _notificationService!.startListening(statusStream, context);
  }

  void _onStatusChanged(OrderStatus newStatus) {
    if (newStatus == _status) return;

    setState(() => _status = newStatus);

    final targetProgress = _statusToProgress(newStatus);
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: targetProgress,
    ).animate(CurvedAnimation(
        parent: _progressController, curve: AppTheme.defaultCurve));

    _progressController
      ..reset()
      ..forward();

    _stepController
      ..reset()
      ..forward();

    if (newStatus == OrderStatus.ready || newStatus == OrderStatus.completed || newStatus == OrderStatus.cancelled) {
      _pulseController.stop();
      _pulseController.animateTo(1.0);
    }
  }

  double _statusToProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.15;
      case OrderStatus.preparing:
        return 0.55;
      case OrderStatus.ready:
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    _notificationService?.stopListening();
    _pulseController.dispose();
    _progressController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SUIVI DE COMMANDE'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isStreamActive)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildLiveIndicator(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            _buildOrderInfoBar(),
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 32),
            _buildProgressBar(),
            const SizedBox(height: 32),
            _buildStepsTimeline(),
            const SizedBox(height: 32),
            _buildInfoGrid(),
            if (_status == OrderStatus.ready || _status == OrderStatus.completed || _status == OrderStatus.cancelled) ...[
              const SizedBox(height: 40),
              _buildActionButtons(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'RÉFÉRENCE: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textLight, letterSpacing: 1),
          ),
          Text(
            '#${widget.orderId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 1),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 12, color: AppTheme.divider),
          const SizedBox(width: 16),
          Text(
            TimeOfDay.now().format(context),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: (_status != OrderStatus.ready && _status != OrderStatus.completed && _status != OrderStatus.cancelled) ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: _getStatusGradient(),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(_getStatusEmoji(), style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _status.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROGRESSION',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Text(
                '${(_progressAnim.value * 100).round()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _getStatusColor()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: _progressAnim.value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_getStatusColor(), _getStatusColor().withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: _getStatusColor().withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsTimeline() {
    final steps = [OrderStatus.pending, OrderStatus.preparing, OrderStatus.ready];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isDone = _status.step > step.step;
          final isCurrent = _status.step == step.step;
          final isLast = index == steps.length - 1;

          return _buildTimelineItem(
            step: step,
            isDone: isDone,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem({
    required OrderStatus step,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isDone ? AppTheme.success : isCurrent ? _getStatusColor() : AppTheme.textLight;

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: AppTheme.fastAnim,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: (isDone || isCurrent) ? color : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    boxShadow: (isDone || isCurrent) ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : isCurrent
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                            : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? AppTheme.success : AppTheme.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                      color: (isDone || isCurrent) ? AppTheme.textPrimary : AppTheme.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepDescription(step),
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.table_bar_rounded,
            label: 'TABLE',
            value: widget.tableNumber,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.timer_outlined,
            label: 'ESTIMATION',
            value: _estimatedTime[_status] ?? '-',
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Si la commande est annulée, afficher des actions spécifiques
    if (_status == OrderStatus.cancelled) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.error),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Nous sommes désolés pour ce désagrément.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Si vous aviez déjà effectué le paiement, un remboursement sera traité automatiquement sous 3 à 5 jours ouvrés sur votre moyen de paiement.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  AppFeedback.showInfo(
                    context,
                    'Fonctionnalité de contact en cours de développement.',
                  );
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('CONTACTER LE RESTAURANT'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
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
                child: const Text('NOUVELLE COMMANDE'),
              ),
            ),
          ],
        ),
      );
    }

    // Pour les commandes terminées ou prêtes
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Besoin d\'autre chose ? Vous pouvez commander à nouveau à tout moment.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
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
              child: const Text('NOUVELLE COMMANDE'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case OrderStatus.pending: return const Color(0xFFC5A059);
      case OrderStatus.preparing: return AppTheme.primary;
      case OrderStatus.ready:
      case OrderStatus.completed: return AppTheme.success;
      case OrderStatus.cancelled: return AppTheme.error;
    }
  }

  LinearGradient _getStatusGradient() {
    switch (_status) {
      case OrderStatus.pending: return AppTheme.goldGradient;
      case OrderStatus.preparing: return AppTheme.primaryGradient;
      case OrderStatus.ready:
      case OrderStatus.completed: return const LinearGradient(colors: [Color(0xFF3E5A3E), Color(0xFF2D422D)]);
      case OrderStatus.cancelled: return const LinearGradient(colors: [Color(0xFF9B2C2C), Color(0xFF720D0D)]);
    }
  }

  String _getStatusEmoji() {
    switch (_status) {
      case OrderStatus.pending: return '⚖️';
      case OrderStatus.preparing: return '🔥';
      case OrderStatus.ready:
      case OrderStatus.completed: return '✨';
      case OrderStatus.cancelled: return '🚫';
    }
  }

  String _getStatusDescription() {
    switch (_status) {
      case OrderStatus.pending: return 'Nous avons bien reçu votre demande\net elle est en cours de validation.';
      case OrderStatus.preparing: return 'Le Chef et sa brigade s\'occupent\nde votre commande en cuisine.';
      case OrderStatus.ready:
      case OrderStatus.completed: return 'Votre commande est prête à être servie.\nExcellente dégustation.';
      case OrderStatus.cancelled: return 'Votre commande a été annulée par le restaurant.\n\nSi vous aviez déjà payé, un remboursement\nsera effectué sous 3-5 jours ouvrés.\n\nContactez le restaurant pour plus d\'informations.';
    }
  }

  String _getStepDescription(OrderStatus step) {
    switch (step) {
      case OrderStatus.pending: return 'Validation par l\'établissement';
      case OrderStatus.preparing: return 'Préparation gastronomique';
      case OrderStatus.ready: return 'Service imminent à votre table';
      case OrderStatus.completed: return 'Expérience finalisée';
      case OrderStatus.cancelled: return 'Commande interrompue';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textLight, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}