// Stub pour mobile - ce widget n'est jamais utilisé sur mobile
import 'package:flutter/material.dart';

class StripePaymentWeb extends StatelessWidget {
  final String clientSecret;
  final double amount;
  final VoidCallback onSuccess;
  final Function(String) onError;
  final VoidCallback onCancel;

  const StripePaymentWeb({
    super.key,
    required this.clientSecret,
    required this.amount,
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Ce widget n'est jamais affiché sur mobile
    return const SizedBox.shrink();
  }
}
