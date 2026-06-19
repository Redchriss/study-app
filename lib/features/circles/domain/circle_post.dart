import 'circle_author.dart';
import 'circle_parse.dart';
import 'circle_poll.dart';

/// A community post. Covers both the feed (`PostFields`) shape and the richer
/// `post(...)` detail shape; detail-only fields default safely when absent.
class CirclePost {
  final String id;
  final String title;
  final String slug;
  final String body;
  final String? bodyHtml;
  final String postType;
  final String? imageUrl;
  final int upvoteCount;
  final int downvoteCount;
  final int score;
  final int commentCount;
  final int fuzzedScore;
  final int awardCount;
  final int shareCount;
  final int viewCount;
  final bool isOc;
  final bool isSpoiler;
  final bool isPinned;
  final bool isLocked;
  final bool isRemoved;
  final bool isDeleted;
  final bool isEdited;
  final bool isNsfw;
  final bool isSaved;
  final int voteDirection;
  final CircleAuthor? author;
  final CircleCommunityRef? community;
  final String? flairText;
  final DateTime? createdAt;

  // Detail-only fields.
  final String? url;
  final String? urlDomain;
  final String? videoUrl;
  final CirclePoll? poll;
  final List<CircleGalleryItem> galleryItems;

  const CirclePost({
    required this.id,
    required this.title,
    required this.slug,
    required this.body,
    required this.postType,
    this.bodyHtml,
    this.imageUrl,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.commentCount = 0,
    this.fuzzedScore = 0,
    this.awardCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.isOc = false,
    this.isSpoiler = false,
    this.isPinned = false,
    this.isLocked = false,
    this.isRemoved = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.isNsfw = false,
    this.isSaved = false,
    this.voteDirection = 0,
    this.author,
    this.community,
    this.flairText,
    this.createdAt,
    this.url,
    this.urlDomain,
    this.videoUrl,
    this.poll,
    this.galleryItems = const [],
  });

  factory CirclePost.fromJson(Map<String, dynamic> json) {
    return CirclePost(
      id: asString(json['id']),
      title: asString(json['title']),
      slug: asString(json['slug']),
      body: asString(json['body']),
      bodyHtml: asStringOrNull(json['bodyHtml']),
      postType: asString(json['postType'], 'text'),
      imageUrl: asStringOrNull(json['imageUrl']),
      upvoteCount: asInt(json['upvoteCount']),
      downvoteCount: asInt(json['downvoteCount']),
      score: asInt(json['score']),
      commentCount: asInt(json['commentCount']),
      fuzzedScore: asInt(json['fuzzedScore']),
      awardCount: asInt(json['awardCount']),
      shareCount: asInt(json['shareCount']),
      viewCount: asInt(json['viewCount']),
      isOc: asBool(json['isOc']),
      isSpoiler: asBool(json['isSpoiler']),
      isPinned: asBool(json['isPinned']),
      isLocked: asBool(json['isLocked']),
      isRemoved: asBool(json['isRemoved']),
      isDeleted: asBool(json['isDeleted']),
      isEdited: asBool(json['isEdited']),
      isNsfw: asBool(json['isNsfw']),
      isSaved: asBool(json['isSaved']),
      voteDirection: asInt(json['voteDirection']),
      author: CircleAuthor.maybe(json['author']),
      community: CircleCommunityRef.maybe(json['community']),
      flairText: asStringOrNull(json['flairText']),
      createdAt: asDateTime(json['createdAt']),
      url: asStringOrNull(json['url']),
      urlDomain: asStringOrNull(json['urlDomain']),
      videoUrl: asStringOrNull(json['videoUrl']),
      poll: CirclePoll.maybe(json['poll']),
      galleryItems: asMapList(json['galleryItems'])
          .map(CircleGalleryItem.fromJson)
          .toList(),
    );
  }

  static CirclePost? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CirclePost.fromJson(map);
  }
}
