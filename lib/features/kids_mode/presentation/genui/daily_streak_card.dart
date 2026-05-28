import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../kids_visual_theme.dart';

final dailyStreakCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DailyStreakCard']),
    'streak_days': S.integer(description: 'Current streak in days'),
    'child_name':
        S.string(description: 'Child first name for personalised message'),
    'message':
        S.string(description: 'Short encouraging message about the streak'),
  },
  required: ['component', 'streak_days', 'message'],
);

class _DailyStreakCardData {
  final int streakDays;
  final String message;
  final String childName;

  _DailyStreakCardData({
    required this.streakDays,
    required this.message,
    this.childName = '',
  });

  factory _DailyStreakCardData.fromJson(Map<String, Object?> json) {
    return _DailyStreakCardData(
      streakDays: (json['streak_days'] as int?) ?? 0,
      message: (json['message'] as String?) ?? 'Keep going!',
      childName: (json['child_name'] as String?) ?? '',
    );
  }
}

class _DailyStreakCardWidget extends StatefulWidget {
  final _DailyStreakCardData data;
  const _DailyStreakCardWidget({required this.data});

  @override
  State<_DailyStreakCardWidget> createState() => _DailyStreakCardWidgetState();
}

class _DailyStreakCardWidgetState extends State<_DailyStreakCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    ));
    _entranceCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final greeting =
        d.childName.isNotEmpty ? 'Hey ${d.childName}!' : 'Great job!';
    final dayWord = d.streakDays == 1 ? 'day' : 'days';

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _entranceAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A65), Color(0xFFFF6F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: KidsVisualTheme.chunkyShadow(const Color(0xCCFF6F00)),
          ),
          child: Column(
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Text(
                  d.streakDays >= 7 ? '🔥' : '⭐',
                  style: const TextStyle(fontSize: 56),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$dayWord $greeting',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              _DayDots(streakDays: d.streakDays),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDots extends StatelessWidget {
  final int streakDays;
  const _DayDots({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final filled = (streakDays % 7).clamp(0, 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                i < filled ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

final dailyStreakCardItem = CatalogItem(
  name: 'DailyStreakCard',
  dataSchema: dailyStreakCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _DailyStreakCardData.fromJson(json);
    return _DailyStreakCardWidget(data: data);
  },
);
