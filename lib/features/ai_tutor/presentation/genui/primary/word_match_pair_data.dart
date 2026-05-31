import 'package:genui/genui.dart';

class MatchPair {
  final String left;
  final String right;

  MatchPair({required this.left, required this.right});

  factory MatchPair.fromJson(Map<String, Object?> json) {
    return MatchPair(
      left: (json['left'] as String?) ?? '',
      right: (json['right'] as String?) ?? '',
    );
  }
}

class WordMatchPairData {
  final List<MatchPair> pairs;
  final String actionName;
  final JsonMap actionContext;

  WordMatchPairData({
    required this.pairs,
    required this.actionName,
    required this.actionContext,
  });

  factory WordMatchPairData.fromJson(Map<String, Object?> json) {
    final action = json['matchCompleteAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final pairsRaw = json['pairs'] as List<dynamic>?;
    return WordMatchPairData(
      pairs: pairsRaw
              ?.map((e) => MatchPair.fromJson(e as Map<String, Object?>))
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
