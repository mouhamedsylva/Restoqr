import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TableService {
  /// Récupère les informations d'une table par son ID
  Future<Map<String, dynamic>?> getTableInfo(String tableId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tables/$tableId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos de la table: $e');
      return null;
    }
  }

  /// Extrait le numéro de table depuis les informations
  String getTableNumber(Map<String, dynamic>? tableInfo, String fallbackId) {
    if (tableInfo != null && tableInfo['number'] != null) {
      return tableInfo['number'].toString();
    }
    // Fallback: extraire les 8 premiers caractères de l'UUID
    if (fallbackId.length > 8 && fallbackId.contains('-')) {
      return fallbackId.substring(0, 8).toUpperCase();
    }
    return fallbackId;
  }
}
