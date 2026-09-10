import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import '../game/session.dart';
import 'pro_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final ActiveGameRuntime _game;
  Timer? _timer;
  late int _elapsed;
  bool _finished = false;

  static const _regionColors = <Color>[
    Color(0xFFFFD6E3),
    Color(0xFFD8E3FF),
    Color(0xFFD8F3C4),
    Color(0xFFFFE1B3),
    Color(0xFFE5D7FF),
    Color(0xFFC7EEE4),
    Color(0xFFFFF0AD),
    Color(0xFFD4EFFF),
    Color(0xFFF0D4FF),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = widget.controller.active!;
    _elapsed = _game.data.elapsedSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished) setState(() => _elapsed++);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(widget.controller.saveActive(elapsedSeconds: _elapsed));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (!_finished && widget.controller.active != null) {
      unawaited(widget.controller.saveActive(elapsedSeconds: _elapsed));
    }
    super.dispose();
  }

  Future<void> _tap(int row, int col) async {
    if (_finished) return;
    final changed = _game.session.cycle(
      row,
      col,
      autoCross: widget.controller.settings.autoCross,
    );
    if (!changed) return;
    widget.controller.feedback.tap(widget.controller.settings);
    setState(() {});
    await widget.controller.saveActive(elapsedSeconds: _elapsed);
    await _checkWin();
  }

  Future<void> _block(int row, int col) async {
    if (_finished || !_game.session.toggleBlocked(row, col)) return;
    widget.controller.feedback.tap(widget.controller.settings);
    setState(() {});
    await widget.controller.saveActive(elapsedSeconds: _elapsed);
  }

  Future<void> _hint() async {
    final suggestion = _game.session.nextHint();
    if (suggestion == null) return;
    final result = await widget.controller.requestHint(elapsedSeconds: _elapsed);
    if (!mounted) return;
    switch (result) {
      case HintRequestResult.applied:
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(suggestion.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _checkWin();
      case HintRequestResult.noHint:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No useful hint is available.')),
        );
      case HintRequestResult.requiresPro:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProPage(controller: widget.controller)),
        );
    }
  }

  Future<void> _checkWin() async {
    if (!_game.session.isSolved || _finished) return;
    _finished = true;
    _timer?.cancel();
    widget.controller.feedback.success(widget.controller.settings);
    final completedMode = _game.data.mode;
    final reward = await widget.controller.completeActive(elapsedSeconds: _elapsed);
    if (!mounted) return;
    await _showVictory(reward);
    if (!mounted) return;
    await widget.controller.maybeShowCompletionAd(completedMode);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _showVictory(ProgressReward reward) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.workspace_premium_rounded,
          color: theme.colorScheme.primary,
          size: 44,
        ),
        title: const Text('Artifact secured'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${reward.xp} XP',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('${_game.session.moves} moves · ${_formatTime(_elapsed)}'),
            if (reward.isPerfect) ...[
              const SizedBox(height: 8),
              const Chip(
                avatar: Icon(Icons.auto_awesome_rounded),
                label: Text('Perfect heist'),
              ),
            ],
            if (reward.xp == 0) ...[
              const SizedBox(height: 8),
              const Text('Daily replay complete — XP was already claimed.'),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back to HQ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = _game.puzzle;
    final settings = widget.controller.settings;
    final conflicts = settings.showConflicts
        ? PuzzleRules.conflicts(puzzle, _game.session.marks)
        : <CellPos>{};
    final animationDuration =
        settings.reducedMotion ? Duration.zero : const Duration(milliseconds: 140);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _game.data.mode == GameMode.daily
              ? "Today's Gallery"
              : _game.data.difficulty.label,
        ),
        actions: [
          Center(
            child: Semantics(
              label: 'Elapsed time ${_formatTime(_elapsed)}',
              child: Text(
                _formatTime(_elapsed),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.touch_app_rounded,
                      label: '${_game.session.moves} moves',
                    ),
                    _InfoChip(
                      icon: Icons.psychology_rounded,
                      label: '${_game.analysis.score} ${_game.analysis.label}',
                    ),
                    _InfoChip(
                      icon: Icons.lightbulb_outline_rounded,
                      label: widget.controller.isPro
                          ? '${_game.session.hintsUsed} hints · Pro'
                          : '${_game.session.hintsUsed}/2 free hints',
                    ),
                    if (_game.session.mistakes > 0)
                      _InfoChip(
                        icon: Icons.warning_amber_rounded,
                        label: '${_game.session.mistakes} mistakes',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = min(constraints.maxWidth, 620.0);
                    return Align(
                      child: SizedBox.square(
                        dimension: boardSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: puzzle.size,
                            ),
                            itemCount: puzzle.size * puzzle.size,
                            itemBuilder: (context, index) {
                              final row = index ~/ puzzle.size;
                              final col = index % puzzle.size;
                              final region = puzzle.regions[row][col];
                              return _RoomCell(
                                duration: animationDuration,
                                regionColor: _regionColors[region % _regionColors.length],
                                regionLabel: settings.regionLabels
                                    ? String.fromCharCode(65 + region)
                                    : null,
                                mark: _game.session.marks[row][col],
                                laser: puzzle.isLaser(row, col),
                                conflict: conflicts.contains((row: row, col: col)),
                                border: _cellBorder(puzzle, row, col, theme),
                                onTap: () => _tap(row, col),
                                onLongPress: () => _block(row, col),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _game.session.canUndo
                          ? () async {
                              setState(_game.session.undo);
                              await widget.controller.saveActive(elapsedSeconds: _elapsed);
                            }
                          : null,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(_game.session.reset);
                        await widget.controller.saveActive(elapsedSeconds: _elapsed);
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _hint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Hint'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tap cycles empty → thief → X. Long-press toggles X. One thief per row, column and color; thieves cannot touch. Laser rooms are blocked.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  child: widget.controller.ads.banner(enabled: !widget.controller.isPro),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Border _cellBorder(Puzzle puzzle, int row, int col, ThemeData theme) {
    final region = puzzle.regions[row][col];
    bool differs(int r, int c) =>
        r < 0 ||
        c < 0 ||
        r >= puzzle.size ||
        c >= puzzle.size ||
        puzzle.regions[r][c] != region;
    final strong = theme.colorScheme.onSurface.withValues(alpha: 0.70);
    final soft = theme.colorScheme.onSurface.withValues(alpha: 0.13);
    BorderSide side(bool boundary) => BorderSide(
          color: boundary ? strong : soft,
          width: boundary ? 2.4 : 0.6,
        );
    return Border(
      top: side(differs(row - 1, col)),
      right: side(differs(row, col + 1)),
      bottom: side(differs(row + 1, col)),
      left: side(differs(row, col - 1)),
    );
  }
}

class _RoomCell extends StatelessWidget {
  const _RoomCell({
    required this.duration,
    required this.regionColor,
    required this.regionLabel,
    required this.mark,
    required this.laser,
    required this.conflict,
    required this.border,
    required this.onTap,
    required this.onLongPress,
  });

  final Duration duration;
  final Color regionColor;
  final String? regionLabel;
  final CellMark mark;
  final bool laser;
  final bool conflict;
  final Border border;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final base = dark ? Color.alphaBlend(Colors.black54, regionColor) : regionColor;
    final background = conflict
        ? Color.alphaBlend(theme.colorScheme.error.withValues(alpha: 0.35), base)
        : base;

    Widget child = const SizedBox.shrink(key: ValueKey('empty'));
    if (laser) {
      child = Icon(
        Icons.flash_on_rounded,
        key: const ValueKey('laser'),
        color: theme.colorScheme.error,
      );
    } else if (mark == CellMark.thief) {
      child = Icon(
        Icons.person_rounded,
        key: const ValueKey('thief'),
        size: 34,
        color: conflict ? theme.colorScheme.error : theme.colorScheme.onSurface,
      );
    } else if (mark == CellMark.blocked) {
      child = Icon(
        Icons.close_rounded,
        key: const ValueKey('blocked'),
        size: 25,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.67),
      );
    }

    final stateLabel = laser
        ? 'laser room, unavailable'
        : switch (mark) {
            CellMark.empty => 'empty room',
            CellMark.blocked => 'room marked impossible',
            CellMark.thief => conflict ? 'thief with conflict' : 'thief',
          };
    final label = [
      'Row ${_rowLabel(context)}, column ${_columnLabel(context)}',
      if (regionLabel != null) 'zone $regionLabel',
      stateLabel,
    ].join(', ');

    return Semantics(
      button: !laser,
      label: label,
      child: Material(
        color: background,
        child: InkWell(
          onTap: laser ? null : onTap,
          onLongPress: laser ? null : onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(border: border),
            child: Stack(
              children: [
                if (regionLabel != null)
                  Positioned(
                    left: 5,
                    top: 3,
                    child: Text(
                      regionLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Center(child: AnimatedSwitcher(duration: duration, child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rowLabel(BuildContext context) => 'cell';
  String _columnLabel(BuildContext context) => 'cell';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
