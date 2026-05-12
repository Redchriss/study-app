import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/widgets.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  String? _sessionId;
  bool _sending = false;
  bool _streaming = false;
  String _streamingText = '';
  late final http.Client _httpClient;
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorAnim;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _cursorAnim = Tween<double>(begin: 0, end: 1).animate(_cursorCtrl);
  }

  @override
  void dispose() {
    _httpClient.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _cursorCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return SecureStorage.getToken();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    setState(() {
      _messages.add({'messageText': text, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()});
      _sending = true;
      _streaming = true;
      _streamingText = '';
    });
    _scrollDown();

    final token = await _getToken();
    if (token == null) { setState(() { _sending = false; _streaming = false; }); return; }

    try {
      final request = http.StreamedRequest('POST', Uri.parse('${AppConfig.apiUrl}/ai/stream/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.sink.add(utf8.encode(jsonEncode({
        'message': text,
        'session_id': _sessionId,
      })));
      request.sink.close();
      final response = await _httpClient.send(request);

      final lines = response.stream.transform(utf8.decoder);
      String eventType = '';
      StringBuffer dataBuffer = StringBuffer();

      await for (final chunk in lines) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
            dataBuffer = StringBuffer();
          } else if (line.startsWith('data: ')) {
            dataBuffer.write(line.substring(6));
          } else if (line.isEmpty && eventType.isNotEmpty) {
            _handleEvent(eventType, dataBuffer.toString());
            eventType = '';
            dataBuffer = StringBuffer();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _sending = false; _streaming = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection lost: $e'), backgroundColor: DesignTokens.error),
        );
      }
    }
  }

  void _handleEvent(String type, String data) {
    try {
      final payload = jsonDecode(data) as Map<String, dynamic>;
      switch (type) {
        case 'token':
          setState(() => _streamingText += payload['text'] as String? ?? '');
          _scrollDown();
          break;
        case 'done':
          setState(() {
            _messages.add({'messageText': _streamingText, 'isUser': false, 'timestamp': DateTime.now().toIso8601String()});
            _streamingText = '';
            _sending = false;
            _streaming = false;
          });
          _scrollDown();
          break;
        case 'meta':
          if (payload['session_id'] != null) _sessionId = payload['session_id'].toString();
          break;
        case 'error':
          setState(() { _sending = false; _streaming = false; _streamingText = ''; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload['message'] ?? 'Error'), backgroundColor: DesignTokens.error),
            );
          }
          break;
      }
    } catch (_) {
      debugPrint('AI Tutor: failed to parse SSE event: $type $data');
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Tutor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(() { _sessionId = null; _messages.clear(); })),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spXs),
            color: DesignTokens.primary.withValues(alpha: 0.05),
            child: const Row(children: [
              Icon(Icons.auto_awesome, size: 14, color: DesignTokens.primary),
              SizedBox(width: 6),
              Text('Powered by Gemini', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
            ]),
          ),
          Expanded(
            child: _messages.isEmpty && !_streaming
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.smart_toy_outlined, size: 80, color: DesignTokens.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: DesignTokens.spMd),
                  const Text('Ask me anything about your subjects', style: TextStyle(color: DesignTokens.textSecondary)),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  itemCount: _messages.length + (_streaming ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_streaming && i == _messages.length) {
                      return _buildAiMessage(_streamingText, true, dark);
                    }
                    final msg = _messages[i];
                    final isUser = msg['isUser'] == true;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.only(bottom: DesignTokens.spXs),
                        padding: const EdgeInsets.all(DesignTokens.spMd),
                        decoration: BoxDecoration(
                          color: isUser ? DesignTokens.primary : (dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg).copyWith(
                            bottomRight: isUser ? const Radius.circular(4) : null,
                            bottomLeft: !isUser ? const Radius.circular(4) : null,
                          ),
                        ),
                        child: Text(msg['messageText'] ?? '', style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14)),
                      ),
                    );
                  },
                ),
          ),
          if (_sending && !_streaming)
            _buildTypingIndicator(),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spSm),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spSm - 2),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sending ? null : _send(),
                  ),
                ),
                const SizedBox(width: DesignTokens.spXs),
                AnimatedPress(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(String text, bool streaming, bool dark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: DesignTokens.spXs),
        padding: const EdgeInsets.all(DesignTokens.spMd),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
            if (streaming)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: FadeTransition(
                  opacity: _cursorAnim,
                  child: Container(
                    width: 8, height: 16,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(0),
          const SizedBox(width: 4),
          _dot(200),
          const SizedBox(width: 4),
          _dot(400),
          const SizedBox(width: 6),
          const Text('Thinking', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return delay == 0
        ? const _Dot(0)
        : _Dot(delay);
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot(this.delay);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () => _ctrl.repeat(reverse: true));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: DesignTokens.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

