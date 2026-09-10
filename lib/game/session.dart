import 'puzzle.dart';

class Move {
  const Move({required this.row, required this.col, required this.before, required this.after});

  final int row;
  final int col;
  final CellMark before;
  final CellMark after;
}

class GameSession {
  GameSession(this.puzzle)
      : marks = List.generate(
          puzzle.size,
          (_) => List.filled(puzzle.size, CellMark.empty),
        );

  final Puzzle puzzle;
  final List<List<CellMark>> marks;
  final List<Move> _history = [];

  int get moves => _history.length;
  bool get canUndo => _history.isNotEmpty;
  bool get isSolved => PuzzleRules.isSolved(puzzle, marks);

  bool cycle(int row, int col) {
    if (puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after = switch (before) {
      CellMark.empty => CellMark.thief,
      CellMark.thief => CellMark.blocked,
      CellMark.blocked => CellMark.empty,
    };
    _apply(row, col, before, after);
    return true;
  }

  bool toggleBlocked(int row, int col) {
    if (puzzle.isLaser(row, col)) return false;
    final before = marks[row][col];
    final after = before == CellMark.blocked ? CellMark.empty : CellMark.blocked;
    _apply(row, col, before, after);
    return true;
  }

  bool revealHint() {
    for (var row = 0; row < puzzle.size; row++) {
      final col = puzzle.solution[row];
      if (marks[row][col] != CellMark.thief) {
        final before = marks[row][col];
        _apply(row, col, before, CellMark.thief);
        return true;
      }
    }
    return false;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final move = _history.removeLast();
    marks[move.row][move.col] = move.before;
    return true;
  }

  void reset() {
    for (final row in marks) {
      row.fillRange(0, row.length, CellMark.empty);
    }
    _history.clear();
  }

  void _apply(int row, int col, CellMark before, CellMark after) {
    if (before == after) return;
    marks[row][col] = after;
    _history.add(Move(row: row, col: col, before: before, after: after));
  }
}
