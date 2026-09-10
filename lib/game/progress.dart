import 'puzzle.dart';

enum GameMode { daily, freePlay }

enum AppThemeSetting { system, light, dark }

enum MuseumSkin { classic, noir, emerald, neon }

class GameSettings {
  GameSettings({
    this.theme = AppThemeSetting.system,
    this.skin = MuseumSkin.classic,
    this.sound = true,
    this.haptics = true,
    this.autoCross = true,
    this.showConflicts = true,
    this.reducedMotion = false,
    this.regionLabels = false,
  });

  AppThemeSetting theme;
  MuseumSkin skin;
  bool sound;
  bool haptics;
  bool autoCross;
  bool showConflicts;
  bool reducedMotion;
  bool regionLabels;

  Map<String, Object> toJson() => {
        'theme': theme.name,
        'skin': skin.name,
        'sound': sound,
        'haptics': haptics,
        'autoCross': autoCross,
        'showConflicts': showConflicts,
        'reducedMotion': reducedMotion,
        'regionLabels': regionLabels,
      };

  factory GameSettings.fromJson(Map<String, Object?> json) => GameSettings(
        theme: AppThemeSetting.values.firstWhere(
          (value) => value.name == json['theme'],
          orElse: () => AppThemeSetting.system,
        ),
        skin: MuseumSkin.values.firstWhere(
          (value) => value.name == json['skin'],
          orElse: () => MuseumSkin.classic,
        ),
        sound: json['sound'] as bool? ?? true,
        haptics: json['haptics'] as bool? ?? true,
        autoCross: json['autoCross'] as bool? ?? true,
        showConflicts: json['showConflicts'] as bool? ?? true,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        regionLabels: json['regionLabels'] as bool? ?? false,
      );
}

class ProgressReward {
  const ProgressReward({
    required this.xp,
    required this.newLevel,
    required this.isNewDaily,
    required this.isPerfect,
  });

  final int xp;
  final int newLevel;
  final bool isNewDaily;
  final bool isPerfect;
}

class PlayerProgress {
  PlayerProgress({
    this.xp = 0,
    this.totalSolved = 0,
    this.totalMoves = 0,
    this.totalSeconds = 0,
    this.totalHints = 0,
    this.perfectSolved = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastDailyDate,
    Set<String>? dailyCompletions,
    Map<String, int>? bestMoves,
    Map<String, int>? bestSeconds,
    this.pro = false,
    this.freePlaySinceAd = 0,
  })  : dailyCompletions = dailyCompletions ?? <String>{},
        bestMoves = bestMoves ?? <String, int>{},
        bestSeconds = bestSeconds ?? <String, int>{};

  int xp;
  int totalSolved;
  int totalMoves;
  int totalSeconds;
  int totalHints;
  int perfectSolved;
  int currentStreak;
  int bestStreak;
  String? lastDailyDate;
  final Set<String> dailyCompletions;
  final Map<String, int> bestMoves;
  final Map<String, int> bestSeconds;
  bool pro;
  int freePlaySinceAd;

  int get level => xp ~/ 500 + 1;
  int get xpIntoLevel => xp % 500;
  double get levelProgress => xpIntoLevel / 500;
  double get averageSeconds => totalSolved == 0 ? 0 : totalSeconds / totalSolved;
  double get averageMoves => totalSolved == 0 ? 0 : totalMoves / totalSolved;

  String get rankName => switch (level) {
        <= 2 => 'Lookout',
        <= 4 => 'Lockpicker',
        <= 7 => 'Infiltrator',
        <= 11 => 'Phantom',
        _ => 'Mastermind',
      };

  bool isSkinUnlocked(MuseumSkin skin) => level >= switch (skin) {
        MuseumSkin.classic => 1,
        MuseumSkin.noir => 3,
        MuseumSkin.emerald => 6,
        MuseumSkin.neon => 10,
      };

  bool hasDailyCompletion(DateTime date, HeistDifficulty difficulty) =>
      dailyCompletions.contains('${dateKey(date)}:${difficulty.name}');

  ProgressReward recordCompletion({
    required DateTime completedAt,
    required GameMode mode,
    required HeistDifficulty difficulty,
    required int moves,
    required int seconds,
    required int hintsUsed,
    required int mistakes,
    required int difficultyScore,
  }) {
    final oldLevel = level;
    final key = '${dateKey(completedAt)}:${difficulty.name}';
    final isNewDaily = mode == GameMode.daily && !dailyCompletions.contains(key);
    if (mode == GameMode.daily && !isNewDaily) {
      return ProgressReward(
        xp: 0,
        newLevel: oldLevel,
        isNewDaily: false,
        isPerfect: false,
      );
    }

    final isPerfect = hintsUsed == 0 && mistakes == 0;
    final movePenalty = (moves - difficulty.size).clamp(0, 30) as int;
    final efficiency = (90 - movePenalty * 3).clamp(0, 90) as int;
    final hintPenalty = (hintsUsed * 20).clamp(0, 80) as int;
    final earned = (difficulty.baseXp +
            difficultyScore +
            efficiency +
            (isPerfect ? 60 : 0) +
            (mode == GameMode.daily ? 80 : 0) -
            hintPenalty)
        .clamp(25, 600) as int;

    xp += earned;
    totalSolved++;
    totalMoves += moves;
    totalSeconds += seconds;
    totalHints += hintsUsed;
    if (isPerfect) perfectSolved++;

    final difficultyKey = difficulty.name;
    final oldBestMoves = bestMoves[difficultyKey];
    if (oldBestMoves == null || moves < oldBestMoves) bestMoves[difficultyKey] = moves;
    final oldBestSeconds = bestSeconds[difficultyKey];
    if (oldBestSeconds == null || seconds < oldBestSeconds) {
      bestSeconds[difficultyKey] = seconds;
    }

    if (mode == GameMode.daily) {
      dailyCompletions.add(key);
      _recordDailyStreak(completedAt);
    } else {
      freePlaySinceAd++;
    }

    return ProgressReward(
      xp: earned,
      newLevel: level,
      isNewDaily: isNewDaily,
      isPerfect: isPerfect,
    );
  }

