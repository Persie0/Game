import 'dart:math';

import 'package:flutter/material.dart';

import 'game/puzzle.dart';
import 'game/session.dart';

void main() => runApp(const MuseumHeistApp());

class MuseumHeistApp extends StatelessWidget {
  const MuseumHeistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Museum Heist',
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const GameScreen(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4B43C4),
        brightness: brightness,
      ),
    );
  }
}

enum GameMode { daily, freePlay }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final PuzzleGenerator _generator = PuzzleGenerator();
  late GameSession _session;
  HeistDifficulty _difficulty = HeistDifficulty.professional;
  GameMode _mode = GameMode.daily;
  bool _showRules = false;
  bool _winShown = false;

  static const _regionColors = <Color>[
    Color(0xFFFFD7E4),
    Color(0xFFD8E2FF),
    Color(0xFFD9F4C7),
    Color(0xFFFFE4B8),
    Color(0xFFE8DBFF),
    Color(0xFFC5EEE5),
    Color(0xFFFFF0B0),
    Color(0xFFD5F0FF),
    Color(0xFFF2D6FF),
  ];

  @override
  void initState() {
    super.initState();
    _startPuzzle();
  }

  void _startPuzzle() {
    final seed = _mode == GameMode.daily
        ? _generator.dailySeed(DateTime.now(), _difficulty)
        : null;
    _session = GameSession(
      _generator.generate(difficulty: _difficulty, seed: seed),
    );
    _winShown = false;
  }

  void _changeDifficulty(HeistDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _startPuzzle();
    });
  }

  void _changeMode(Set<GameMode> values) {
    if (values.isEmpty) return;
    setState(() {
      _mode = values.first;
      _startPuzzle();
    });
  }

  void _onTap(int row, int col) {
    setState(() => _session.cycle(row, col));
    _checkWin();
  }

  void _onLongPress(int row, int col) {
    setState(() => _session.toggleBlocked(row, col));
    _checkWin();
  }

  void _hint() {
    setState(_session.revealHint);
    _checkWin();
  }

  void _checkWin() {
    if (!_session.isSolved || _winShown) return;
    _winShown = true;
    Future<void>.delayed(const Duration(milliseconds: 180), _showWinDialog);
  }

  Future<void> _showWinDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded),
        title: const Text('Artifact secured'),
        content: Text(
          _mode == GameMode.daily
              ? 'Daily heist complete in ${_session.moves} moves.'
              : 'Clean getaway in ${_session.moves} moves.',
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _mode = GameMode.freePlay;
                _startPuzzle();
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next heist'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _session.puzzle;
    final conflicts = PuzzleRules.conflicts(puzzle, _session.marks);
    final theme = Theme.of(context);
    final galleryNumber = (puzzle.seed % 9000) + 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Museum Heist'),
        actions: [
          IconButton(
            tooltip: 'How to play',
            onPressed: () => setState(() => _showRules = !_showRules),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                SegmentedButton<GameMode>(
                  segments: const [
                    ButtonSegment(
                      value: GameMode.daily,
                      icon: Icon(Icons.calendar_today_rounded),
                      label: Text('Daily Heist'),
                    ),
                    ButtonSegment(
                      value: GameMode.freePlay,
                      icon: Icon(Icons.all_inclusive_rounded),
                      label: Text('Free Play'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _changeMode,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mode == GameMode.daily
                                ? 'Today’s Gallery'
                                : 'Gallery $galleryNumber',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'One thief per row, column and security zone. Thieves can’t touch.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<HeistDifficulty>(
                      value: _difficulty,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(16),
                      items: [
                        for (final item in HeistDifficulty.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) _changeDifficulty(value);
                      },
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _showRules
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Tap: empty → thief → X. Long-press toggles an X. Every colored zone needs exactly one thief. Thieves may not share a row or column, touch—even diagonally—or stand on a laser cell.',
                        ),
                      ),
                    ),
                  ),
                  secondChild: const SizedBox(height: 14),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      icon: Icons.touch_app_rounded,
                      label: '${_session.moves} moves',
                    ),
                    _StatChip(
                      icon: Icons.grid_view_rounded,
                      label: '${puzzle.size}×${puzzle.size}',
                    ),
                    _StatChip(
                      icon: Icons.flash_on_rounded,
                      label: '${puzzle.lasers.length} lasers',
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
                          borderRadius: BorderRadius.circular(22),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: puzzle.size,
                            ),
                            itemCount: puzzle.size * puzzle.size,
                            itemBuilder: (context, index) {
                              final row = index ~/ puzzle.size;
                              final col = index % puzzle.size;
                              final region = puzzle.regions[row][col];
                              return _RoomCell(
                                regionColor: _regionColors[region % _regionColors.length],
                                mark: _session.marks[row][col],
                                laser: puzzle.isLaser(row, col),
                                conflict: conflicts.contains((row: row, col: col)),
                                border: _cellBorder(puzzle, row, col, theme),
                                onTap: () => _onTap(row, col),
                                onLongPress: () => _onLongPress(row, col),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _session.canUndo ? () => setState(_session.undo) : null,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(_session.reset),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _hint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Hint'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Laser rooms are permanently guarded. Red thief markers show an active rule conflict.',
                          ),
                        ),
                      ],
                    ),
                  ),
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

    final strong = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final soft = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    BorderSide side(bool strongSide) => BorderSide(
          color: strongSide ? strong : soft,
          width: strongSide ? 2.5 : 0.5,
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
    required this.regionColor,
    required this.mark,
    required this.laser,
    required this.conflict,
    required this.border,
    required this.onTap,
    required this.onLongPress,
  });

  final Color regionColor;
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

    Widget? icon;
    if (laser) {
      icon = Icon(Icons.flash_on_rounded, color: theme.colorScheme.error, size: 26);
    } else if (mark == CellMark.thief) {
      icon = Icon(
        Icons.person_rounded,
        color: conflict ? theme.colorScheme.error : theme.colorScheme.onSurface,
        size: 34,
      );
    } else if (mark == CellMark.blocked) {
      icon = Icon(
        Icons.close_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        size: 25,
      );
    }

    final label = laser
        ? 'Laser room, unavailable'
        : switch (mark) {
            CellMark.empty => 'Empty room',
            CellMark.blocked => 'Room marked impossible',
            CellMark.thief => conflict ? 'Thief, conflict' : 'Thief',
          };

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
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
