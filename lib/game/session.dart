import 'hints.dart';
import 'puzzle.dart';

class CellChange {
  const CellChange({
    required this.row,
    required this.col,
    required this.before,
    required this.after,
  });

  final int row;
  final int col;
  final CellMark before;
  final CellMark after;

  Map<String, Object> toJson() => {
        'r': row,
        'c': col,
        'b': before.index,
        'a': after.index,
      };

  factory CellChange.fromJson(Map<String, Object?> json) => CellChange(
        row: json['r']! as int,
        col: json['c']! as int,
        before: CellMark.values[json['b']! as int],
        after: CellMark.values[json['a']! as int],
      );
}

class GameSession {
  GameSession(this.puzzle)
      : marks = List.generate(
          puzzle.size,
          (_) => List.filled(puzzle.size, CellMark.empty),
        ),
        _history = [],
        hintsUsed = 0,
        mistakes = 0;

  GameSession._(
    this.puzzle,
    this.marks,
    this._history,
    this.hintsUsed,
    this.mistakes,
  );

  final Puzzle puzzle;
  final List<List<CellMark>> marks;
  final List<List<CellChange>> _history;
  int hintsUsed;
  int mistakes;

  int get moves => _history.length;
  bool get canUndo => _history.isNotEmpty;
  bool get isSolved => PuzzleRules.isSolved(puzzle, marks);

  bool cycle(int row, int col, {bool autoCross = false}) {
    if (puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after = switch (before) {
      CellMark.empty => CellMark.thief,
      CellMark.thief => CellMark.blocked,
      CellMark.blocked => CellMark.empty,
    };
    return _applyAction(row, col, after, autoCross: autoCross);
  }

  bool toggleBlocked(int row, int col) {
    if (puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after = before == CellMark.blocked ? CellMark.empty : CellMark.blocked;
    return _applyAction(row, col, after);
  }

  HintSuggestion? nextHint() => HintEngine.next(puzzle, marks);

  bool applyHint(HintSuggestion hint, {bool autoCross = false}) {
    if (puzzle.isLaser(hint.target.row, hint.target.col)) return false;
    hintsUsed++;
    return _applyAction(
      hint.target.row,
      hint.target.col,
      hint.mark,
      autoCross: autoCross && hint.mark == CellMark.thief,
      countMistake: false,
    );
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final changes = _history.removeLast();
    for (final change in changes.reversed) {
      marks[change.row][change.col] = change.before;
    }
    return true;
  }

  void reset() {
    for (final row in marks) {
      row.fillRange(0, row.length, CellMark.empty);
    }
    _history.clear();
    hintsUsed = 0;
    mistakes = 0;
  }

  bool _applyAction(
    int row,
    int col,
    CellMark after, {
    bool autoCross = false,
    bool countMistake = true,
  }) {
    final before = marks[row][col];
    if (before == after) return false;
    final changes = <CellChange>[];
    _set(row, col, after, changes);

    if (after == CellMark.thief && autoCross) {
      final thief = (row: row, col: col);
      for (var r = 0; r < puzzle.size; r++) {
        for (var c = 0; c < puzzle.size; c++) {
          if (r == row && c == col) continue;
          if (marks[r][c] != CellMark.empty || puzzle.isLaser(r, c)) continue;
          if (PuzzleRules.attacks(puzzle, thief, (row: r, col: c))) {
            _set(r, c, CellMark.blocked, changes);
          }
        }
      }
    }

    if (countMistake &&
        after == CellMark.thief &&
        PuzzleSolver.countSolutions(puzzle, marks: marks, limit: 1) == 0) {
      mistakes++;
    }
    _history.add(changes);
    return true;
  }

  void _set(int row, int col, CellMark after, List<CellChange> changes) {
    final before = marks[row][col];
    if (before == after) return;
    marks[row][col] = after;
    changes.add(CellChange(row: row, col: col, before: before, after: after));
  }

  Map<String, Object> toJson() => {
        'marks': [
          for (final row in marks) [for (final mark in row) mark.index],
        ],
        'history': [
          for (final action in _history)
            [for (final change in action) change.toJson()],
        ],
        'hintsUsed': hintsUsed,
        'mistakes': mistakes,
      };

  factory GameSession.fromJson(Puzzle puzzle, Map<String, Object?> json) {
    final rawMarks = json['marks'] as List<Object?>?;
    if (rawMarks == null || rawMarks.length != puzzle.size) {
      return GameSession(puzzle);
    }
    final marks = <List<CellMark>>[];
    for (final rawRow in rawMarks) {
      final values = rawRow as List<Object?>;
      if (values.length != puzzle.size) return GameSession(puzzle);
      marks.add([
        for (final value in values)
          CellMark.values[(value as int).clamp(0, CellMark.values.length - 1)],
      ]);
    }

    final history = <List<CellChange>>[];
    final rawHistory = json['history'] as List<Object?>? ?? const [];
    for (final rawAction in rawHistory) {
      final action = <CellChange>[];
      for (final rawChange in rawAction as List<Object?>) {
        action.add(
          CellChange.fromJson(
            Map<String, Object?>.from(rawChange! as Map),
          ),
        );
      }
      history.add(action);
    }

    return GameSession._(
      puzzle,
      marks,
      history,
      json['hintsUsed'] as int? ?? 0,
      json['mistakes'] as int? ?? 0,
    );
  }
}
