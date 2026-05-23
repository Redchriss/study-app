import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final progressRingSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ProgressRing']),
    'topic': S.string(description: 'The topic or course being tracked'),
    'completed_count':
        S.integer(description: 'Number of subtopics or questions completed'),
    'total_count':
        S.integer(description: 'Total subtopics or questions in this topic'),
    'session_summary': S.string(
      description: 'One sentence summary of what was covered today',
    ),
  },
  required: ['component', 'topic', 'completed_count', 'total_count'],
);

class _ProgressRingData {
  final String topic;
  final int completedCount;
  final int totalCount;
  final String? sessionSummary;

  _ProgressRingData({
    required this.topic,
    required this.completedCount,
    required this.totalCount,
    this.sessionSummary,
  });

  double get fraction => totalCount > 0 ? completedCount / totalCount : 0.0;

  factory _ProgressRingData.fromJson(Map<String, Object?> json) {
    return _ProgressRingData(
      topic: (json['topic'] as String?) ?? '',
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 1,
      sessionSummary: json['session_summary'] as String?,
    );
  }
}

class _ProgressRingWidget extends StatefulWidget {
  final _ProgressRingData data;

  const _ProgressRingWidget({required this.data});

  @override
  State<_ProgressRingWidget> createState() => _ProgressRingWidgetState();
}

class _ProgressRingWidgetState extends State<_ProgressRingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final percent = widget.data.fraction * _anim.value;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _RingPainter(
                    fraction: percent,
                    color: cs.primary,
                    trackColor: cs.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percent * 100).round()}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${widget.data.completedCount}/${widget.data.totalCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.topic,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.data.sessionSummary != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.data.sessionSummary!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.fraction != fraction;
}

final progressRingItem = CatalogItem(
  name: 'ProgressRing',
  dataSchema: progressRingSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ProgressRingData.fromJson(json);
    return _ProgressRingWidget(data: data);
  },
);
