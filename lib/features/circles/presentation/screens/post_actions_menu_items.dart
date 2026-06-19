import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Builds the popup-menu entries for [PostActions]. Extracted to keep the
/// menu widget within the project's 250-line file limit.
List<PopupMenuEntry<String>> buildPostActionItems({
  required bool isMod,
  required bool canTagPost,
  required bool isOc,
  required bool isSpoiler,
  required bool isPinned,
  required bool isLocked,
  required bool isRemoved,
  required String authorUsername,
}) {
  return [
    _item('save', Icons.bookmark_outline, 'Save'),
    _item('copy_link', Icons.link, 'Copy link'),
    _item('hide', Icons.visibility_off_outlined, 'Hide'),
    _item('crosspost', Icons.repeat_rounded, 'Crosspost'),
    if (authorUsername.isNotEmpty)
      _item('block_author', Icons.block, 'Block author',
          color: DesignTokens.error),
    const PopupMenuDivider(),
    _item('report', Icons.flag_outlined, 'Report'),
    if (canTagPost) ...[
      const PopupMenuDivider(),
      _item('mark_oc', isOc ? Icons.verified : Icons.verified_outlined,
          isOc ? 'Marked OC' : 'Mark as OC'),
      _item(
          'mark_spoiler',
          isSpoiler ? Icons.visibility_off : Icons.visibility_off_outlined,
          isSpoiler ? 'Unmark spoiler' : 'Mark as spoiler'),
      _item('set_flair', Icons.label_outline, 'Set flair'),
    ],
    if (isMod) ...[
      const PopupMenuDivider(),
      _item('pin', isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          isPinned ? 'Unpin' : 'Pin'),
      _item('lock', isLocked ? Icons.lock : Icons.lock_outline,
          isLocked ? 'Unlock' : 'Lock'),
      _item('distinguish', Icons.shield_outlined, 'Distinguish [MOD]'),
      _item('remove', Icons.delete_outline, 'Remove', color: DesignTokens.error),
      if (isRemoved)
        _item('approve', Icons.check_circle_outline, 'Approve',
            color: Colors.green),
    ],
  ];
}

PopupMenuItem<String> _item(String value, IconData icon, String label,
    {Color? color}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(label, style: color == null ? null : TextStyle(color: color)),
    ]),
  );
}
