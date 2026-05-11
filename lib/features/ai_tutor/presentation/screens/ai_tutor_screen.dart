import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

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
    final result = await client.mutate(MutationOptions(
      document: gql(kCreateChatSession),
    ));
    if (result.data != null && !mounted) return;
    _sessionId = result.data?['createChatSession']?['session']?['id'] ?? result.data?['createChatSession']?['id'];
    if (_sessionId != null) _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    final client = await ref.read(graphqlClientProvider.future);
    final result = await client.query(QueryOptions(
      document: gql(kChatMessages),
      variables: {'sessionId': _sessionId},
    ));
    if (result.data != null && mounted) {
      setState(() => _messages = ((result.data!['chatMessages'] as List?) ?? []).cast<Map<String, dynamic>>());
      _scrollDown();
    }
  }

  Future<void> _sendMessage() async {
    if (_sessionId == null || _msgCtrl.text.trim().isEmpty) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    setState(() {
      _messages.add({'messageText': text, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()});
      _sending = true;
    });
    _scrollDown();
    final client = await ref.read(graphqlClientProvider.future);
    final result = await client.mutate(MutationOptions(
      document: gql(kSendMessage),
      variables: {'sessionId': _sessionId, 'content': text},
    ));
    if (result.data != null && mounted) {
      final msg = result.data!['sendMessage']['message'];
      if (msg != null) {
        setState(() => _messages.add(Map<String, dynamic>.from(msg)));
      }
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
    if (_sessionId == null) {
      _createSession();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        centerTitle: true,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(() { _sessionId = null; _messages = []; }),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withOpacity(0.05),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Powered by Gemini', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 80, color: AppColors.primary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Ask me anything about your subjects', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final isUser = msg['isUser'] == true;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? const Radius.circular(4) : null,
                            bottomLeft: !isUser ? const Radius.circular(4) : null,
                          ),
                          border: isUser ? null : Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                        ),
                        child: Text(
                          msg['messageText'] ?? '',
                          style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
