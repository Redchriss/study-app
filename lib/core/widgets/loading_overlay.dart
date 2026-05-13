import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool visible;

  const LoadingOverlay({
    super.key,
    this.message,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: DesignTokens.spMd),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingBuilder extends StatelessWidget {
  final bool loading;
  final Widget child;
  final String? loadingMessage;

  const LoadingBuilder({
    super.key,
    required this.loading,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          LoadingOverlay(
            message: loadingMessage,
            visible: loading,
          ),
      ],
    );
  }
}
