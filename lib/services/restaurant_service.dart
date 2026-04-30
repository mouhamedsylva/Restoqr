import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RestaurantTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final String buttonStyle;
  final String currency;
  final String language;
  final bool isTaxIncluded;
  final double taxRate;

  const RestaurantTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonStyle,
    required this.currency,
    required this.language,
    required this.isTaxIncluded,
    required this.taxRate,
  });

  factory RestaurantTheme.fromJson(Map<String, dynamic> json) {
    // Parser les couleurs hexadécimales
    Color parseColor(String? hex, Color defaultColor) {
      if (hex == null || hex.isEmpty) return defaultColor;
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (e) {
        return defaultColor;
      }
    }

    return RestaurantTheme(
      primaryColor: parseColor(json['primaryColor'], const Color(0xFFFF6B35)),
      secondaryColor: parseColor(json['secondaryColor'], const Color(0xFF2C3E50)),
      buttonStyle: json['buttonStyle'] ?? 'rounded',
      currency: json['currency'] ?? 'EUR',
      language: json['language'] ?? 'fr',
      isTaxIncluded: json['isTaxIncluded'] ?? false,
      taxRate: json['taxRate'] != null 
        ? double.tryParse(json['taxRate'].toString()) ?? 0.10 
        : 0.10,
    );
  }
}

class RestaurantService {
  RestaurantTheme? _cachedTheme;
  Map<String, dynamic>? _cachedInfo;

  /// Récupère les informations complètes du restaurant
  Future<Map<String, dynamic>> getRestaurantInfo(String restaurantId) async {
    if (_cachedInfo != null) return _cachedInfo!;

    try {
      // Essayer d'abord l'endpoint basic (plus simple, moins de risque d'erreur)
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurants/$restaurantId/basic'),
      );

      if (response.statusCode == 200) {
        _cachedInfo = jsonDecode(response.body);
        debugPrint('✅ Restaurant info loaded (basic): ${_cachedInfo!['name']}');
        return _cachedInfo!;
      } else {
        debugPrint('❌ Error loading restaurant (basic): ${response.statusCode}');
        throw Exception('Erreur de chargement du restaurant');
      }
    } catch (e) {
      debugPrint('❌ Exception loading restaurant: $e');
      throw Exception('Erreur de chargement du restaurant');
    }
  }

  /// Récupère le thème personnalisé du restaurant
  Future<RestaurantTheme> getRestaurantTheme(String restaurantId) async {
    if (_cachedTheme != null) return _cachedTheme!;

    final info = await getRestaurantInfo(restaurantId);
    _cachedTheme = RestaurantTheme.fromJson(info);
    return _cachedTheme!;
  }

  /// Efface le cache (utile pour rafraîchir)
  void clearCache() {
    _cachedTheme = null;
    _cachedInfo = null;
  }
}
