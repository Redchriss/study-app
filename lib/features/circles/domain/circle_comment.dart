import 'circle_author.dart';
import 'circle_parse.dart';

/// A comment on a post (`CommentFields`). Replies are loaded lazily, so a
/// comment only knows its [repliesCount] and tree [depth].
class CircleComment {
  final String id;
  final String body;
  final String? bodyHtml;
  final int upvoteCount;
  final int downvoteCount;
  final int score;
  final int fuzzedScore;
  final bool isDeleted;
  final bool isEdited;
  final bool isPinned;
  final bool isAnswer;
  final bool isCollapsed;
  final int depth;
  final int repliesCount;
  final CircleAuthor? author;
  final DateTime? createdAt;
  final DateTime? editedAt;

  const CircleComment({
    required this.id,
    required this.body,
    this.bodyHtml,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.score = 0,
    this.fuzzedScore = 0,
    this.isDeleted = false,
    this.isEdited = false,
    this.isPinned = false,
    this.isAnswer = false,
    this.isCollapsed = false,
    this.depth = 0,
    this.repliesCount = 0,
    this.author,
    this.createdAt,
    this.editedAt,
  });

  factory CircleComment.fromJson(Map<String, dynamic> json) {
    return CircleComment(
      id: asString(json['id']),
      body: asString(json['body']),
      bodyHtml: asStringOrNull(json['bodyHtml']),
      upvoteCount: asInt(json['upvoteCount']),
      downvoteCount: asInt(json['downvoteCount']),
      score: asInt(json['score']),
      fuzzedScore: asInt(json['fuzzedScore']),
      isDeleted: asBool(json['isDeleted']),
      isEdited: asBool(json['isEdited']),
      isPinned: asBool(json['isPinned']),
      isAnswer: asBool(json['isAnswer']),
      isCollapsed: asBool(json['isCollapsed']),
      depth: asInt(json['depth']),
      repliesCount: asInt(json['repliesCount']),
      author: CircleAuthor.maybe(json['author']),
      createdAt: asDateTime(json['createdAt']),
      editedAt: asDateTime(json['editedAt']),
    );
  }
}
