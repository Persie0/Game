import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/game/puzzle.dart';
import 'package:museum_heist/game/session.dart';

void main() {
  group('generator', () {
    test('fixed seed is deterministic', () {
      final generator = PuzzleGenerator();
      final a = generator.generate(
        difficulty: HeistDifficulty.professional,
        seed: 424242,
      );
      final b = generator.generate(
        difficulty: HeistDifficulty.professional,
        seed: 424242,
      );

      expect(a.solution, b.solution);
      expect(a.regions, b.regions);
      expect(a.lasers, b.lasers);
    });

    test('generated puzzle has exactly one solution', () {
      final generator = PuzzleGenerator();
      for (final difficulty in HeistDifficulty.values) {
        final puzzle = generator.generate(
          difficulty: difficulty,
          seed: 12345 + difficulty.index,
        );
        expect(generator.countSolutions(puzzle), 1);
      }
    });

    test('known solution satisfies all rules and avoids lasers', () {
      final puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.mastermind,
        seed: 998877,
      );
      final marks = List.generate(
        puzzle.size,
        (row) => List.generate(
          puzzle.size,
          (col) => puzzle.solution[row] == col ? CellMark.thief : CellMark.empty,
        ),
      );

      for (var row = 0; row < puzzle.size; row++) {
        expect(puzzle.isLaser(row, puzzle.solution[row]), isFalse);
      }
      expect(PuzzleRules.isSolved(puzzle, marks), isTrue);
    });
  });

  group('session and validation', () {
    late Puzzle puzzle;
    late GameSession session;

    setUp(() {
      puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.professional,
        seed: 424242,
      );
      session = GameSession(puzzle);
    });

    test('undo restores the previous mark', () {
      final col = puzzle.solution[0];
      expect(session.cycle(0, col), isTrue);
      expect(session.marks[0][col], CellMark.thief);
      expect(session.undo(), isTrue);
      expect(session.marks[0][col], CellMark.empty);
    });

    test('laser cells cannot be edited', () {
      final laser = puzzle.lasers.first;
      expect(session.cycle(laser.row, laser.col), isFalse);
      expect(session.marks[laser.row][laser.col], CellMark.empty);
    });

    test('same-row thieves are reported as conflicts', () {
      var first = -1;
      var second = -1;
      for (var col = 0; col < puzzle.size; col++) {
        if (puzzle.isLaser(0, col)) continue;
        if (first == -1) {
          first = col;
        } else {
          second = col;
          break;
        }
      }
      session.cycle(0, first);
      session.cycle(0, second);

      final conflicts = PuzzleRules.conflicts(puzzle, session.marks);
      expect(conflicts.contains((row: 0, col: first)), isTrue);
      expect(conflicts.contains((row: 0, col: second)), isTrue);
    });
  });
}
