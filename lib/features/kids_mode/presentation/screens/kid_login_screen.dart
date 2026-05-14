import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kids_playful_button.dart';

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
  final _kidPinCtrl = TextEditingController();
  bool _parentLoading = false;
  bool _creatingKid = false;
  int? _newKidStandard;
  String _newKidEducationTrack = 'primary';
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

  void _logoutParent() {
    setState(() {
      _parentToken = null;
      _children = null;
      _client = null;
    });
  }

  Future<void> _loginAsParent() async {
    setState(() {
      _parentLoading = true;
      _error = null;
    });
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
      setState(() {
        _error = 'Invalid credentials';
        _parentLoading = false;
      });
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
        'educationTrack': _newKidEducationTrack,
      },
    ));
    setState(() => _creatingKid = false);
    if (result.data?['createChildProfile']?['success'] == true) {
      _nameCtrl.clear();
      _kidPinCtrl.clear();
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
            final child = data['child'] as Map<String, dynamic>?;
            ref.read(kidProfileProvider.notifier).state = Map<String, dynamic>.from(kid);
            ref.read(kidAuthStateProvider.notifier).state = KidAuthState(
              isAuthenticated: true,
              childName: child?['childName'] as String? ?? kid['childName'] as String? ?? '',
              standard: (child?['standard'] as num?)?.toInt() ?? kid['standard'] as int? ?? 1,
              educationTrack: child?['childEducationTrack'] as String? ?? 'primary',
              token: data['token'],
            );
            if (mounted) context.go('/kids/learn');
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data?['errors']?.first ?? 'Wrong PIN'),
                  backgroundColor: DesignTokens.error,
                ),
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
    _kidPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_parentToken != null) return _buildParentDashboard(theme);
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Yaza Kids'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.go('/home'),
              tooltip: 'Back to Yaza',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: DesignTokens.shadowSm(theme.brightness == Brightness.dark),
                      ),
                      child: const Icon(Icons.family_restroom_rounded, size: 52, color: KidsVisualTheme.pathBlue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Parent sign-in',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: KidsVisualTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the same username and password as your Yaza account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: KidsVisualTheme.inkMuted.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: KidsVisualTheme.pathBlue.withValues(alpha: 0.12),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _parentUserCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _parentPassCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _loginAsParent(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: DesignTokens.error, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 22),
                        KidsPlayfulPrimaryButton(
                          label: _parentLoading ? 'Please wait…' : 'Continue',
                          onTap: _parentLoading ? null : _loginAsParent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Yaza', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentDashboard(ThemeData theme) {
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Who is learning?'),
            actions: [
              IconButton(
                tooltip: 'Add child',
                onPressed: () => _showCreateKidDialog(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: KidsVisualTheme.pathBlue),
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: _logoutParent,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded, color: KidsVisualTheme.inkMuted),
                ),
              ),
            ],
          ),
          body: _children == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _children!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: DesignTokens.shadowSm(theme.brightness == Brightness.dark),
                              ),
                              child: Icon(Icons.child_friendly_rounded, size: 64, color: KidsVisualTheme.pathBlue.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Add your first learner',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Create a profile and PIN so your child can open Yaza Kids on their own.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),
                            KidsPlayfulPrimaryButton(
                              label: 'Add a child',
                              icon: Icons.add_rounded,
                              onTap: () => _showCreateKidDialog(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _children!.length,
                      itemBuilder: (_, i) {
                        final kid = _children![i] as Map<String, dynamic>;
                        final name = kid['childName'] as String? ?? 'Learner';
                        final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _loginAsKid(kid);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: KidsVisualTheme.ctaGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: KidsVisualTheme.chunkyShadow(const Color(0xFF2A8F4A), dy: 3),
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: KidsVisualTheme.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            kid['childEducationTrack'] == 'ecd'
                                                ? 'Early childhood · Std ${kid['standard'] ?? '?'}'
                                                : 'Primary · Std ${kid['standard'] ?? '?'}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: KidsVisualTheme.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_fill_rounded, color: KidsVisualTheme.pathBlue, size: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  void _showCreateKidDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add a learner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Child\'s name', isDense: true),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _newKidEducationTrack,
                  decoration: const InputDecoration(
                    labelText: 'Learning track',
                    helperText: 'ECD uses infant-friendly subjects; progress is kept separate',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'primary', child: Text('Primary (Std 1–8)')),
                    DropdownMenuItem(value: 'ecd', child: Text('Early childhood (pre–Std 1)')),
                  ],
                  onChanged: (v) => setDState(() => _newKidEducationTrack = v ?? 'primary'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _newKidStandard,
                  decoration: const InputDecoration(labelText: 'Standard', isDense: true),
                  items: List.generate(
                    8,
                    (i) => DropdownMenuItem(value: i + 1, child: Text('Standard ${i + 1}')),
                  ),
                  onChanged: (v) => setDState(() => _newKidStandard = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kidPinCtrl,
                  decoration: const InputDecoration(
                    labelText: '4-digit PIN',
                    helperText: 'Your child uses this to sign in',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: _creatingKid
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _createKid();
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class KidPinDialog extends StatefulWidget {
  const KidPinDialog({super.key, required this.kidName, required this.onSubmit});

  final String kidName;
  final Future<void> Function(String) onSubmit;

  @override
  State<KidPinDialog> createState() => _KidPinDialogState();
}

class _KidPinDialogState extends State<KidPinDialog> {
  final _pin = <String>[];

  Future<void> _submit(String pin) async {
    await widget.onSubmit(pin);
  }

  void _press(String d) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.add(d));
    if (_pin.length == 4) {
      _submit(_pin.join(''));
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(gradient: KidsVisualTheme.ctaGradient),
            child: Column(
              children: [
                Text(
                  'Hi, ${widget.kidName}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your secret PIN',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i < _pin.length ? KidsVisualTheme.trailGreen : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i < _pin.length ? Colors.white : Colors.grey.shade400,
                          width: 2,
                        ),
                        boxShadow: i < _pin.length
                            ? [BoxShadow(color: KidsVisualTheme.trailGreen.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          i < _pin.length ? '•' : '○',
                          style: TextStyle(
                            color: i < _pin.length ? Colors.white : Colors.grey.shade500,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...['123', '456', '789'].map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.split('').map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Material(
                            color: Colors.grey.shade100,
                            shape: const CircleBorder(),
                            elevation: 0,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _press(d),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 76),
                    Material(
                      color: Colors.grey.shade100,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _press('0'),
                        child: const SizedBox(
                          width: 64,
                          height: 64,
                          child: Center(child: Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Material(
                        color: Colors.orange.shade50,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _delete,
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Icon(Icons.backspace_outlined, color: Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KidAuthState {
  final bool isAuthenticated;
  final String childName;
  final int standard;
  final String educationTrack;
  final String? token;
  const KidAuthState({
    this.isAuthenticated = false,
    this.childName = '',
    this.standard = 1,
    this.educationTrack = 'primary',
    this.token,
  });
}

final kidAuthStateProvider = StateProvider<KidAuthState>((ref) => const KidAuthState());
