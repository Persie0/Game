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
    if (marks.length != puzzle.size ||
        marks.any((row) => row.length != puzzle.size)) {
      return null;
    }

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
        if (marks[row][col] != CellMark.empty || puzzle.isLaser(row, col)) {
          continue;
        }
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

    // Some positions require a deeper search than the short explanations above.
    // The puzzle itself is solver-verified unique, so this fallback reveals one
    // safe cell without pretending it came from a simple local deduction.
    for (var row = 0; row < puzzle.size; row++) {
      final col = puzzle.solution[row];
      if (marks[row][col] != CellMark.thief) {
        return HintSuggestion(
          kind: HintKind.forcedPlacement,
          message:
              'No short deduction remains. The verified unique solution confirms row ${row + 1}, column ${col + 1} as a safe placement.',
          target: (row: row, col: col),
          mark: CellMark.thief,
        );
      }
    }
    return null;
  }
}
