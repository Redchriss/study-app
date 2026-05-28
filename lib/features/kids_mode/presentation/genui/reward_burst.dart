import 'dart:math';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final rewardBurstSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['RewardBurst']),
    'message': S.string(
      description: 'Short celebration message, max 5 words',
    ),
    'stars_earned':
        S.integer(description: 'Number of stars to show (1, 2, or 3)'),
    'dismissAction': A2uiSchemas.action(
      description: 'Fires automatically after 2.5 seconds',
    ),
  },
  required: ['component', 'message', 'stars_earned', 'dismissAction'],
);

class _RewardBurstData {
  final String message;
  final int starsEarned;
  final String dismissActionName;
  final JsonMap dismissActionContext;

  _RewardBurstData({
    required this.message,
    required this.starsEarned,
    required this.dismissActionName,
    required this.dismissActionContext,
  });

  factory _RewardBurstData.fromJson(Map<String, Object?> json) {
    final action = json['dismissAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _RewardBurstData(
      message: (json['message'] as String?) ?? 'Amazing!',
      starsEarned: ((json['stars_earned'] as int?) ?? 1).clamp(1, 3),
      dismissActionName: (event?['name'] as String?) ?? 'dismissed',
      dismissActionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawRect(
        Rect.fromCenter(center: p.position, width: 8, height: 6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

class _ConfettiParticle {
  Offset position;
  final Offset velocity;
  final Color color;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
  });

  void update() {
    position += velocity;
  }
}

class _RewardBurstWidget extends StatefulWidget {
  final _RewardBurstData data;
  final VoidCallback onDismiss;

  const _RewardBurstWidget({required this.data, required this.onDismiss});

  @override
  State<_RewardBurstWidget> createState() => _RewardBurstWidgetState();
}

class _RewardBurstWidgetState extends State<_RewardBurstWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _starAnim;
  late final AnimationController _confettiCtrl;
  late final List<_ConfettiParticle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    );
    _entranceCtrl.forward();
    _entranceCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), widget.onDismiss);
      }
    });
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _particles = List.generate(40, (_) {
      return _ConfettiParticle(
        position: Offset(
          _rand.nextDouble() * 400,
          -20 - _rand.nextDouble() * 100,
        ),
        velocity: Offset(
          (_rand.nextDouble() - 0.5) * 2,
          2 + _rand.nextDouble() * 3,
        ),
        color: [
          Colors.amber,
          Colors.orange,
          Colors.blue,
          Colors.green,
          Colors.pink,
          Colors.purple,
        ][_rand.nextInt(6)],
      );
    });
    _confettiCtrl.addListener(() {
      for (final p in _particles) {
        p.update();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(_particles),
                size: Size.infinite,
              );
            },
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _starAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.data.starsEarned, (_) {
                    return const Text('⭐', style: TextStyle(fontSize: 48));
                  }),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _starAnim,
                child: Text(
                  widget.data.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final rewardBurstItem = CatalogItem(
  name: 'RewardBurst',
  dataSchema: rewardBurstSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _RewardBurstData.fromJson(json);
    return _RewardBurstWidget(
      data: data,
      onDismiss: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.dismissActionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.dismissActionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
