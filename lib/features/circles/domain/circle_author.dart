import 'circle_parse.dart';

/// A minimal user reference as embedded in posts/comments (`{ id username }`).
class CircleAuthor {
  final String id;
  final String username;

  const CircleAuthor({required this.id, required this.username});

  factory CircleAuthor.fromJson(Map<String, dynamic> json) {
    return CircleAuthor(
      id: asString(json['id']),
      username: asString(json['username']),
    );
  }

  /// Tolerates a null map (deleted/anonymous authors).
  static CircleAuthor? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CircleAuthor.fromJson(map);
  }
}

/// A compact reference to a community as embedded in a post.
class CircleCommunityRef {
  final String id;
  final String name;
  final String slug;
  final String displayName;
  final String? icon;
  final bool isMember;
  final bool isModerator;

  const CircleCommunityRef({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayName,
    this.icon,
    this.isMember = false,
    this.isModerator = false,
  });

  factory CircleCommunityRef.fromJson(Map<String, dynamic> json) {
    return CircleCommunityRef(
      id: asString(json['id']),
      name: asString(json['name']),
      slug: asString(json['slug']),
      displayName: asString(json['displayName'], asString(json['name'])),
      icon: asStringOrNull(json['icon']),
      isMember: asBool(json['isMember']),
      isModerator: asBool(json['isModerator']),
    );
  }

  static CircleCommunityRef? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CircleCommunityRef.fromJson(map);
  }
}
