import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final wordMatchPairSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WordMatchPair']),
    'pairs': S.list(
      description: 'Exactly 3 or 4 pairs',
      items: S.object(properties: {
        'left': S.string(description: 'Word or phrase on the left side'),
        'right':
            S.string(description: 'Matching definition, translation, or value'),
      }),
    ),
    'matchCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when all pairs are correctly matched',
    ),
  },
  required: ['component', 'pairs', 'matchCompleteAction'],
);

const _palette = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
];

class _MatchPair {
  final String left;
  final String right;

  _MatchPair({required this.left, required this.right});

  factory _MatchPair.fromJson(Map<String, Object?> json) {
    return _MatchPair(
      left: (json['left'] as String?) ?? '',
      right: (json['right'] as String?) ?? '',
    );
  }
}

class _WordMatchPairData {
  final List<_MatchPair> pairs;
  final String actionName;
  final JsonMap actionContext;

  _WordMatchPairData({
    required this.pairs,
    required this.actionName,
    required this.actionContext,
  });

  factory _WordMatchPairData.fromJson(Map<String, Object?> json) {
    final action = json['matchCompleteAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final pairsRaw = json['pairs'] as List<dynamic>?;
    return _WordMatchPairData(
      pairs: pairsRaw
              ?.map((e) => _MatchPair.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      actionName: (event?['name'] as String?) ?? 'match_complete',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }

  List<String> get shuffledLeft {
    final items = pairs.map((p) => p.left).toList()..shuffle();
    return items;
  }

  List<String> get shuffledRight {
    final items = pairs.map((p) => p.right).toList()..shuffle();
    return items;
  }
}

class _WordMatchPairWidget extends StatefulWidget {
  final _WordMatchPairData data;
  final VoidCallback onComplete;

  const _WordMatchPairWidget({required this.data, required this.onComplete});

  @override
  State<_WordMatchPairWidget> createState() => _WordMatchPairWidgetState();
}

class _WordMatchPairWidgetState extends State<_WordMatchPairWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;

  final List<String> _shuffledLeft = [];
  final List<String> _shuffledRight = [];
  final Map<String, int> _matchedIndices = {};
  String? _selectedLeft;
  int? _selectedLeftIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _shuffledLeft.addAll(widget.data.shuffledLeft);
    _shuffledRight.addAll(widget.data.shuffledRight);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _pairIndexForLeft(String left) {
    return widget.data.pairs.indexWhere((p) => p.left == left);
  }

  int _pairIndexForRight(String right) {
    return widget.data.pairs.indexWhere((p) => p.right == right);
  }

  String _rightForLeft(String left) {
    final idx = widget.data.pairs.indexWhere((p) => p.left == left);
    if (idx == -1) return '';
    return widget.data.pairs[idx].right;
  }

  void _selectLeft(String item, int index) {
    if (_matchedIndices.containsKey(item)) return;
    setState(() {
      _selectedLeft = item;
      _selectedLeftIndex = index;
    });
  }

  void _selectRight(String item) {
    if (_selectedLeft == null) return;
    if (_matchedIndices.values.any(
        (v) => v == widget.data.pairs.indexWhere((p) => p.right == item))) {
      return;
    }

    final pairIdx = _pairIndexForRight(item);
    final expectedRight = _rightForLeft(_selectedLeft!);

    if (item == expectedRight) {
      setState(() {
        _matchedIndices[_selectedLeft!] = pairIdx;
        _selectedLeft = null;
        _selectedLeftIndex = null;
      });
      if (_matchedIndices.length == widget.data.pairs.length) {
        widget.onComplete();
      }
    } else {
      setState(() {
        _selectedLeft = null;
        _selectedLeftIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildColumn(
                _shuffledLeft,
                _selectedLeftIndex,
                true,
                theme,
                cs,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildColumn(
                _shuffledRight,
                null,
                false,
                theme,
                cs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(
    List<String> items,
    int? selectedIndex,
    bool isLeft,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isMatched = _matchedIndices.containsKey(item) ||
            _matchedIndices.values.any((v) =>
                v == widget.data.pairs.indexWhere((p) => p.right == item));
        final pairIdx =
            isLeft ? _pairIndexForLeft(item) : _pairIndexForRight(item);
        final color =
            isMatched ? _palette[pairIdx % _palette.length] : cs.surface;

        return GestureDetector(
          onTap: () {
            if (isMatched) return;
            if (isLeft) {
              _selectLeft(item, i);
            } else {
              _selectRight(item);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: isMatched
                  ? color.withValues(alpha: 0.2)
                  : (selectedIndex == i && isLeft
                      ? cs.primaryContainer
                      : cs.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMatched
                    ? color
                    : (selectedIndex == i && isLeft
                        ? cs.primary
                        : cs.outlineVariant),
                width: isMatched || selectedIndex == i ? 2 : 1,
              ),
            ),
            child: Text(
              item,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isMatched ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }),
    );
  }
}

final wordMatchPairItem = CatalogItem(
  name: 'WordMatchPair',
  dataSchema: wordMatchPairSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _WordMatchPairData.fromJson(json);
    return _WordMatchPairWidget(
      data: data,
      onComplete: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
