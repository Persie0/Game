import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import 'game_page.dart';
import 'game_style.dart';
import 'pro_page.dart';
import 'stats_settings.dart';

class MuseumHome extends StatefulWidget {
  const MuseumHome({super.key, required this.controller});

  final AppController controller;

  @override
  State<MuseumHome> createState() => _MuseumHomeState();
}

class _MuseumHomeState extends State<MuseumHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PlayTab(controller: widget.controller),
      StatsTab(controller: widget.controller),
      SettingsTab(controller: widget.controller),
    ];
    return Scaffold(
      extendBody: true,
      body: HeistBackdrop(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: pages),
        ),
      ),
      bottomNavigationBar: _HeistDock(
        selectedIndex: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _HeistDock extends StatelessWidget {
  const _HeistDock({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.key_rounded, 'HEISTS'),
    (Icons.query_stats_rounded, 'DOSSIER'),
    (Icons.tune_rounded, 'GEAR'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: dark ? const Color(0xF2111520) : const Color(0xF7FFF8EA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _DockItem(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  selected: selectedIndex == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.56);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.32),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 3),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayTab extends StatelessWidget {
  const PlayTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = controller.progress;
    final today = DateTime.now();
    final dailyDone = progress.hasDailyCompletion(
      today,
      HeistDifficulty.professional,
    );

    return ListView(
      key: const PageStorageKey('heists'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE GRAND MUSEUM',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Heist HQ', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 3),
                  Text(
                    '${progress.rankName} · Agent level ${progress.level}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.67),
                    ),
                  ),
                ],
              ),
            ),
            if (!controller.isPro)
              InkWell(
                onTap: () => _openPro(context),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    Icons.diamond_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: '${progress.xpIntoLevel} of 500 experience toward next level',
                child: HeistProgressBar(value: progress.levelProgress),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${progress.xpIntoLevel}/500 XP',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.active != null) ...[
          _ContinueMission(controller: controller),
          const SizedBox(height: 18),
        ],
        HeistSectionTitle(
          eyebrow: 'Priority target',
          title: "Today's Gallery",
          trailing: HeistBadge(
            icon: Icons.local_fire_department_rounded,
            label: '${progress.currentStreak} DAY',
            accent: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        _DailyMission(
          completed: dailyDone,
          onTap: () => _start(
            context,
            GameMode.daily,
            HeistDifficulty.professional,
          ),
        ),
        const SizedBox(height: 26),
        const HeistSectionTitle(
          eyebrow: 'Open cases',
          title: 'Choose a target',
        ),
        const SizedBox(height: 12),
        for (final difficulty in HeistDifficulty.values) ...[
          _DifficultyMission(
            difficulty: difficulty,
            bestMoves: progress.bestMoves[difficulty.name],
            bestSeconds: progress.bestSeconds[difficulty.name],
            onTap: () => _start(context, GameMode.freePlay, difficulty),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Align(child: controller.ads.banner(enabled: !controller.isPro)),
      ],
    );
  }

  Future<void> _start(
    BuildContext context,
    GameMode mode,
    HeistDifficulty difficulty,
  ) async {
    if (controller.active != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ABANDON CURRENT CASE?'),
          content: const Text(
            'Opening a new target will replace your unfinished heist. Career records remain safe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('KEEP CASE'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'ABANDON',
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (replace != true || !context.mounted) return;
    }

    await controller.startGame(mode: mode, difficulty: difficulty);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GamePage(controller: controller)),
    );
  }

  Future<void> _openPro(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProPage(controller: controller)),
      );
}

class _ContinueMission extends StatelessWidget {
  const _ContinueMission({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.active!;
    final theme = Theme.of(context);
    return HeistPanel(
      emphasis: true,
      accent: theme.colorScheme.secondary,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GamePage(controller: controller)),
      ),
      child: Row(
        children: [
          _MissionEmblem(
            icon: Icons.play_arrow_rounded,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE OPERATION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Continue current heist',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${game.data.difficulty.label} · ${game.session.moves} moves · ${formatTime(game.data.elapsedSeconds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.secondary),
        ],
      ),
    );
  }
}

class _DailyMission extends StatelessWidget {
  const _DailyMission({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeistPanel(
      emphasis: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MissionEmblem(
                icon: completed ? Icons.check_rounded : Icons.museum_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'ARTIFACT SECURED' : 'HIGH VALUE TARGET',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed ? 'Replay the gallery' : 'The Aurelia Collection',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'Daily reward already claimed · replay anytime'
                          : 'Professional · one attempt for today’s streak',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const HeistBadge(icon: Icons.grid_4x4_rounded, label: '6×6'),
              const SizedBox(width: 8),
              const HeistBadge(icon: Icons.flash_on_rounded, label: 'LASERS'),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyMission extends StatelessWidget {
  const _DifficultyMission({
    required this.difficulty,
    required this.bestMoves,
    required this.bestSeconds,
    required this.onTap,
  });

  final HeistDifficulty difficulty;
  final int? bestMoves;
  final int? bestSeconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (difficulty) {
      HeistDifficulty.rookie => const Color(0xFF4CA985),
      HeistDifficulty.professional => theme.colorScheme.primary,
      HeistDifficulty.mastermind => theme.colorScheme.secondary,
    };
    final subtitle = <String>[
      '${difficulty.size}×${difficulty.size}',
      '${difficulty.laserCount} lasers',
      if (bestMoves != null) 'record $bestMoves moves',
      if (bestSeconds != null) formatTime(bestSeconds!),
    ].join(' · ');

    return HeistPanel(
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      child: Row(
        children: [
          _MissionEmblem(
            icon: switch (difficulty) {
              HeistDifficulty.rookie => Icons.lock_open_rounded,
              HeistDifficulty.professional => Icons.key_rounded,
              HeistDifficulty.mastermind => Icons.diamond_rounded,
            },
            color: accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  difficulty.label.toUpperCase(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accent),
        ],
      ),
    );
  }
}

class _MissionEmblem extends StatelessWidget {
  const _MissionEmblem({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.48), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

String formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
