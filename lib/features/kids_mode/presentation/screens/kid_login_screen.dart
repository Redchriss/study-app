import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

final kidTokenProvider = StateProvider<String?>((ref) => null);
final kidProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class KidLoginScreen extends ConsumerStatefulWidget {
  const KidLoginScreen({super.key});
  @override
  ConsumerState<KidLoginScreen> createState() => _KidLoginScreenState();
}

class _KidLoginScreenState extends ConsumerState<KidLoginScreen> {
  final _parentUserCtrl = TextEditingController();
  final _parentPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _kidPinCtrl = TextEditingController();
  bool _parentLoading = false;
  bool _creatingKid = false;
  int? _newKidStandard;
  List<dynamic>? _children;
  String? _parentToken;
  String? _error;
  GraphQLClient? _client;

  GraphQLClient _buildClient({String? token}) {
    if (_client != null) return _client!;
    final t = token ?? _parentToken;
    final authLink = AuthLink(getToken: () async => t);
    final httpLink = HttpLink(AppConfig.graphqlUrl);
    _client = GraphQLClient(cache: GraphQLCache(), link: authLink.concat(httpLink));
    return _client!;
  }

  Future<void> _loginAsParent() async {
    setState(() { _parentLoading = true; _error = null; });
    final client = _buildClient();
    final result = await client.mutate(MutationOptions(
      document: gql(kTokenAuth),
      variables: {'username': _parentUserCtrl.text.trim(), 'password': _parentPassCtrl.text},
    ));
    if (result.data != null && result.data!['tokenAuth'] != null) {
      final t = result.data!['tokenAuth']['token'] as String?;
      if (t != null) {
        _parentToken = t;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('parent_token', _parentToken!);
      }
      await _fetchChildren();
    } else {
      setState(() { _error = 'Invalid credentials'; _parentLoading = false; });
    }
  }

  Future<void> _fetchChildren() async {
    final client = _buildClient();
    final result = await client.query(QueryOptions(document: gql(kMyChildren)));
    setState(() {
      _children = (result.data?['myChildren'] as List?) ?? [];
      _parentLoading = false;
    });
  }

  Future<void> _createKid() async {
    if (_nameCtrl.text.trim().isEmpty || _kidPinCtrl.text.length != 4 || _newKidStandard == null) return;
    setState(() => _creatingKid = true);
    final client = _buildClient();
    final result = await client.mutate(MutationOptions(
      document: gql(kCreateChildProfile),
      variables: {
        'childName': _nameCtrl.text.trim(),
        'standard': _newKidStandard!,
        'pinCode': _kidPinCtrl.text,
      },
    ));
    setState(() => _creatingKid = false);
    if (result.data?['createChildProfile']?['success'] == true) {
      _nameCtrl.clear(); _kidPinCtrl.clear();
      await _fetchChildren();
    }
  }

