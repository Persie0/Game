import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/game/hints.dart';
import 'package:museum_heist/game/puzzle.dart';
import 'package:museum_heist/game/session.dart';

void main() {
  group('generator and solver', () {
    test('fixed seed is deterministic and unique', () {
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
      expect(PuzzleSolver.countSolutions(a), 1);
    });

    test('every difficulty produces a valid known solution', () {
      for (final difficulty in HeistDifficulty.values) {
        final puzzle = PuzzleGenerator().generate(
          difficulty: difficulty,
          seed: 12000 + difficulty.index,
        );
        final marks = List.generate(
          puzzle.size,
          (row) => List.generate(
            puzzle.size,
            (col) => puzzle.solution[row] == col
                ? CellMark.thief
                : CellMark.empty,
          ),
        );
        expect(PuzzleRules.isSolved(puzzle, marks), isTrue);
        expect(PuzzleSolver.countSolutions(puzzle), 1);
      }
    });

    test('at least one laser is essential to puzzle uniqueness', () {
      final puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.professional,
        seed: 424242,
      );
      var foundEssentialLaser = false;
      for (final laser in puzzle.lasers) {
        final reduced = Puzzle(
          size: puzzle.size,
          regions: puzzle.regions,
          solution: puzzle.solution,
          lasers: {...puzzle.lasers}..remove(laser),
          seed: puzzle.seed,
          version: puzzle.version,
        );
        if (PuzzleSolver.countSolutions(reduced, limit: 2) > 1) {
          foundEssentialLaser = true;
          break;
        }
      }
      expect(foundEssentialLaser, isTrue);
    });

    test('daily puzzle seed is versioned and deterministic', () {
      final generator = PuzzleGenerator();
      final date = DateTime(2026, 9, 10);
      final a = generator.dailySeed(date, HeistDifficulty.professional);
      final b = generator.dailySeed(date, HeistDifficulty.professional);
      expect(a, b);
      expect(a, greaterThan(3000000000));
    });

    test('difficulty analysis is stable and bounded', () {
      final puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.mastermind,
        seed: 998877,
      );
      final first = PuzzleSolver.analyze(puzzle);
      final second = PuzzleSolver.analyze(puzzle);
      expect(first.score, second.score);
      expect(first.score, inInclusiveRange(1, 100));
      expect(first.visitedNodes, greaterThan(0));
    });

    test('solver rejects malformed force coordinates', () {
      final puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.rookie,
        seed: 22001,
      );
      expect(
        PuzzleSolver.countSolutions(
          puzzle,
          forceThief: (row: -1, col: 0),
        ),
        0,
      );
    });
  });

  group('session', () {
    late Puzzle puzzle;
    late GameSession session;

    setUp(() {
      puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.professional,
        seed: 424242,
      );
      session = GameSession(puzzle);
    });

    test('auto-cross is one undoable action', () {
      final col = puzzle.solution[0];
      expect(session.cycle(0, col, autoCross: true), isTrue);
      expect(session.marks[0][col], CellMark.thief);
      expect(
        session.marks.expand((row) => row).where((m) => m == CellMark.blocked),
        isNotEmpty,
      );
      expect(session.moves, 1);
      expect(session.undo(), isTrue);
      expect(
        session.marks.expand((row) => row).every((m) => m == CellMark.empty),
        isTrue,
      );
    });

    test('laser cells and out-of-range cells cannot be edited', () {
      final laser = puzzle.lasers.first;
      expect(session.cycle(laser.row, laser.col), isFalse);
      expect(session.toggleBlocked(laser.row, laser.col), isFalse);
      expect(session.cycle(-1, 0), isFalse);
      expect(session.toggleBlocked(puzzle.size, 0), isFalse);
    });

    test('session round-trips marks and undo history', () {
      final col = puzzle.solution[0];
      session.cycle(0, col, autoCross: true);
      final restored = GameSession.fromJson(puzzle, session.toJson());
      expect(restored.marks, session.marks);
      expect(restored.moves, session.moves);
      expect(restored.canUndo, isTrue);
      expect(restored.undo(), isTrue);
    });

    test('reset cannot erase hint usage for a perfect-clear exploit', () {
      final hint = session.nextHint();
      expect(hint, isNotNull);
      expect(session.applyHint(hint!), isTrue);
      expect(session.hintsUsed, 1);
      session.reset();
      expect(session.hintsUsed, 1);
      expect(session.moves, 0);
      expect(
        session.marks.expand((row) => row).every((mark) => mark == CellMark.empty),
        isTrue,
      );
    });

    test('a repeated no-op hint does not increase hint usage', () {
      final hint = session.nextHint();
      expect(hint, isNotNull);
      expect(session.applyHint(hint!), isTrue);
      expect(session.hintsUsed, 1);
      expect(session.applyHint(hint), isFalse);
      expect(session.hintsUsed, 1);
    });

    test('malformed saved history is discarded without losing valid marks', () {
      final col = puzzle.solution[0];
      session.cycle(0, col);
      final json = Map<String, Object?>.from(session.toJson());
      json['history'] = [
        [
          {'r': 999, 'c': 0, 'b': 0, 'a': 2},
        ],
      ];
      final restored = GameSession.fromJson(puzzle, json);
      expect(restored.marks[0][col], CellMark.thief);
      expect(restored.canUndo, isFalse);
    });
  });

  group('logical hints', () {
    test('hint move remains compatible with a valid completion', () {
      final puzzle = PuzzleGenerator().generate(
        difficulty: HeistDifficulty.rookie,
        seed: 22001,
      );
      final session = GameSession(puzzle);
      final hint = HintEngine.next(puzzle, session.marks);
      expect(hint, isNotNull);
      expect(session.applyHint(hint!), isTrue);
      expect(
        PuzzleSolver.countSolutions(puzzle, marks: session.marks, limit: 1),
        1,
      );
    });
  });
}
