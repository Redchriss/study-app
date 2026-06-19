import 'circle_author.dart';
import 'circle_parse.dart';

/// A full community as returned by the `community(slug:)` query, plus the
/// lighter shape used by list/discover queries (extra fields default safely).
class CircleCommunity {
  final String id;
  final String name;
  final String slug;
  final String displayName;
  final String description;
  final String? sidebarMarkdown;
  final String? icon;
  final String? banner;
  final int memberCount;
  final int postCount;
  final String communityType;
  final bool over18;
  final bool isMember;
  final bool isModerator;
  final bool isFavorite;
  final String? userRole;
  final CircleCommunityPermissions permissions;
  final CircleAuthor? createdBy;
  final DateTime? createdAt;

  const CircleCommunity({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayName,
    required this.description,
    required this.memberCount,
    required this.postCount,
    required this.communityType,
    required this.permissions,
    this.sidebarMarkdown,
    this.icon,
    this.banner,
    this.over18 = false,
    this.isMember = false,
    this.isModerator = false,
    this.isFavorite = false,
    this.userRole,
    this.createdBy,
    this.createdAt,
  });

  factory CircleCommunity.fromJson(Map<String, dynamic> json) {
    return CircleCommunity(
      id: asString(json['id']),
      name: asString(json['name']),
      slug: asString(json['slug']),
      displayName: asString(json['displayName'], asString(json['name'])),
      description: asString(json['description']),
      sidebarMarkdown: asStringOrNull(json['sidebarMarkdown']),
      icon: asStringOrNull(json['icon']),
      banner: asStringOrNull(json['banner']),
      memberCount: asInt(json['memberCount']),
      postCount: asInt(json['postCount']),
      communityType: asString(json['communityType'], 'public'),
      over18: asBool(json['over18']),
      isMember: asBool(json['isMember']),
      isModerator: asBool(json['isModerator']),
      isFavorite: asBool(json['isFavorite']),
      userRole: asStringOrNull(json['userRole']),
      permissions: CircleCommunityPermissions.fromJson(json),
      createdBy: CircleAuthor.maybe(json['createdBy']),
      createdAt: asDateTime(json['createdAt']),
    );
  }
}

/// Posting permissions/toggles for a community.
class CircleCommunityPermissions {
  final bool allowImages;
  final bool allowVideos;
  final bool allowPolls;
  final bool allowLinks;
  final bool allowGalleries;
  final bool allowCrossposts;
  final bool spoilersEnabled;

  const CircleCommunityPermissions({
    this.allowImages = true,
    this.allowVideos = true,
    this.allowPolls = true,
    this.allowLinks = true,
    this.allowGalleries = true,
    this.allowCrossposts = true,
    this.spoilersEnabled = false,
  });

  factory CircleCommunityPermissions.fromJson(Map<String, dynamic> json) {
    return CircleCommunityPermissions(
      allowImages: asBool(json['allowImages'], true),
      allowVideos: asBool(json['allowVideos'], true),
      allowPolls: asBool(json['allowPolls'], true),
      allowLinks: asBool(json['allowLinks'], true),
      allowGalleries: asBool(json['allowGalleries'], true),
      allowCrossposts: asBool(json['allowCrossposts'], true),
      spoilersEnabled: asBool(json['spoilersEnabled']),
    );
  }
}

/// A single moderation rule for a community.
class CircleRule {
  final String id;
  final String title;
  final String description;
  final int order;

  const CircleRule({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
  });

  factory CircleRule.fromJson(Map<String, dynamic> json) {
    return CircleRule(
      id: asString(json['id']),
      title: asString(json['title']),
      description: asString(json['description']),
      order: asInt(json['order']),
    );
  }
}
