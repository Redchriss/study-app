import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class RegisterStepUsername extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool dark;
  final VoidCallback onContinue;

  const RegisterStepUsername({
    super.key,
    required this.formKey,
    required this.controller,
    required this.dark,
    required this.onContinue,
  });

  @override
  State<RegisterStepUsername> createState() => _RegisterStepUsernameState();
}

class _RegisterStepUsernameState extends State<RegisterStepUsername> {
  Timer? _debounce;
  bool? _available; // null=unchecked, true=available, false=taken
  bool _checking = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _available = null;
      _checking = false;
    });
    _debounce?.cancel();
    final v = value.trim();
    if (v.length < 3 || v.contains(' ')) return;
    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 600), () => _check(v));
  }

  Future<void> _check(String username) async {
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.query(QueryOptions(
        document: gql(kCheckUsername),
        variables: {'username': username},
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      if (!mounted) return;
      setState(() {
        _checking = false;
        _available = result.data?['checkUsername'] as bool?;
      });
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Widget? get _suffix {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_available == true)
      return const Icon(Icons.check_circle_rounded,
          color: DesignTokens.success, size: 22);
    if (_available == false)
      return const Icon(Icons.cancel_rounded,
          color: DesignTokens.error, size: 22);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 40, color: DesignTokens.primary),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'What should we\ncall you?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            const Text(
              'Your unique username on Yaza.',
              style: TextStyle(
                  fontSize: 15,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
            TextFormField(
              controller: widget.controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                hintText: 'e.g. kondwani265',
                suffixIcon: _suffix,
                filled: true,
                fillColor: widget.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                helperText: _available == true
                    ? 'Username is available ✓'
                    : _available == false
                        ? 'Username is already taken'
                        : null,
                helperStyle: TextStyle(
                  color: _available == true
                      ? DesignTokens.success
                      : DesignTokens.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onFieldSubmitted: (_) {
                if (_available != false) widget.onContinue();
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Username is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (v.trim().contains(' ')) return 'No spaces allowed';
                if (_available == false) return 'Username is already taken';
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
