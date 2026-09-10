import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import 'game_style.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        const HeistSectionTitle(
          eyebrow: 'Confidential dossier',
          title: 'Career record',
        ),
        const SizedBox(height: 14),
        HeistPanel(
          emphasis: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.rankName.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 3),
              Text('Agent level ${p.level}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${p.xp} total XP'),
              const SizedBox(height: 13),
              HeistProgressBar(value: p.levelProgress),
              const SizedBox(height: 7),
              Text(
                '${500 - p.xpIntoLevel} XP until next clearance level',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.63),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'FIELD METRICS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _Metric(value: '${p.totalSolved}', label: 'Artifacts secured', icon: Icons.diamond_rounded),
            _Metric(value: '${p.bestStreak}', label: 'Best daily streak', icon: Icons.local_fire_department_rounded),
            _Metric(value: '${p.perfectSolved}', label: 'Perfect heists', icon: Icons.auto_awesome_rounded),
            _Metric(
              value: p.totalSolved == 0 ? '—' : p.averageMoves.toStringAsFixed(1),
              label: 'Average moves',
              icon: Icons.touch_app_rounded,
            ),
            _Metric(
              value: p.totalSolved == 0 ? '—' : _formatTime(p.averageSeconds.round()),
              label: 'Average time',
              icon: Icons.schedule_rounded,
            ),
            _Metric(value: '${p.totalHints}', label: 'Intel used', icon: Icons.lightbulb_outline_rounded),
          ],
        ),
        const SizedBox(height: 24),
        const HeistSectionTitle(
          eyebrow: 'Personal bests',
          title: 'Case records',
        ),
        const SizedBox(height: 10),
        HeistPanel(
          child: Column(
            children: [
              for (var i = 0; i < HeistDifficulty.values.length; i++) ...[
                _RecordRow(
                  difficulty: HeistDifficulty.values[i],
                  moves: p.bestMoves[HeistDifficulty.values[i].name],
                  seconds: p.bestSeconds[HeistDifficulty.values[i].name],
                ),
                if (i != HeistDifficulty.values.length - 1)
                  Divider(
                    height: 22,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const HeistSectionTitle(
          eyebrow: 'Milestones',
          title: 'Achievements',
        ),
        const SizedBox(height: 10),
        for (final achievement in achievements) ...[
          HeistPanel(
            accent: achievement.unlocked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (achievement.unlocked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface)
                        .withValues(alpha: 0.10),
                    border: Border.all(
                      color: (achievement.unlocked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface)
                          .withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.unlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(achievement.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        achievement.detail,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(
                  achievement.unlocked
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  color: achievement.unlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final progress = controller.progress;
    return ListView(
      key: const PageStorageKey('settings'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        const HeistSectionTitle(
          eyebrow: 'Loadout configuration',
          title: 'Gear & preferences',
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'VISUAL KIT',
          icon: Icons.palette_outlined,
          children: [
            _ChoiceRow<AppThemeSetting>(
              title: 'Lighting',
              value: settings.theme,
              values: AppThemeSetting.values,
              label: (value) => _title(value.name),
              onChanged: (value) => controller.updateSettings((s) => s.theme = value),
            ),
            _SkinRow(controller: controller, progress: progress),
            _ToggleRow(
              icon: Icons.abc_rounded,
              title: 'Zone labels',
              subtitle: 'Show A/B/C labels so regions never rely on color alone.',
              value: settings.regionLabels,
              onChanged: (value) => controller.updateSettings((s) => s.regionLabels = value),
            ),
            _ToggleRow(
              icon: Icons.animation_rounded,
              title: 'Reduced motion',
              value: settings.reducedMotion,
              onChanged: (value) => controller.updateSettings((s) => s.reducedMotion = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'FIELD ASSISTS',
          icon: Icons.tune_rounded,
          children: [
            _ToggleRow(
              icon: Icons.auto_fix_high_rounded,
              title: 'Auto-mark impossible rooms',
              subtitle: 'Placing a thief X-marks attacked rooms; undo reverses the whole action.',
              value: settings.autoCross,
              onChanged: (value) => controller.updateSettings((s) => s.autoCross = value),
            ),
            _ToggleRow(
              icon: Icons.warning_amber_rounded,
              title: 'Show conflicts',
              subtitle: 'Highlight thief placements that violate a rule.',
              value: settings.showConflicts,
              onChanged: (value) => controller.updateSettings((s) => s.showConflicts = value),
            ),
            _ToggleRow(
              icon: Icons.vibration_rounded,
              title: 'Haptics',
              value: settings.haptics,
              onChanged: (value) => controller.updateSettings((s) => s.haptics = value),
            ),
            _ToggleRow(
              icon: Icons.volume_up_rounded,
              title: 'Sound effects',
              value: settings.sound,
              onChanged: (value) => controller.updateSettings((s) => s.sound = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: 'PRIVATE VAULT',
          icon: Icons.diamond_rounded,
          children: [
            _ActionRow(
              icon: controller.isPro ? Icons.verified_rounded : Icons.key_rounded,
              title: controller.isPro ? 'Pro access granted' : 'Unlock Museum Heist Pro',
              subtitle: controller.isPro
                  ? 'No ads · unlimited intel'
                  : 'Remove ads and unlock unlimited logical hints.',
              trailing: controller.isPro ? null : Icons.chevron_right_rounded,
              onTap: controller.isPro
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProPage(controller: controller)),
                      ),
            ),
            if (!controller.isPro)
              _ActionRow(
                icon: Icons.restore_rounded,
                title: 'Restore purchase',
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
            title: 'PRIVACY',
            icon: Icons.privacy_tip_outlined,
            children: [
              _ActionRow(
                icon: Icons.shield_outlined,
                title: 'Ad privacy choices',
                subtitle: 'Review or change consent choices for advertising.',
                trailing: Icons.chevron_right_rounded,
                onTap: controller.ads.showPrivacyOptions,
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _Section(
          title: 'ARCHIVE',
          icon: Icons.archive_outlined,
          children: [
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              title: 'Burn career file',
              subtitle: 'Reset statistics and the active heist. Pro access is kept.',
              trailing: Icons.chevron_right_rounded,
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
        title: const Text('BURN CAREER FILE?'),
        content: const Text(
          'This clears levels, streaks, statistics, achievements, and the active heist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'RESET',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.resetProgress();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeistPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.difficulty,
    required this.moves,
    required this.seconds,
  });

  final HeistDifficulty difficulty;
  final int? moves;
  final int? seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = [
      if (moves != null) '$moves moves',
      if (seconds != null) _formatTime(seconds!),
    ];
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.30),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${difficulty.size}',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(difficulty.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(record.isEmpty ? 'No clear yet' : record.join(' · ')),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 7),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        HeistPanel(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.light_mode_outlined, size: 21),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            items: [
              for (final item in values)
                DropdownMenuItem(value: item, child: Text(label(item))),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({required this.controller, required this.progress});

  final AppController controller;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.texture_rounded, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Museum finish', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('${_title(settings.skin.name)} · unlock with reputation'),
              ],
            ),
          ),
          PopupMenuButton<MuseumSkin>(
            icon: const Icon(Icons.expand_more_rounded),
            onSelected: (skin) => controller.updateSettings((s) => s.skin = skin),
            itemBuilder: (_) => [
              for (final skin in MuseumSkin.values)
                PopupMenuItem(
                  value: skin,
                  enabled: progress.isSkinUnlocked(skin),
                  child: Row(
                    children: [
                      Expanded(child: Text(_title(skin.name))),
                      if (!progress.isSkinUnlocked(skin))
                        const Icon(Icons.lock_outline_rounded, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) Icon(trailing, size: 20),
          ],
        ),
      ),
    );
  }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _title(String value) => value[0].toUpperCase() + value.substring(1);
