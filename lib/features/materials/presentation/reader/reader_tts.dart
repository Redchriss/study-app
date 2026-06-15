import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech helper for reading study materials aloud.
/// Uses flutter_tts which is already in pubspec.yaml.
class ReaderTts {
  static FlutterTts? _tts;
  static bool _speaking = false;

  static Future<FlutterTts> _getInstance() async {
    if (_tts != null) return _tts!;
    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.4);
    await _tts!.setPitch(1.0);
    await _tts!.setVolume(1.0);
    _tts!.setCompletionHandler(() => _speaking = false);
    _tts!.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _speaking = false;
    });
    return _tts!;
  }

  static bool get isSpeaking => _speaking;

  /// Start reading text aloud. Returns true if started successfully.
  static Future<bool> speak(String text) async {
    if (text.isEmpty) return false;
    try {
      final tts = await _getInstance();
      await tts.stop();
      _speaking = true;
      await tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _speaking = false;
      return false;
    }
  }

  /// Stop reading.
  static Future<void> stop() async {
    try {
      final tts = await _getInstance();
      await tts.stop();
      _speaking = false;
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
  }

  /// Toggle play/pause. Returns new state (true = speaking).
  static Future<bool> toggle(String text) async {
    if (_speaking) {
      await stop();
      return false;
    } else {
      await speak(text);
      return true;
    }
  }

  /// Clean up resources.
  static Future<void> dispose() async {
    await stop();
    _tts = null;
  }
}
