import 'package:flutter/material.dart';

class BanUserDialog extends StatefulWidget {
  final String username;

  const BanUserDialog({super.key, required this.username});

  @override
  State<BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<BanUserDialog> {
  final _reasonCtrl = TextEditingController();
  bool _isPermanent = true;
  int _durationDays = 7;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ban u/${widget.username}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _reasonCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Reason for ban',
              labelText: 'Ban reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Permanent ban'),
            value: _isPermanent,
            onChanged: (v) => setState(() => _isPermanent = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_isPermanent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duration', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [3, 7, 14, 30].map((d) {
                    final selected = _durationDays == d;
                    return ChoiceChip(
                      label: Text('$d days'),
                      selected: selected,
                      onSelected: (_) => setState(() => _durationDays = d),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, {
                  'reason': _reasonCtrl.text,
                  'isPermanent': _isPermanent,
                  'durationDays': _durationDays,
                }),
            child: const Text('Confirm Ban')),
      ],
    );
  }
}