  void _recordDailyStreak(DateTime date) {
    final today = dateKey(date);
    if (lastDailyDate == today) return;
    final previous = DateTime(date.year, date.month, date.day).subtract(const Duration(days: 1));
    if (lastDailyDate == dateKey(previous)) {
      currentStreak++;
    } else {
      currentStreak = 1;
    }
    lastDailyDate = today;
    if (currentStreak > bestStreak) bestStreak = currentStreak;
  }

  Map<String, Object?> toJson() => {
        'xp': xp,
        'totalSolved': totalSolved,
        'totalMoves': totalMoves,
        'totalSeconds': totalSeconds,
        'totalHints': totalHints,
        'perfectSolved': perfectSolved,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastDailyDate': lastDailyDate,
        'dailyCompletions': dailyCompletions.toList(),
        'bestMoves': bestMoves,
        'bestSeconds': bestSeconds,
        'pro': pro,
        'freePlaySinceAd': freePlaySinceAd,
      };

  factory PlayerProgress.fromJson(Map<String, Object?> json) => PlayerProgress(
        xp: json['xp'] as int? ?? 0,
        totalSolved: json['totalSolved'] as int? ?? 0,
        totalMoves: json['totalMoves'] as int? ?? 0,
        totalSeconds: json['totalSeconds'] as int? ?? 0,
        totalHints: json['totalHints'] as int? ?? 0,
        perfectSolved: json['perfectSolved'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastDailyDate: json['lastDailyDate'] as String?,
        dailyCompletions: Set<String>.from(
          json['dailyCompletions'] as List<Object?>? ?? const [],
        ),
        bestMoves: _intMap(json['bestMoves']),
        bestSeconds: _intMap(json['bestSeconds']),
        pro: json['pro'] as bool? ?? false,
        freePlaySinceAd: json['freePlaySinceAd'] as int? ?? 0,
      );

  static Map<String, int> _intMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value as int));
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class ActiveGameData {
  ActiveGameData({
    required this.mode,
    required this.difficulty,
    required this.seed,
    required this.generatorVersion,
    required this.session,
    required this.elapsedSeconds,
  });

  final GameMode mode;
  final HeistDifficulty difficulty;
  final int seed;
  final int generatorVersion;
  Map<String, Object?> session;
  int elapsedSeconds;

  Map<String, Object?> toJson() => {
        'mode': mode.name,
        'difficulty': difficulty.name,
        'seed': seed,
        'generatorVersion': generatorVersion,
        'session': session,
        'elapsedSeconds': elapsedSeconds,
      };

  factory ActiveGameData.fromJson(Map<String, Object?> json) => ActiveGameData(
        mode: GameMode.values.firstWhere(
          (value) => value.name == json['mode'],
          orElse: () => GameMode.freePlay,
        ),
        difficulty: HeistDifficulty.values.firstWhere(
          (value) => value.name == json['difficulty'],
          orElse: () => HeistDifficulty.professional,
        ),
        seed: json['seed'] as int? ?? 1,
        generatorVersion: json['generatorVersion'] as int? ?? 1,
        session: Map<String, Object?>.from(json['session'] as Map? ?? const {}),
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      );
}

class PersistentState {
  PersistentState({
    GameSettings? settings,
    PlayerProgress? progress,
    this.onboardingDone = false,
    this.activeGame,
  })  : settings = settings ?? GameSettings(),
        progress = progress ?? PlayerProgress();

  final GameSettings settings;
  final PlayerProgress progress;
  bool onboardingDone;
  ActiveGameData? activeGame;

  Map<String, Object?> toJson() => {
        'schema': 2,
        'settings': settings.toJson(),
        'progress': progress.toJson(),
        'onboardingDone': onboardingDone,
        'activeGame': activeGame?.toJson(),
      };

  factory PersistentState.fromJson(Map<String, Object?> json) {
    final active = json['activeGame'];
    return PersistentState(
      settings: GameSettings.fromJson(
        Map<String, Object?>.from(json['settings'] as Map? ?? const {}),
      ),
      progress: PlayerProgress.fromJson(
        Map<String, Object?>.from(json['progress'] as Map? ?? const {}),
      ),
      onboardingDone: json['onboardingDone'] as bool? ?? false,
      activeGame: active is Map
          ? ActiveGameData.fromJson(Map<String, Object?>.from(active))
          : null,
    );
  }
}
