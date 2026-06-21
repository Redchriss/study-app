import 'package:flutter/services.dart';

class HapticService {
  HapticService._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static void lightTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static void mediumTap() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void success() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
