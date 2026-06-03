import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class OrderingList extends StatefulWidget {
  final List<dynamic> options;
  final ValueChanged<String> onOrder;

  const OrderingList({
    super.key,
    required this.options,
    required this.onOrder,
  });

  @override
  State<OrderingList> createState() => _OrderingListState();
}

class _OrderingListState extends State<OrderingList> {
  late List<String> _orderedIds;
  bool _initialized = false;

  void _initOrdered() {
    if (!_initialized) {
      _orderedIds = widget.options
          .map((o) => o['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList()
        ..shuffle();
      _initialized = true;
    }
  }

  void _onReorder(int oldIdx, int newIdx) {
    setState(() {
      if (newIdx >= _orderedIds.length) newIdx = _orderedIds.length - 1;
      final id = _orderedIds.removeAt(oldIdx);
      _orderedIds.insert(newIdx, id);
    });
    widget.onOrder(_orderedIds.join(','));
  }

  @override
  void didUpdateWidget(OrderingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _orderedIds = [];
      _initialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _initOrdered();
    return ReorderableListView.builder(
      itemCount: _orderedIds.length,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final id = _orderedIds[i];
        final opt = widget.options.firstWhere(
          (o) => o['id'] == id,
          orElse: () => {'answerText': ''},
        );
        return Container(
          key: ValueKey(id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark ? DesignTokens.darkBorder : DesignTokens.border,
            ),
          ),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: i,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.drag_handle,
                    size: 16, color: DesignTokens.primary),
              ),
            ),
            title: Text(
              '${i + 1}. ${opt['answerText'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
