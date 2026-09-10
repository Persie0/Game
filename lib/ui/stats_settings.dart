import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import 'pro_page.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = controller.progress;
    final achievements = [
      (
        icon: Icons.key_rounded,
        title: 'First score',
        detail: 'Complete your first gallery.',
        unlocked: p.totalSolved >= 1,
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: 'Clean getaway',
        detail: 'Complete a perfect heist without hints or mistakes.',
        unlocked: p.perfectSolved >= 1,
      ),
      (
        icon: Icons.local_fire_department_rounded,
        title: 'Inside job',
        detail: 'Reach a 7-day Daily Heist streak.',
        unlocked: p.bestStreak >= 7,
      ),
      (
        icon: Icons.psychology_rounded,
        title: 'Mastermind',
        detail: 'Reach reputation level 10.',
        unlocked: p.level >= 10,
      ),
      (
        icon: Icons.diamond_rounded,
        title: 'Collection complete',
        detail: 'Secure 100 artifacts.',
        unlocked: p.totalSolved >= 100,
      ),
    ];

    return ListView(
      key: const PageStorageKey('stats'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Career',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _RankCard(progress: p),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.65,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _MetricCard(value: '${p.totalSolved}', label: 'Artifacts secured'),
            _MetricCard(value: '${p.bestStreak}', label: 'Best daily streak'),
            _MetricCard(value: '${p.perfectSolved}', label: 'Perfect heists'),
            _MetricCard(
              value: p.totalSolved == 0 ? '—' : p.averageMoves.toStringAsFixed(1),
              label: 'Avg moves',
            ),
            _MetricCard(
              value: p.totalSolved == 0 ? '—' : _formatTime(p.averageSeconds.round()),
              label: 'Avg time',
            ),
            _MetricCard(value: '${p.totalHints}', label: 'Hints used'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Personal records',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (final difficulty in HeistDifficulty.values)
                ListTile(
                  leading: CircleAvatar(child: Text('${difficulty.size}')),
                  title: Text(difficulty.label),
                  subtitle: Text(
                    [
                      if (p.bestMoves[difficulty.name] != null)
                        '${p.bestMoves[difficulty.name]} moves',
                      if (p.bestSeconds[difficulty.name] != null)
                        _formatTime(p.bestSeconds[difficulty.name]!),
                    ].isEmpty
                        ? 'No clear yet'
                        : [
                            if (p.bestMoves[difficulty.name] != null)
                              '${p.bestMoves[difficulty.name]} moves',
                            if (p.bestSeconds[difficulty.name] != null)
                              _formatTime(p.bestSeconds[difficulty.name]!),
                          ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Achievements',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final achievement in achievements)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: achievement.unlocked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  achievement.icon,
                  color: achievement.unlocked ? theme.colorScheme.primary : theme.disabledColor,
                ),
              ),
              title: Text(
                achievement.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(achievement.detail),
              trailing: Icon(
                achievement.unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = controller.settings;
    final progress = controller.progress;
    return ListView(
      key: const PageStorageKey('settings'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Settings',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Appearance',
          children: [
            ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<AppThemeSetting>(
                value: settings.theme,
                underline: const SizedBox.shrink(),
                items: [
                  for (final value in AppThemeSetting.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_title(value.name)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.updateSettings((s) => s.theme = value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Museum skin'),
              subtitle: Text('${_title(settings.skin.name)} · unlock with reputation'),
              trailing: PopupMenuButton<MuseumSkin>(
                icon: const Icon(Icons.palette_outlined),
                onSelected: (skin) => controller.updateSettings((s) => s.skin = skin),
                itemBuilder: (_) => [
                  for (final skin in MuseumSkin.values)
                    PopupMenuItem(
                      value: skin,
                      enabled: progress.isSkinUnlocked(skin),
                      child: Row(
                        children: [
                          Expanded(child: Text(_title(skin.name))),
                          if (!progress.isSkinUnlocked(skin)) const Icon(Icons.lock_outline, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              value: settings.regionLabels,
              title: const Text('Region labels'),
              subtitle: const Text('Add A/B/C labels so regions do not rely on color alone.'),
              onChanged: (value) => controller.updateSettings((s) => s.regionLabels = value),
            ),
            SwitchListTile(
              value: settings.reducedMotion,
              title: const Text('Reduced motion'),
              onChanged: (value) => controller.updateSettings((s) => s.reducedMotion = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Gameplay',
          children: [
            SwitchListTile(
              value: settings.autoCross,
              title: const Text('Auto-mark impossible rooms'),
              subtitle: const Text('Placing a thief X-marks rooms it attacks; undo reverses the whole action.'),
              onChanged: (value) => controller.updateSettings((s) => s.autoCross = value),
            ),
            SwitchListTile(
              value: settings.showConflicts,
              title: const Text('Show conflicts'),
              subtitle: const Text('Highlight thief placements that violate a rule.'),
              onChanged: (value) => controller.updateSettings((s) => s.showConflicts = value),
            ),
            SwitchListTile(
              value: settings.haptics,
              title: const Text('Haptics'),
              onChanged: (value) => controller.updateSettings((s) => s.haptics = value),
            ),
            SwitchListTile(
              value: settings.sound,
              title: const Text('Sound effects'),
              onChanged: (value) => controller.updateSettings((s) => s.sound = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'Museum Heist Pro',
          children: [
            ListTile(
              leading: Icon(
                controller.isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              ),
              title: Text(controller.isPro ? 'Pro unlocked' : 'Unlock Pro'),
              subtitle: Text(
                controller.isPro ? 'No ads · unlimited hints' : 'Remove ads and unlock unlimited logical hints.',
              ),
              trailing: controller.isPro ? null : const Icon(Icons.chevron_right_rounded),
              onTap: controller.isPro
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProPage(controller: controller)),
                      ),
            ),
            if (!controller.isPro)
              ListTile(
                title: const Text('Restore purchases'),
                onTap: () async {
                  await controller.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore request sent to the store.')),
                    );
                  }
                },
              ),
          ],
        ),
        if (controller.ads.configured) ...[
          const SizedBox(height: 14),
          _Section(
            title: 'Privacy',
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Ad privacy choices'),
                subtitle: const Text('Review or change consent choices for advertising.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: controller.ads.showPrivacyOptions,
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _Section(
          title: 'Data',
          children: [
            ListTile(
              title: const Text('Reset game progress'),
              subtitle: const Text('Clears statistics and the active heist; keeps Pro.'),
              trailing: const Icon(Icons.delete_outline_rounded),
              onTap: () => _confirmReset(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears levels, streaks, statistics, achievements, and the active heist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.resetProgress();
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.rankName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text('Level ${progress.level} · ${progress.xp} total XP'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: progress.levelProgress, minHeight: 9),
            ),
            const SizedBox(height: 6),
            Text('${500 - progress.xpIntoLevel} XP to next level'),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _title(String value) => value[0].toUpperCase() + value.substring(1);
