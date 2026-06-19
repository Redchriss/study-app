import 'circle_parse.dart';

/// A post flair template configured for a community.
class CirclePostFlair {
  final String id;
  final String text;
  final String? color;
  final String? textColor;
  final String? emoji;
  final bool modOnly;
  final int order;

  const CirclePostFlair({
    required this.id,
    required this.text,
    this.color,
    this.textColor,
    this.emoji,
    this.modOnly = false,
    this.order = 0,
  });

  factory CirclePostFlair.fromJson(Map<String, dynamic> json) {
    return CirclePostFlair(
      id: asString(json['id']),
      text: asString(json['text']),
      color: asStringOrNull(json['color']),
      textColor: asStringOrNull(json['textColor']),
      emoji: asStringOrNull(json['emoji']),
      modOnly: asBool(json['modOnly']),
      order: asInt(json['order']),
    );
  }

  static CirclePostFlair? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CirclePostFlair.fromJson(map);
  }
}

/// A user's flair within a community.
class CircleUserFlair {
  final String id;
  final String text;
  final String? emoji;

  const CircleUserFlair({
    required this.id,
    required this.text,
    this.emoji,
  });

  factory CircleUserFlair.fromJson(Map<String, dynamic> json) {
    return CircleUserFlair(
      id: asString(json['id']),
      text: asString(json['text']),
      emoji: asStringOrNull(json['emoji']),
    );
  }

  static CircleUserFlair? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CircleUserFlair.fromJson(map);
  }
}
