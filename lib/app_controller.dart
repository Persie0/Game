import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/app_repository.dart';
import 'game/progress.dart';
import 'game/puzzle.dart';
import 'game/session.dart';
import 'services/ad_service.dart';
import 'services/feedback_service.dart';
import 'services/purchase_service.dart';

class ActiveGameRuntime {
  ActiveGameRuntime({
    required this.data,
    required this.puzzle,
    required this.session,
  }) : analysis = PuzzleSolver.analyze(puzzle);

  final ActiveGameData data;
  final Puzzle puzzle;
  final GameSession session;
  final PuzzleAnalysis analysis;
}

enum HintRequestResult { applied, noHint, requiresPro }

class AppController extends ChangeNotifier {
  AppController._({
    required AppRepository repository,
    required this.purchases,
    required this.ads,
    required this.state,
  }) : _repository = repository;

  final AppRepository _repository;
  final PuzzleGenerator generator = PuzzleGenerator();
  final FeedbackService feedback = const FeedbackService();
  final PurchaseService purchases;
  final AdService ads;
  PersistentState state;
  ActiveGameRuntime? active;

  GameSettings get settings => state.settings;
  PlayerProgress get progress => state.progress;
  bool get isPro => progress.pro;

  static Future<AppController> create({AppRepository? repository}) async {
    final repo = repository ?? PreferencesAppRepository();
    final state = await repo.load();
    final controller = AppController._(
      repository: repo,
      purchases: createPurchaseService(),
      ads: createAdService(),
      state: state,
    );
    controller._restoreActive();
    controller.purchases.proEntitlement.addListener(controller._syncStorePro);
    await Future.wait([
      controller.purchases.initialize(),
      controller.ads.initialize(),
    ]);
    controller._syncStorePro();
    return controller;
  }

  static Future<AppController> memory([PersistentState? initial]) =>
      create(repository: MemoryAppRepository(initial));

  void _restoreActive() {
    final data = state.activeGame;
    if (data == null ||
        data.generatorVersion != PuzzleGenerator.generatorVersion) {
      state.activeGame = null;
      return;
    }
    try {
      final puzzle = generator.generate(
        difficulty: data.difficulty,
        seed: data.seed,
      );
      final session = GameSession.fromJson(puzzle, data.session);
      active = ActiveGameRuntime(data: data, puzzle: puzzle, session: session);
    } catch (_) {
      state.activeGame = null;
      active = null;
    }
  }

  Future<ActiveGameRuntime> startGame({
    required GameMode mode,
    required HeistDifficulty difficulty,
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    final seed = mode == GameMode.daily
        ? generator.dailySeed(date, difficulty)
        : null;
    final puzzle = generator.generate(difficulty: difficulty, seed: seed);
    final session = GameSession(puzzle);
    final data = ActiveGameData(
      mode: mode,
      difficulty: difficulty,
      seed: puzzle.seed,
      generatorVersion: PuzzleGenerator.generatorVersion,
      session: session.toJson(),
      elapsedSeconds: 0,
    );
    active = ActiveGameRuntime(data: data, puzzle: puzzle, session: session);
    state.activeGame = data;
    await _save();
    notifyListeners();
    return active!;
  }

  Future<void> saveActive({required int elapsedSeconds}) async {
    final current = active;
    if (current == null) return;
    current.data.session = current.session.toJson();
    current.data.elapsedSeconds = elapsedSeconds;
    state.activeGame = current.data;
    await _save();
    notifyListeners();
  }

  Future<HintRequestResult> requestHint({required int elapsedSeconds}) async {
    final current = active;
    if (current == null) return HintRequestResult.noHint;
    final suggestion = current.session.nextHint();
    if (suggestion == null) return HintRequestResult.noHint;

    final freeHint = current.session.hintsUsed < 2;
    if (!isPro && !freeHint) {
      final earned = await ads.showRewarded();
      if (!earned) return HintRequestResult.requiresPro;
    }

    current.session.applyHint(suggestion, autoCross: settings.autoCross);
    feedback.hint(settings);
    await saveActive(elapsedSeconds: elapsedSeconds);
    return HintRequestResult.applied;
  }

  Future<ProgressReward> completeActive({
    required int elapsedSeconds,
    DateTime? now,
  }) async {
    final current = active;
    if (current == null || !current.session.isSolved) {
      throw StateError('No solved active game.');
    }
    final reward = progress.recordCompletion(
      completedAt: now ?? DateTime.now(),
      mode: current.data.mode,
      difficulty: current.data.difficulty,
      moves: current.session.moves,
      seconds: elapsedSeconds,
      hintsUsed: current.session.hintsUsed,
      mistakes: current.session.mistakes,
      difficultyScore: current.analysis.score,
    );
    state.activeGame = null;
    active = null;
    await _save();
    notifyListeners();
    return reward;
  }

  Future<void> maybeShowCompletionAd(GameMode completedMode) async {
    if (isPro || completedMode != GameMode.freePlay) return;
    if (progress.freePlaySinceAd == 0 ||
        progress.freePlaySinceAd % 3 != 0) {
      return;
    }
    await ads.maybeShowInterstitial(enabled: true);
  }

  Future<void> completeOnboarding() async {
    state.onboardingDone = true;
    await _save();
    notifyListeners();
  }

  Future<void> updateSettings(
    void Function(GameSettings settings) update,
  ) async {
    update(settings);
    if (!progress.isSkinUnlocked(settings.skin)) {
      settings.skin = MuseumSkin.classic;
    }
    await _save();
    notifyListeners();
  }

  Future<bool> buyLifetime() async {
    final started = await purchases.buyLifetime();
    _syncStorePro();
    return started;
  }

  Future<bool> restorePurchases() async {
    final started = await purchases.restore();
    _syncStorePro();
    return started;
  }

  void _syncStorePro() {
    if (purchases.proEntitlement.value && !progress.pro) {
      progress.pro = true;
      unawaited(_save());
      notifyListeners();
    }
  }

  Future<void> resetProgress() async {
    final keepPro = progress.pro;
    state = PersistentState(
      settings: settings,
      progress: PlayerProgress(pro: keepPro),
      onboardingDone: true,
    );
    active = null;
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _repository.save(state);

  @override
  void dispose() {
    purchases.proEntitlement.removeListener(_syncStorePro);
    purchases.dispose();
    super.dispose();
  }
}
