import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Voice recorder for AI Tutor voice input.
/// Records audio → sends to backend → returns transcribed text.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;

  bool get isRecording => _isRecording;

  /// Start recording audio to a temp file.
  Future<bool> start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }

      final dir = await getTemporaryDirectory();
      _recordedPath = '${dir.path}/yaza_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ), path: _recordedPath!);

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('❌ Recording start failed: $e');
      return false;
    }
  }

  /// Stop recording and return the audio as base64.
  /// Returns null if recording failed or was too short.
  Future<String?> stop() async {
    if (!_isRecording) return null;

    try {
      await _recorder.stop();
      _isRecording = false;

      if (_recordedPath == null || !File(_recordedPath!).existsSync()) {
        debugPrint('❌ No recording file found');
        return null;
      }

      final file = File(_recordedPath!);
      final bytes = await file.readAsBytes();
      await file.delete(); // clean up

      if (bytes.length < 100) {
        debugPrint('❌ Recording too short: ${bytes.length} bytes');
        return null;
      }

      return base64Encode(bytes);
    } catch (e) {
      debugPrint('❌ Recording stop failed: $e');
      return null;
    }
  }

  /// Send recorded audio to backend for transcription.
  /// Returns transcribed text or null on failure.
  Future<String?> transcribe(String base64Audio, String serverUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/ai/voice/transcribe/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio': base64Audio,
          'content_type': 'audio/wav',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Transcription failed: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['text'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Transcription request failed: $e');
      return null;
    }
  }

  /// Cancel recording without processing.
  Future<void> cancel() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
  }

  /// Clean up resources.
  void dispose() {
    _recorder.dispose();
  }
}
