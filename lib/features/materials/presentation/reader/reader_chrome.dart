import 'package:flutter/material.dart';

class ReaderScaffold extends StatelessWidget {
  const ReaderScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.actions = const <Widget>[],
    this.bottomBar,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final List<Widget> actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          ...actions,
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: trailing),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: child),
          if (bottomBar != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: bottomBar!,
            ),
        ],
      ),
    );
  }
}

class ReaderPageBadge extends StatelessWidget {
  const ReaderPageBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ReaderTag extends StatelessWidget {
  const ReaderTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ReaderTip extends StatelessWidget {
  const ReaderTip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class ReaderActionBar extends StatelessWidget {
  const ReaderActionBar({
    super.key,
    required this.onNote,
    required this.onQuickQuiz,
    required this.onFlashcards,
    this.onAskAi,
  });

  final VoidCallback onNote;
  final VoidCallback onQuickQuiz;
  final VoidCallback onFlashcards;
  final VoidCallback? onAskAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ReaderActionChip(
            label: 'Highlight',
            icon: Icons.draw_outlined,
            onPressed: onNote,
          ),
          _ReaderActionChip(
            label: 'Mini Quiz',
            icon: Icons.quiz_outlined,
            onPressed: onQuickQuiz,
          ),
          _ReaderActionChip(
            label: 'Flashcards',
            icon: Icons.style_outlined,
            onPressed: onFlashcards,
          ),
          if (onAskAi != null)
            _ReaderActionChip(
              label: 'Ask AI',
              icon: Icons.auto_awesome,
              emphasized: true,
              onPressed: onAskAi!,
            ),
        ],
      ),
    );
  }
}

class _ReaderActionChip extends StatelessWidget {
  const _ReaderActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? Colors.black : Colors.white;
    final background = emphasized
        ? const Color(0xFFEFCB74)
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
