import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MaterialCacheService {
  static const _materialsListKey = 'cache_materials_list';
  static const _materialPrefix = 'cache_material_';

  Future<void> saveMaterialsList(List<dynamic> materials) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = materials
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    await prefs.setString(_materialsListKey, jsonEncode(normalized));
  }

  Future<List<Map<String, dynamic>>> loadMaterialsList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_materialsListKey);
    if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> saveMaterial(String slug, Map<String, dynamic> material) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_materialPrefix$slug', jsonEncode(material));
  }

  Future<Map<String, dynamic>?> loadMaterial(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_materialPrefix$slug');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
}
