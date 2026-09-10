import 'puzzle.dart';

enum HintKind { conflict, forcedPlacement, contradiction }

class HintSuggestion {
  const HintSuggestion({
    required this.kind,
    required this.message,
    required this.target,
    required this.mark,
  });

  final HintKind kind;
  final String message;
  final CellPos target;
  final CellMark mark;
}

class HintEngine {
  static HintSuggestion? next(Puzzle puzzle, List<List<CellMark>> marks) {
    final conflicts = PuzzleRules.conflicts(puzzle, marks);
    if (conflicts.isNotEmpty) {
      final target = conflicts.first;
      return HintSuggestion(
        kind: HintKind.conflict,
        message:
            'This thief clashes with another thief by row, column, zone, or adjacency. Remove it and reconsider the nearby rooms.',
        target: target,
        mark: CellMark.blocked,
      );
    }

    for (var row = 0; row < puzzle.size; row++) {
      final viable = PuzzleSolver.viableCandidatesForRow(puzzle, marks, row);
      if (viable.length == 1) {
        return HintSuggestion(
          kind: HintKind.forcedPlacement,
          message:
              'Row ${row + 1} has only one room that can still lead to a complete heist.',
          target: viable.single,
          mark: CellMark.thief,
        );
      }
    }

    for (var row = 0; row < puzzle.size; row++) {
      for (var col = 0; col < puzzle.size; col++) {
        if (marks[row][col] != CellMark.empty || puzzle.isLaser(row, col)) continue;
        final target = (row: row, col: col);
        final solutions = PuzzleSolver.countSolutions(
          puzzle,
          marks: marks,
          forceThief: target,
          limit: 1,
        );
        if (solutions == 0) {
          return HintSuggestion(
            kind: HintKind.contradiction,
            message:
                'If a thief enters row ${row + 1}, column ${col + 1}, no complete solution remains. Mark this room X.',
            target: target,
            mark: CellMark.blocked,
          );
        }
      }
    }

    for (var row = 0; row < puzzle.size; row++) {
      final col = puzzle.solution[row];
      if (marks[row][col] != CellMark.thief) {
        return HintSuggestion(
          kind: HintKind.forcedPlacement,
          message:
              'Global elimination leaves row ${row + 1}, column ${col + 1} as the forced room.',
          target: (row: row, col: col),
          mark: CellMark.thief,
        );
      }
    }
    return null;
  }
}
