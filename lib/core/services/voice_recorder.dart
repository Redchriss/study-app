import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Voice recorder for AI Tutor voice input.
/// Records audio → sends to backend → returns transcribed text.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;
  Uint8List? _recordedBytes;

  bool get isRecording => _isRecording;

  /// Start recording audio.
  Future<bool> start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }

      _recordedBytes = null;

      // Record directly to bytes
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // NIM prefers 16kHz
        numChannels: 1,
      ));

      // Collect all chunks
      final chunks = <Uint8List>[];
      stream.listen(
        (data) => chunks.add(data),
        onDone: () {
          _recordedBytes = Uint8List(chunks.fold<int>(0, (sum, e) => sum + e.length));
          final full = Uint8List(_recordedBytes!.length);
          int offset = 0;
          for (final chunk in chunks) {
            full.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }
          _recordedBytes = full;
        },
      );

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

      if (_recordedBytes == null || _recordedBytes!.length < 100) {
        debugPrint('❌ Recording too short');
        return null;
      }

      return base64Encode(_recordedBytes!);
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
