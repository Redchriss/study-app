import 'circle_parse.dart';

/// A single option within a post poll.
class CirclePollOption {
  final String id;
  final String text;
  final int order;
  final int voteCount;

  const CirclePollOption({
    required this.id,
    required this.text,
    required this.order,
    required this.voteCount,
  });

  factory CirclePollOption.fromJson(Map<String, dynamic> json) {
    return CirclePollOption(
      id: asString(json['id']),
      text: asString(json['text']),
      order: asInt(json['order']),
      voteCount: asInt(json['voteCount']),
    );
  }
}

/// A poll attached to a post.
class CirclePoll {
  final String id;
  final DateTime? closesAt;
  final bool allowAddOption;
  final int voteCount;
  final List<CirclePollOption> options;
  final String? userVoteOptionId;

  const CirclePoll({
    required this.id,
    required this.options,
    this.closesAt,
    this.allowAddOption = false,
    this.voteCount = 0,
    this.userVoteOptionId,
  });

  bool get hasVoted => userVoteOptionId != null;

  factory CirclePoll.fromJson(Map<String, dynamic> json) {
    final options = asMapList(json['options'])
        .map(CirclePollOption.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return CirclePoll(
      id: asString(json['id']),
      closesAt: asDateTime(json['closesAt']),
      allowAddOption: asBool(json['allowAddOption']),
      voteCount: asInt(json['voteCount']),
      options: options,
      userVoteOptionId: asStringOrNull(asMap(json['userVote'])?['id']),
    );
  }

  static CirclePoll? maybe(dynamic json) {
    final map = asMap(json);
    if (map == null) return null;
    return CirclePoll.fromJson(map);
  }
}

/// A single image within a gallery post.
class CircleGalleryItem {
  final String id;
  final String imageUrl;
  final String? caption;
  final String? linkUrl;
  final int order;

  const CircleGalleryItem({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.linkUrl,
    this.order = 0,
  });

  factory CircleGalleryItem.fromJson(Map<String, dynamic> json) {
    return CircleGalleryItem(
      id: asString(json['id']),
      imageUrl: asString(json['imageUrl']),
      caption: asStringOrNull(json['caption']),
      linkUrl: asStringOrNull(json['linkUrl']),
      order: asInt(json['order']),
    );
  }
}
