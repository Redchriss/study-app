import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static const _appFolder = 'Yaza';

  static Future<String?> downloadFile(String url, String fileName) async {
    try {
      final dir = await _getDownloadDir();
      if (dir == null) return null;

      final file = File('${dir.path}/${_sanitize(fileName)}');
      if (await file.exists()) return file.path;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('Download failed: $e');
      return null;
    }
  }

  static Future<Directory?> _getDownloadDir() async {
    if (Platform.isAndroid) {
      final public = Directory('/storage/emulated/0/Download/$_appFolder');
      try {
        if (!await public.exists()) await public.create(recursive: true);
        return public;
      } catch (_) {}
      final fallback = Directory('${(await getApplicationDocumentsDirectory()).path}/$_appFolder');
      if (!await fallback.exists()) await fallback.create(recursive: true);
      return fallback;
    }
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$_appFolder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
