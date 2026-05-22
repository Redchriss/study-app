import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kid_create_learner_sheet.dart';
import '../widgets/kid_login_dashboard.dart';
import '../widgets/kid_login_manager.dart';
import '../widgets/kids_playful_button.dart';

class KidLoginScreen extends ConsumerStatefulWidget {
  const KidLoginScreen({super.key});
  @override
  ConsumerState<KidLoginScreen> createState() => _KidLoginScreenState();
}

class _KidLoginScreenState extends ConsumerState<KidLoginScreen> {
  final _mgr = KidLoginManager();

  @override
  void initState() {
    super.initState();
    _mgr.attach(
        ref: ref,
        setState: setState,
        getContext: () => context,
        isMounted: () => mounted);
    _mgr.restoreSavedSession();
  }

  @override
  void dispose() {
    _mgr.dispose();
    super.dispose();
  }

  void _showCreateKidDialog() {
    _mgr.newKidAvatar = '🦊';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KidCreateLearnerSheet(
        existingAvatar: _mgr.newKidAvatar,
        onCreate: (
            {required name,
            required pin,
            required avatar,
            required educationTrack,
            required standard}) {
          _mgr.nameCtrl.text = name;
          _mgr.kidPinCtrl.text = pin;
          _mgr.newKidAvatar = avatar;
          _mgr.newKidEducationTrack = educationTrack;
          _mgr.newKidStandard = standard;
          _mgr.createKid();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_mgr.parentToken != null) {
      return KidLoginDashboard(
        children: _mgr.children,
        avatars: _mgr.avatars,
        parentToken: _mgr.parentToken,
        onCreateKid: _showCreateKidDialog,
        onLoginKid: (kid) => _mgr.loginAsKid(kid),
        onLogout: () => _mgr.logoutParent(),
      );
    }
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
                        boxShadow: DesignTokens.shadowSm(
                            theme.brightness == Brightness.dark),
                      ),
                      child: const Icon(Icons.family_restroom_rounded,
                          size: 52, color: KidsVisualTheme.pathBlue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Parent sign-in',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: KidsVisualTheme.ink)),
                  const SizedBox(height: 8),
                  Text(
                      'Use the same username and password as your Yaza account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: KidsVisualTheme.inkMuted
                              .withValues(alpha: 0.95))),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: KidsVisualTheme.pathBlue
                                .withValues(alpha: 0.12),
                            offset: const Offset(0, 8),
                            blurRadius: 20)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _mgr.parentUserCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline_rounded)),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _mgr.parentPassCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded)),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _mgr.loginAsParent(),
                        ),
                        if (_mgr.error != null) ...[
                          const SizedBox(height: 10),
                          Text(_mgr.error!,
                              style: const TextStyle(
                                  color: DesignTokens.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 22),
                        KidsPlayfulPrimaryButton(
                          label: _mgr.parentLoading
                              ? 'Please wait\u2026'
                              : 'Continue',
                          onTap: _mgr.parentLoading
                              ? null
                              : () => _mgr.loginAsParent(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Yaza',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
