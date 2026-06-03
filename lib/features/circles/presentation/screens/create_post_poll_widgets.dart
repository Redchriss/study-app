import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PollDurationSelector extends StatefulWidget {
  final List<TextEditingController> options;
  final int duration;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
  final ValueChanged<int> onDurationChanged;
  const PollDurationSelector({
    super.key,
    required this.options,
    required this.duration,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onDurationChanged,
  });

  @override
  State<PollDurationSelector> createState() => _PollDurationSelectorState();
}

class _PollDurationSelectorState extends State<PollDurationSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      ...widget.options.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: e.key,
                  child: const Icon(Icons.drag_handle,
                      color: DesignTokens.textTertiary),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: 'Option ${e.key + 1}',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.options.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => widget.onRemoveOption(e.key),
                  ),
              ],
            ),
          )),
      OutlinedButton.icon(
        onPressed: widget.options.length < 6 ? widget.onAddOption : null,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add option'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: widget.duration,
        decoration: const InputDecoration(
          labelText: 'Poll duration',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 24, child: Text('1 day')),
          DropdownMenuItem(value: 72, child: Text('3 days')),
          DropdownMenuItem(value: 168, child: Text('7 days')),
        ],
        onChanged: (v) {
          if (v != null) widget.onDurationChanged(v);
        },
      ),
    ]);
  }
}
