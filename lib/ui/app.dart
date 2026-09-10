import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import 'game_style.dart';
import 'home.dart';

class MuseumHeistApp extends StatelessWidget {
  const MuseumHeistApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final themeMode = switch (settings.theme) {
          AppThemeSetting.system => ThemeMode.system,
          AppThemeSetting.light => ThemeMode.light,
          AppThemeSetting.dark => ThemeMode.dark,
        };
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Museum Heist',
          themeMode: themeMode,
          theme: _theme(Brightness.light, settings.skin),
          darkTheme: _theme(Brightness.dark, settings.skin),
          home: controller.state.onboardingDone
              ? MuseumHome(controller: controller)
              : OnboardingScreen(controller: controller),
        );
      },
    );
  }

  ThemeData _theme(Brightness brightness, MuseumSkin skin) {
    final accent = switch (skin) {
      MuseumSkin.classic => const Color(0xFFC98A34),
      MuseumSkin.noir => const Color(0xFF8D9AAF),
      MuseumSkin.emerald => const Color(0xFF39B886),
      MuseumSkin.neon => const Color(0xFFB25CFF),
    };
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF090B12) : const Color(0xFFF2ECE1);
    final surface = dark ? const Color(0xFF151925) : const Color(0xFFFFFBF3);
    final onSurface = dark ? const Color(0xFFF2F0EA) : const Color(0xFF201D1A);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary:
          ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
              ? Colors.white
              : Colors.black,
      secondary: dark ? const Color(0xFFDD4E66) : const Color(0xFFA92E46),
      onSecondary: Colors.white,
      error: const Color(0xFFE34D59),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    final base = ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: onSurface.withValues(alpha: 0.12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF202637) : const Color(0xFF302B26),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _stage = 0;
  final Set<int> _thieves = <int>{};
  final Set<int> _blocked = <int>{};

  static const _firstTarget = 1;
  static const _secondTarget = 11;
  static const _laserCell = 9;

  void _advance() {
    if (_stage < 4) {
      setState(() => _stage++);
    }
  }

  void _tapTutorialCell(int index) {
    if (_stage == 1 && index == _firstTarget) {
      setState(() {
        _thieves.add(index);
        _blocked.addAll(const [0, 2, 4, 5, 6]);
        _stage = 2;
      });
      widget.controller.feedback.tap(widget.controller.settings);
      return;
    }
    if (_stage == 2 && index == _secondTarget) {
      setState(() {
        _thieves.add(index);
        _blocked.addAll(const [3, 7, 10, 12, 14, 15]);
        _stage = 3;
      });
      widget.controller.feedback.tap(widget.controller.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Scaffold(
      body: HeistBackdrop(
        safeArea: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'CASE FILE 001',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.controller.completeOnboarding,
                      child: const Text('Skip training'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: widget.controller.settings.reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  child: _buildStage(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                                decoration: BoxDecoration(
                                  color: i <= _stage
                                      ? accent
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_stage + 1}/5',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    switch (_stage) {
      case 0:
        return _BriefingStage(onContinue: _advance);
      case 1:
      case 2:
      case 3:
        return _TrainingStage(
          stage: _stage,
          thieves: _thieves,
          blocked: _blocked,
          laserCell: _laserCell,
          firstTarget: _firstTarget,
          secondTarget: _secondTarget,
          onTap: _tapTutorialCell,
          onContinue: _stage == 3 ? _advance : null,
        );
      case 4:
        return _ReadyStage(
          onFinish: widget.controller.completeOnboarding,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BriefingStage extends StatelessWidget {
  const _BriefingStage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('briefing'),
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.28),
                      theme.colorScheme.primary.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.museum_rounded,
                  size: 62,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'WELCOME TO THE CREW',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every room is a puzzle.\nEvery move leaves a trace.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(height: 1.08),
              ),
              const SizedBox(height: 18),
              Text(
                'Place one thief in every row, column, and security zone without letting two thieves touch. Learn the rules in a 30-second training heist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 28),
              HeistPanel(
                accent: theme.colorScheme.secondary,
                child: const Row(
                  children: [
                    Icon(Icons.visibility_off_rounded, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Objective: infiltrate the gallery, avoid laser rooms, and leave no conflicting placements behind.',
                        style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: HeistButton(
                  label: 'BEGIN TRAINING',
                  icon: Icons.play_arrow_rounded,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingStage extends StatelessWidget {
  const _TrainingStage({
    required this.stage,
    required this.thieves,
    required this.blocked,
    required this.laserCell,
    required this.firstTarget,
    required this.secondTarget,
    required this.onTap,
    this.onContinue,
  });

  final int stage;
  final Set<int> thieves;
  final Set<int> blocked;
  final int laserCell;
  final int firstTarget;
  final int secondTarget;
  final ValueChanged<int> onTap;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instruction = switch (stage) {
      1 => ('STEP 1 · INFILTRATE', 'Tap the glowing room to place your first thief.'),
      2 => ('STEP 2 · SPREAD OUT', 'Auto-X marks rooms that thief can no longer use. Place the second thief in the glowing safe room.'),
      _ => ('STEP 3 · WATCH THE LASERS', 'Red laser rooms are permanently blocked. Never place a thief there.'),
    };

    return SingleChildScrollView(
      key: ValueKey('training-$stage'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                instruction.$1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instruction.$2,
                style: theme.textTheme.headlineSmall?.copyWith(height: 1.2),
              ),
              const SizedBox(height: 24),
              HeistPanel(
                emphasis: true,
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final target = (stage == 1 && index == firstTarget) ||
                          (stage == 2 && index == secondTarget);
                      final laser = index == laserCell;
                      final thief = thieves.contains(index);
                      final impossible = blocked.contains(index);
                      final zone = ((index ~/ 4) * 2 + (index % 4 ~/ 2)) % 4;
                      return _TutorialCell(
                        index: index,
                        zone: zone,
                        target: target,
                        laser: laser,
                        thief: thief,
                        blocked: impossible,
                        onTap: () => onTap(index),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  HeistBadge(icon: Icons.person_rounded, label: 'THIEF'),
                  HeistBadge(icon: Icons.close_rounded, label: 'IMPOSSIBLE'),
                  HeistBadge(icon: Icons.flash_on_rounded, label: 'LASER'),
                ],
              ),
              if (onContinue != null) ...[
                const SizedBox(height: 24),
                HeistButton(
                  label: 'RULES LOCKED IN',
                  icon: Icons.check_rounded,
                  onPressed: onContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialCell extends StatelessWidget {
  const _TutorialCell({
    required this.index,
    required this.zone,
    required this.target,
    required this.laser,
    required this.thief,
    required this.blocked,
    required this.onTap,
  });

  final int index;
  final int zone;
  final bool target;
  final bool laser;
  final bool thief;
  final bool blocked;
  final VoidCallback onTap;

  static const _zones = [
    Color(0xFF314A66),
    Color(0xFF5C3C53),
    Color(0xFF31584A),
    Color(0xFF655332),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final base = _zones[zone];
    final icon = laser
        ? Icons.flash_on_rounded
        : thief
            ? Icons.person_rounded
            : blocked
                ? Icons.close_rounded
                : null;
    final iconColor = laser
        ? theme.colorScheme.error
        : thief
            ? accent
            : Colors.white60;

    return Semantics(
      button: target,
      label: 'Training room ${index + 1}${target ? ', target room' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              target ? accent.withValues(alpha: 0.24) : Colors.transparent,
              base,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: target ? accent : Colors.white.withValues(alpha: 0.11),
              width: target ? 2.6 : 1,
            ),
            boxShadow: target
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: icon == null
              ? target
                  ? Icon(Icons.touch_app_rounded, color: accent)
                  : const SizedBox.shrink()
              : Icon(icon, color: iconColor, size: 30),
        ),
      ),
    );
  }
}

class _ReadyStage extends StatelessWidget {
  const _ReadyStage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('ready'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 78,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'TRAINING COMPLETE',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The gallery is open.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Solve heists to earn XP, build daily streaks, unlock museum skins, and chase perfect clears with zero hints or mistakes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              HeistPanel(
                child: Column(
                  children: const [
                    _RuleRow(icon: Icons.view_week_rounded, text: 'One thief per row, column, and colored zone'),
                    SizedBox(height: 14),
                    _RuleRow(icon: Icons.people_outline_rounded, text: 'Thieves may not touch, even diagonally'),
                    SizedBox(height: 14),
                    _RuleRow(icon: Icons.flash_on_rounded, text: 'Laser rooms are always off limits'),
                    SizedBox(height: 14),
                    _RuleRow(icon: Icons.undo_rounded, text: 'Undo is safe; hints and mistakes affect perfect clears'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: HeistButton(
                  label: 'ENTER HEIST HQ',
                  icon: Icons.key_rounded,
                  onPressed: onFinish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
      ],
    );
  }
}
