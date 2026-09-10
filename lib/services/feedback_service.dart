import 'dart:async';

import 'package:flutter/services.dart';

import '../game/progress.dart';

class FeedbackService {
  const FeedbackService();

  void tap(GameSettings settings) {
    if (settings.haptics) unawaited(HapticFeedback.selectionClick());
    if (settings.sound) unawaited(SystemSound.play(SystemSoundType.click));
  }

  void hint(GameSettings settings) {
    if (settings.haptics) unawaited(HapticFeedback.lightImpact());
  }

  void success(GameSettings settings) {
    if (settings.haptics) unawaited(HapticFeedback.heavyImpact());
    if (settings.sound) unawaited(SystemSound.play(SystemSoundType.alert));
  }
}
