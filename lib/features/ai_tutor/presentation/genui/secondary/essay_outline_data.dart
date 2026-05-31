class PointData {
  final String heading;
  final String evidence;
  final String linkBack;

  PointData({
    required this.heading,
    required this.evidence,
    required this.linkBack,
  });

  factory PointData.fromJson(Map<String, Object?> json) {
    return PointData(
      heading: (json['heading'] as String?) ?? '',
      evidence: (json['evidence'] as String?) ?? '',
      linkBack: (json['link_back'] as String?) ?? '',
    );
  }
}

class EssayOutlineData {
  final String essayQuestion;
  final String thesis;
  final List<PointData> points;
  final String? conclusionNote;

  EssayOutlineData({
    required this.essayQuestion,
    required this.thesis,
    required this.points,
    this.conclusionNote,
  });

  factory EssayOutlineData.fromJson(Map<String, Object?> json) {
    final pointsRaw = json['points'] as List<dynamic>?;
    return EssayOutlineData(
      essayQuestion: (json['essay_question'] as String?) ?? '',
      thesis: (json['thesis'] as String?) ?? '',
      points: pointsRaw
              ?.map((e) => PointData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      conclusionNote: json['conclusion_note'] as String?,
    );
  }
}