  Future<void> _loginAsKid(Map<String, dynamic> kid) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => KidPinDialog(
        kidName: kid['childName'] as String? ?? 'Kid',
        onSubmit: (pin) async {
          Navigator.pop(context);
          final client = _buildClient();
          final result = await client.mutate(MutationOptions(
            document: gql(kKidLogin),
            variables: {'username': kid['username'], 'pinCode': pin},
          ));
          final data = result.data?['kidLogin'];
          if (data?['success'] == true) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('kid_token', data['token']);
            ref.read(kidTokenProvider.notifier).state = data['token'];
            ref.read(kidProfileProvider.notifier).state = Map<String, dynamic>.from(kid);
            ref.read(kidAuthStateProvider.notifier).state = KidAuthState(
              isAuthenticated: true,
              childName: kid['childName'] as String? ?? '',
              standard: kid['standard'] as int? ?? 1,
              token: data['token'],
            );
            if (mounted) context.go('/kids/learn');
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data?['errors']?.first ?? 'Wrong PIN'), backgroundColor: DesignTokens.error),
            );
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _parentUserCtrl.dispose();
    _parentPassCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _kidPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_parentToken != null) return _buildParentDashboard();
    return Scaffold(
      appBar: AppBar(title: const Text('Yaza Kids'), centerTitle: true, backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 40),
          const Text('👋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Parent Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Log in to manage your child\'s learning', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextField(controller: _parentUserCtrl, decoration: const InputDecoration(labelText: 'Your username', prefixIcon: Icon(Icons.person)), textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          TextField(controller: _parentPassCtrl, decoration: const InputDecoration(labelText: 'Your password', prefixIcon: Icon(Icons.lock)), obscureText: true, textInputAction: TextInputAction.done),
          if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: DesignTokens.error))],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _parentLoading ? null : _loginAsParent,
              child: _parentLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Log In'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () {}, child: const Text('Don\'t have an account? Register', style: TextStyle(color: DesignTokens.textSecondary))),
        ]),
      ),
    );
  }

  Widget _buildParentDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kids'),
        centerTitle: true,
        backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateKidDialog()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() { _parentToken = null; _children = null; })),
        ],
      ),
      body: _children == null
          ? const Center(child: CircularProgressIndicator())
          : _children!.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.child_care, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No kids added yet', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add a Child'),
                      onPressed: () => _showCreateKidDialog(),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _children!.length,
                  itemBuilder: (_, i) {
                    final kid = _children![i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF27AE60).withValues(alpha: 0.15),
                          child: Text((kid['childName'] as String? ?? '?')[0], style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF27AE60))),
                        ),
                        title: Text(kid['childName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Standard ${kid['standard'] ?? '?'}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _loginAsKid(kid),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCreateKidDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Add a Child'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Child\'s name', isDense: true)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _newKidStandard,
                decoration: const InputDecoration(labelText: 'Standard', isDense: true),
                items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Standard ${i + 1}'))),
                onChanged: (v) => setDState(() => _newKidStandard = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: _kidPinCtrl, decoration: const InputDecoration(labelText: '4-digit PIN', helperText: 'Kid uses this to log in', isDense: true), keyboardType: TextInputType.number, maxLength: 4),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _creatingKid ? null : () { Navigator.pop(ctx); _createKid(); },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class KidPinDialog extends StatefulWidget {
  final String kidName;
  final Function(String) onSubmit;
  const KidPinDialog({super.key, required this.kidName, required this.onSubmit});
  @override
  State<KidPinDialog> createState() => _KidPinDialogState();
}

class _KidPinDialogState extends State<KidPinDialog> {
  final _pin = <String>[];
  String _error = '';

  void _press(String d) {
    if (_pin.length >= 4) return;
    setState(() { _pin.add(d); _error = ''; });
    if (_pin.length == 4) widget.onSubmit(_pin.join(''));
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hi ${widget.kidName}!'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter your PIN'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Container(
            width: 50, height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: i < _pin.length ? const Color(0xFF27AE60) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(i < _pin.length ? '●' : '○', style: TextStyle(color: i < _pin.length ? Colors.white : Colors.grey[400], fontSize: 24))),
          )),
        ),
        if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: DesignTokens.error, fontSize: 13))],
        const SizedBox(height: 20),
        ...['123', '456', '789'].map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.split('').map((d) => GestureDetector(
              onTap: () => _press(d),
              child: Container(
                width: 64, height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: Center(child: Text(d, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600))),
              ),
            )).toList(),
          ),
        )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72 + 16),
            GestureDetector(
              onTap: _delete,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: const Icon(Icons.backspace_outlined, color: Colors.grey),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

// Auth state for kid mode
class KidAuthState {
  final bool isAuthenticated;
  final String childName;
  final int standard;
  final String? token;
  const KidAuthState({this.isAuthenticated = false, this.childName = '', this.standard = 1, this.token});
}

final kidAuthStateProvider = StateProvider<KidAuthState>((ref) => const KidAuthState());
