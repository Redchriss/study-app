import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/widgets.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kids_home_state_provider.dart';

class KidsHomeRedirect extends StatelessWidget {
  const KidsHomeRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Redirecting...')));
  }
}

class KidsHomeLoading extends ConsumerWidget {
  final VoidCallback? onFetchSubjects;

  const KidsHomeLoading({super.key, this.onFetchSubjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kidsHomeStateProvider);
    if (!state.subjectFetchStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            !state.fetchedSubjects &&
            !state.subjectFetchStarted) {
          onFetchSubjects?.call();
        }
      });
    }
    final theme = Theme.of(context);
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: LoadingWidget(),
        ),
      ),
    );
  }
}
