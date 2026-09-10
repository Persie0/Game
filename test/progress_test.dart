import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/game/progress.dart';
import 'package:museum_heist/game/puzzle.dart';

void main() {
  test('daily streak grows on consecutive days and ignores replay rewards', () {
    final progress = PlayerProgress();
    final first = DateTime(2026, 9, 10);
    progress.recordCompletion(
      completedAt: first,
      mode: GameMode.daily,
      difficulty: HeistDifficulty.professional,
      moves: 10,
      seconds: 120,
      hintsUsed: 0,
      mistakes: 0,
      difficultyScore: 55,
    );
    final xpAfterFirst = progress.xp;

    final replay = progress.recordCompletion(
      completedAt: first,
      mode: GameMode.daily,
      difficulty: HeistDifficulty.professional,
      moves: 8,
      seconds: 90,
      hintsUsed: 0,
      mistakes: 0,
      difficultyScore: 55,
    );
    expect(progress.currentStreak, 1);
    expect(progress.xp, xpAfterFirst);
    expect(replay.xp, 0);

    progress.recordCompletion(
      completedAt: first.add(const Duration(days: 1)),
      mode: GameMode.daily,
      difficulty: HeistDifficulty.professional,
      moves: 9,
      seconds: 100,
      hintsUsed: 0,
      mistakes: 0,
      difficultyScore: 55,
    );
    expect(progress.currentStreak, 2);
    expect(progress.bestStreak, 2);
  });

  test('persistent state round trips settings and progression', () {
    final state = PersistentState(onboardingDone: true);
    state.progress.xp = 1234;
    state.progress.dailyCompletions.add('2026-09-10:professional');
    state.settings.autoCross = false;
    state.settings.regionLabels = true;

    final restored = PersistentState.fromJson(state.toJson());
    expect(restored.onboardingDone, isTrue);
    expect(restored.progress.xp, 1234);
    expect(
      restored.progress.dailyCompletions,
      contains('2026-09-10:professional'),
    );
    expect(restored.settings.autoCross, isFalse);
    expect(restored.settings.regionLabels, isTrue);
  });

  test('museum skins unlock from reputation levels', () {
    final progress = PlayerProgress();
    expect(progress.isSkinUnlocked(MuseumSkin.classic), isTrue);
    expect(progress.isSkinUnlocked(MuseumSkin.neon), isFalse);
    progress.xp = 4500;
    expect(progress.level, 10);
    expect(progress.isSkinUnlocked(MuseumSkin.neon), isTrue);
  });
}
