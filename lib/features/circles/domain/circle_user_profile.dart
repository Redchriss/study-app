import 'circle_author.dart';
import 'circle_parse.dart';

/// A community member's public profile (`userProfile` / `myProfile`).
class CircleUserProfile {
  final CircleAuthor? user;
  final String? avatarUrl;
  final String? bannerUrl;
  final String bio;
  final int postKarma;
  final int commentKarma;
  final int awardKarma;
  final int totalKarma;
  final bool isFollowing;
  final bool isBlocked;
  final List<CircleProfileCommunity> activeCommunities;
  final DateTime? createdAt;

  const CircleUserProfile({
    this.user,
    this.avatarUrl,
    this.bannerUrl,
    this.bio = '',
    this.postKarma = 0,
    this.commentKarma = 0,
    this.awardKarma = 0,
    this.totalKarma = 0,
    this.isFollowing = false,
    this.isBlocked = false,
    this.activeCommunities = const [],
    this.createdAt,
  });

  factory CircleUserProfile.fromJson(Map<String, dynamic> json) {
    return CircleUserProfile(
      user: CircleAuthor.maybe(json['user']),
      avatarUrl: asStringOrNull(json['avatarUrl']),
      bannerUrl: asStringOrNull(json['bannerUrl']),
      bio: asString(json['bio']),
      postKarma: asInt(json['postKarma']),
      commentKarma: asInt(json['commentKarma']),
      awardKarma: asInt(json['awardKarma']),
      totalKarma: asInt(json['totalKarma']),
      isFollowing: asBool(json['isFollowing']),
      isBlocked: asBool(json['isBlocked']),
      activeCommunities: asMapList(json['activeCommunities'])
          .map(CircleProfileCommunity.fromJson)
          .toList(),
      createdAt: asDateTime(json['createdAt']),
    );
  }
}

/// A community shown on a user's profile (a light list shape).
class CircleProfileCommunity {
  final String slug;
  final String name;
  final String displayName;
  final String? icon;
  final int memberCount;

  const CircleProfileCommunity({
    required this.slug,
    required this.name,
    required this.displayName,
    this.icon,
    this.memberCount = 0,
  });

  factory CircleProfileCommunity.fromJson(Map<String, dynamic> json) {
    return CircleProfileCommunity(
      slug: asString(json['slug']),
      name: asString(json['name']),
      displayName: asString(json['displayName'], asString(json['name'])),
      icon: asStringOrNull(json['icon']),
      memberCount: asInt(json['memberCount']),
    );
  }
}
