import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _sessionId;
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final client = await ref.read(graphqlClientProvider.future);
    final result = await client.mutate(MutationOptions(document: gql(kCreateChatSession)));
    if (result.data != null && mounted) {
      _sessionId = result.data?['createChatSession']?['session']?['id'] ?? result.data?['createChatSession']?['id'];
      if (_sessionId != null) _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    final client = await ref.read(graphqlClientProvider.future);
    final result = await client.query(QueryOptions(document: gql(kChatMessages), variables: {'sessionId': _sessionId}));
    if (result.data != null && mounted) {
      setState(() => _messages = ((result.data!['chatMessages'] as List?) ?? []).cast<Map<String, dynamic>>());
      _scrollDown();
    }
  }

  Future<void> _send() async {
    if (_sessionId == null || _msgCtrl.text.trim().isEmpty) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    setState(() { _messages.add({'messageText': text, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()}); _sending = true; });
    _scrollDown();
    final client = await ref.read(graphqlClientProvider.future);
    final result = await client.mutate(MutationOptions(document: gql(kSendMessage), variables: {'sessionId': _sessionId, 'content': text}));
    if (result.data != null && mounted) {
      final msg = result.data!['sendMessage']['message'];
      if (msg != null) setState(() => _messages.add(Map<String, dynamic>.from(msg)));
    }
    if (mounted) setState(() => _sending = false);
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    if (_sessionId == null) _createSession();
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Tutor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [if (_messages.isNotEmpty) IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => setState(() { _sessionId = null; _messages = []; }))],
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
            child: _messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.smart_toy_outlined, size: 80, color: DesignTokens.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: DesignTokens.spMd),
                  const Text('Ask me anything about your subjects', style: TextStyle(color: DesignTokens.textSecondary)),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
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
          if (_sending) const Padding(padding: EdgeInsets.only(bottom: 4), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
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
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: DesignTokens.spXs),
                AnimatedPress(
                  onTap: _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
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
}
