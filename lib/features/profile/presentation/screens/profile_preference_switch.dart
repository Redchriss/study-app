import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AsyncPreferenceSwitch extends StatefulWidget {
  const AsyncPreferenceSwitch({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.loadValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Future<bool> Function() loadValue;
  final Future<void> Function(bool) onChanged;
  final String title, subtitle;

  @override
  State<AsyncPreferenceSwitch> createState() => _AsyncPreferenceSwitchState();
}

class _AsyncPreferenceSwitchState extends State<AsyncPreferenceSwitch> {
  bool? _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.loadValue().then((v) {
      if (mounted) setState(() => _value = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(widget.icon, size: 16, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(widget.subtitle,
                    style: const TextStyle(
                        color: DesignTokens.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          _value == null
              ? const SizedBox(
                  width: 36,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Switch.adaptive(
                  value: _value!,
                  onChanged: _saving
                      ? null
                      : (v) async {
                          setState(() {
                            _value = v;
                            _saving = true;
                          });
                          await widget.onChanged(v);
                          if (mounted) setState(() => _saving = false);
                        },
                  activeTrackColor: DesignTokens.primary,
                ),
        ],
      ),
    );
  }
}
