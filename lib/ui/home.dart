import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import 'game_page.dart';
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
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.key_rounded), label: 'Heists'),
          NavigationDestination(icon: Icon(Icons.query_stats_rounded), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Settings'),
        ],
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
    final dailyDone = progress.hasDailyCompletion(today, HeistDifficulty.professional);

    return ListView(
      key: const PageStorageKey('heists'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Museum Heist',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.rankName} · Level ${progress.level}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (!controller.isPro)
              IconButton.filledTonal(
                tooltip: 'Museum Heist Pro',
                onPressed: () => _openPro(context),
                icon: const Icon(Icons.workspace_premium_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '${progress.xpIntoLevel} of 500 experience toward next level',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress.levelProgress, minHeight: 8),
          ),
        ),
        const SizedBox(height: 24),
        if (controller.active != null) ...[
          _ContinueCard(controller: controller),
          const SizedBox(height: 16),
        ],
        Card(
          child: InkWell(
            onTap: () => _start(
              context,
              GameMode.daily,
              HeistDifficulty.professional,
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      dailyDone ? Icons.check_rounded : Icons.calendar_today_rounded,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Gallery",
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dailyDone
                              ? 'Secured today · replay anytime'
                              : '${progress.currentStreak} day streak · Professional',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose a target',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final difficulty in HeistDifficulty.values) ...[
          _DifficultyCard(
            difficulty: difficulty,
            bestMoves: progress.bestMoves[difficulty.name],
            bestSeconds: progress.bestSeconds[difficulty.name],
            onTap: () => _start(context, GameMode.freePlay, difficulty),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Align(
          child: controller.ads.banner(enabled: !controller.isPro),
        ),
      ],
    );
  }

  Future<void> _start(
    BuildContext context,
    GameMode mode,
    HeistDifficulty difficulty,
  ) async {
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

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.active!;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
        title: const Text(
          'Continue current heist',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${game.data.difficulty.label} · ${game.session.moves} moves · ${formatTime(game.data.elapsedSeconds)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GamePage(controller: controller)),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
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
    final base = '${difficulty.size}×${difficulty.size} · ${difficulty.laserCount} lasers';
    final records = <String>[
      if (bestMoves != null) 'best $bestMoves moves',
      if (bestSeconds != null) formatTime(bestSeconds!),
    ];
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          child: Text('${difficulty.size}'),
        ),
        title: Text(difficulty.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(records.isEmpty ? base : '$base · ${records.join(' · ')}'),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: onTap,
      ),
    );
  }
}

String formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
