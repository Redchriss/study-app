import 'package:flutter/material.dart';
import 'kid_auth_pin_data.dart';

class GraphicalPinGrid extends StatelessWidget {
  const GraphicalPinGrid({
    required this.onEmojiTap,
    required this.delete,
  });

  final void Function(String) onEmojiTap;
  final VoidCallback delete;

  @override
  Widget build(BuildContext context) {
    final emojiRows = [
      pinEmojis.sublist(0, 3),
      pinEmojis.sublist(3, 6),
      pinEmojis.sublist(6, 9)
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Emoji PIN pad',
          child: Column(
            children: emojiRows
                .map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((emoji) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Semantics(
                              button: true,
                              label: 'Select ${emojiPinMap[emoji]}',
                              child: Material(
                                color: Colors.grey.shade100,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => onEmojiTap(emoji),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Center(
                                      child: Semantics(
                                        excludeSemantics: true,
                                        child: Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 30)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: 'Delete last emoji',
          child: Material(
            color: Colors.orange,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: delete,
              child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.backspace_outlined,
                      color: Colors.orange.shade800)),
            ),
          ),
        ),
      ],
    );
  }
}
