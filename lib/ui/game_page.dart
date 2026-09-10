import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../game/progress.dart';
import '../game/puzzle.dart';
import 'game_style.dart';
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
    Color(0xFF2F4358),
    Color(0xFF5A3949),
    Color(0xFF345344),
    Color(0xFF665431),
    Color(0xFF44395A),
    Color(0xFF31565B),
    Color(0xFF59442F),
    Color(0xFF364B63),
    Color(0xFF583D5C),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = widget.controller.active!;
    _elapsed = _game.data.elapsedSeconds;
    _startTimer();
  }

  void _startTimer() {
    if (_finished || _timer?.isActive == true) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished) setState(() => _elapsed++);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
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
    if (_finished) return;
    final suggestion = _game.session.nextHint();
    if (suggestion == null) return;
    final result = await widget.controller.requestHint(elapsedSeconds: _elapsed);
    if (!mounted) return;
    switch (result) {
      case HintRequestResult.applied:
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('INTEL: ${suggestion.message}')),
        );
        await _checkWin();
      case HintRequestResult.noHint:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No useful intel is available.')),
        );
      case HintRequestResult.requiresPro:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProPage(controller: widget.controller),
          ),
        );
    }
  }

  Future<void> _checkWin() async {
    if (!_game.session.isSolved || _finished) return;
    _finished = true;
    _timer?.cancel();
    widget.controller.feedback.success(widget.controller.settings);
    final completedMode = _game.data.mode;
    final reward = await widget.controller.completeActive(
      elapsedSeconds: _elapsed,
    );
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
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.diamond_rounded,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ARTIFACT SECURED',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '+${reward.xp} XP',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_game.session.moves} moves · ${_formatTime(_elapsed)}',
                  style: theme.textTheme.titleMedium,
                ),
                if (reward.isPerfect) ...[
                  const SizedBox(height: 14),
                  HeistBadge(
                    icon: Icons.auto_awesome_rounded,
                    label: 'PERFECT GETAWAY',
                    accent: theme.colorScheme.primary,
                  ),
                ],
                if (reward.xp == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Daily replay complete — today’s reward was already claimed.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: HeistButton(
                    label: 'RETURN TO HQ',
                    icon: Icons.key_rounded,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final animationDuration = settings.reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 140);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _game.data.mode == GameMode.daily
                  ? 'DAILY OPERATION'
                  : 'OPEN CASE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _game.data.mode == GameMode.daily
                  ? "Today's Gallery"
                  : _game.data.difficulty.label,
              style: theme.appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          Center(
            child: Semantics(
              label: 'Elapsed time ${_formatTime(_elapsed)}',
              child: HeistBadge(
                icon: Icons.schedule_rounded,
                label: _formatTime(_elapsed),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: HeistBackdrop(
        safeArea: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 74, 16, 30),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      HeistBadge(
                        icon: Icons.touch_app_rounded,
                        label: '${_game.session.moves} MOVES',
                      ),
                      HeistBadge(
                        icon: Icons.psychology_rounded,
                        label: '${_game.analysis.score} ${_game.analysis.label.toUpperCase()}',
                      ),
                      HeistBadge(
                        icon: Icons.lightbulb_outline_rounded,
                        label: widget.controller.isPro
                            ? '${_game.session.hintsUsed} INTEL · PRO'
                            : '${_game.session.hintsUsed}/2 INTEL',
                      ),
                      if (_game.session.mistakes > 0)
                        HeistBadge(
                          icon: Icons.warning_amber_rounded,
                          label: '${_game.session.mistakes} ALERTS',
                          accent: theme.colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  HeistPanel(
                    emphasis: true,
                    padding: const EdgeInsets.all(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize = min(constraints.maxWidth, 620.0);
                        return Align(
                          child: SizedBox.square(
                            dimension: boardSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                                    row: row,
                                    col: col,
                                    duration: animationDuration,
                                    regionColor: _regionColors[
                                      region % _regionColors.length
                                    ],
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: HeistButton(
                          label: 'UNDO',
                          icon: Icons.undo_rounded,
                          primary: false,
                          compact: true,
                          onPressed: _game.session.canUndo
                              ? () async {
                                  setState(_game.session.undo);
                                  await widget.controller.saveActive(
                                    elapsedSeconds: _elapsed,
                                  );
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeistButton(
                          label: 'RESET',
                          icon: Icons.restart_alt_rounded,
                          primary: false,
                          compact: true,
                          onPressed: () async {
                            setState(_game.session.reset);
                            await widget.controller.saveActive(
                              elapsedSeconds: _elapsed,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeistButton(
                          label: 'INTEL',
                          icon: Icons.lightbulb_outline_rounded,
                          compact: true,
                          onPressed: _hint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HeistPanel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.visibility_off_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'Tap: empty → thief → X. Long-press: X. One thief per row, column, and colored zone. Thieves cannot touch. Red laser rooms are blocked.',
                            style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    child: widget.controller.ads.banner(
                      enabled: !widget.controller.isPro,
                    ),
                  ),
                ],
              ),
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
    final strong = theme.colorScheme.primary.withValues(alpha: 0.82);
    final soft = Colors.white.withValues(alpha: 0.08);
    BorderSide side(bool boundary) => BorderSide(
          color: boundary ? strong : soft,
          width: boundary ? 2.2 : 0.7,
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
    required this.row,
    required this.col,
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

  final int row;
  final int col;
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
    final base = dark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.22), regionColor)
        : Color.lerp(regionColor, const Color(0xFFF7EFE0), 0.62)!;
    final background = conflict
        ? Color.alphaBlend(
            theme.colorScheme.error.withValues(alpha: 0.38),
            base,
          )
        : base;

    Widget child = const SizedBox.shrink(key: ValueKey('empty'));
    if (laser) {
      child = const _LaserGlyph(key: ValueKey('laser'));
    } else if (mark == CellMark.thief) {
      child = Container(
        key: const ValueKey('thief'),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          border: Border.all(color: theme.colorScheme.primary, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.28),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          size: 24,
          color: conflict ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      );
    } else if (mark == CellMark.blocked) {
      child = Icon(
        Icons.close_rounded,
        key: const ValueKey('blocked'),
        size: 24,
        color: dark ? Colors.white54 : Colors.black45,
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
      'Row ${row + 1}, column ${col + 1}',
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
                        color: dark ? Colors.white54 : Colors.black54,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                Center(
                  child: AnimatedSwitcher(duration: duration, child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaserGlyph extends StatelessWidget {
  const _LaserGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.65,
          child: Container(
            width: 38,
            height: 3,
            decoration: BoxDecoration(
              color: error,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(color: error.withValues(alpha: 0.72), blurRadius: 8),
              ],
            ),
          ),
        ),
        Icon(Icons.flash_on_rounded, color: error, size: 22),
      ],
    );
  }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
