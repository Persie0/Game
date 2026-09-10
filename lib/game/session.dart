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
    if (!_inBounds(row, col) || puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after = switch (before) {
      CellMark.empty => CellMark.thief,
      CellMark.thief => CellMark.blocked,
      CellMark.blocked => CellMark.empty,
    };
    return _applyAction(row, col, after, autoCross: autoCross);
  }

  bool toggleBlocked(int row, int col) {
    if (!_inBounds(row, col) || puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after =
        before == CellMark.blocked ? CellMark.empty : CellMark.blocked;
    return _applyAction(row, col, after);
  }

  HintSuggestion? nextHint() => HintEngine.next(puzzle, marks);

  bool applyHint(HintSuggestion hint, {bool autoCross = false}) {
    final row = hint.target.row;
    final col = hint.target.col;
    if (!_inBounds(row, col) || puzzle.isLaser(row, col)) return false;
    final applied = _applyAction(
      row,
      col,
      hint.mark,
      autoCross: autoCross && hint.mark == CellMark.thief,
      countMistake: false,
    );
    if (applied) hintsUsed++;
    return applied;
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
    // Hints and mistakes intentionally survive a board reset. Otherwise a
    // player could use assistance, reset, and still earn a "perfect" clear.
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

  bool _inBounds(int row, int col) =>
      row >= 0 && row < puzzle.size && col >= 0 && col < puzzle.size;

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
    final rawMarks = json['marks'];
    if (rawMarks is! List || rawMarks.length != puzzle.size) {
      return GameSession(puzzle);
    }

    final marks = <List<CellMark>>[];
    for (final rawRow in rawMarks) {
      if (rawRow is! List || rawRow.length != puzzle.size) {
        return GameSession(puzzle);
      }
      final row = <CellMark>[];
      for (final value in rawRow) {
        final index = _readInt(value);
        if (index == null || index < 0 || index >= CellMark.values.length) {
          return GameSession(puzzle);
        }
        row.add(CellMark.values[index]);
      }
      marks.add(row);
    }

    // Laser cells can never contain user marks. Sanitizing them protects
    // against stale/corrupt saves without throwing away the rest of a puzzle.
    for (final laser in puzzle.lasers) {
      marks[laser.row][laser.col] = CellMark.empty;
    }

    final history = <List<CellChange>>[];
    final rawHistory = json['history'];
    var historyValid = rawHistory == null || rawHistory is List;
    if (rawHistory is List) {
      for (final rawAction in rawHistory) {
        if (rawAction is! List) {
          historyValid = false;
          break;
        }
        final action = <CellChange>[];
        for (final rawChange in rawAction) {
          if (rawChange is! Map) {
            historyValid = false;
            break;
          }
          final map = Map<String, Object?>.from(rawChange);
          final row = _readInt(map['r']);
          final col = _readInt(map['c']);
          final before = _readInt(map['b']);
          final after = _readInt(map['a']);
          if (row == null ||
              col == null ||
              before == null ||
              after == null ||
              row < 0 ||
              row >= puzzle.size ||
              col < 0 ||
              col >= puzzle.size ||
              before < 0 ||
              before >= CellMark.values.length ||
              after < 0 ||
              after >= CellMark.values.length ||
              puzzle.isLaser(row, col)) {
            historyValid = false;
            break;
          }
          action.add(
            CellChange(
              row: row,
              col: col,
              before: CellMark.values[before],
              after: CellMark.values[after],
            ),
          );
        }
        if (!historyValid) break;
        if (action.isNotEmpty) history.add(action);
      }
    }

    return GameSession._(
      puzzle,
      marks,
      historyValid ? history : <List<CellChange>>[],
      _readNonNegativeInt(json['hintsUsed']),
      _readNonNegativeInt(json['mistakes']),
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    return null;
  }

  static int _readNonNegativeInt(Object? value) {
    final parsed = _readInt(value) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }
}
