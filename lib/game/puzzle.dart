import 'dart:math';

enum CellMark { empty, blocked, thief }

enum HeistDifficulty {
  rookie(size: 5, laserCount: 2, label: 'Rookie'),
  professional(size: 6, laserCount: 4, label: 'Professional'),
  mastermind(size: 7, laserCount: 7, label: 'Mastermind');

  const HeistDifficulty({
    required this.size,
    required this.laserCount,
    required this.label,
  });

  final int size;
  final int laserCount;
  final String label;
}

typedef CellPos = ({int row, int col});

class Puzzle {
  const Puzzle({
    required this.size,
    required this.regions,
    required this.solution,
    required this.lasers,
    required this.seed,
  });

  final int size;
  final List<List<int>> regions;
  final List<int> solution; // row -> column
  final Set<CellPos> lasers;
  final int seed;

  bool isLaser(int row, int col) => lasers.contains((row: row, col: col));
}

class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  Puzzle generate({
    HeistDifficulty difficulty = HeistDifficulty.professional,
    int? seed,
  }) {
    return generateForSize(
      size: difficulty.size,
      laserCount: difficulty.laserCount,
      seed: seed,
    );
  }

  Puzzle generateForSize({
    required int size,
    int laserCount = 0,
    int? seed,
  }) {
    if (size < 4 || size > 9) {
      throw ArgumentError.value(size, 'size', 'Supported size is 4..9');
    }
    if (laserCount < 0 || laserCount > size * size - size) {
      throw ArgumentError.value(laserCount, 'laserCount');
    }

    final effectiveSeed = seed ?? _random.nextInt(0x7fffffff);
    final rng = Random(effectiveSeed);

    for (var attempt = 0; attempt < 3000; attempt++) {
      final solution = _makeSolution(size, rng);
      if (solution == null) continue;

      final regions = _growRegions(size, solution, rng);
      final basePuzzle = Puzzle(
        size: size,
        regions: regions,
        solution: solution,
        lasers: const {},
        seed: effectiveSeed,
      );

      if (countSolutions(basePuzzle, limit: 2) != 1) continue;

      final lasers = _placeLasers(size, solution, laserCount, rng);
      final puzzle = Puzzle(
        size: size,
        regions: regions,
        solution: solution,
        lasers: lasers,
        seed: effectiveSeed,
      );

      // Adding laser cells cannot create solutions, but keep this assertion in
      // the generation path so future constraint changes remain safe.
      if (countSolutions(puzzle, limit: 2) == 1) return puzzle;
    }

    throw StateError(
      'Could not generate a unique $size×$size puzzle for seed $effectiveSeed.',
    );
  }

  int dailySeed(DateTime localDate, HeistDifficulty difficulty) {
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    return date.year * 100000 + date.month * 1000 + date.day * 10 + difficulty.index;
  }

  int countSolutions(Puzzle puzzle, {int limit = 2}) {
    final size = puzzle.size;
    final usedColumns = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    var count = 0;

    void search(int row, int previousColumn) {
      if (count >= limit) return;
      if (row == size) {
        count++;
        return;
      }

      for (var col = 0; col < size; col++) {
        if (puzzle.isLaser(row, col) || usedColumns[col]) continue;
        final region = puzzle.regions[row][col];
        if (usedRegions[region]) continue;
        if (row > 0 && (col - previousColumn).abs() <= 1) continue;

        usedColumns[col] = true;
        usedRegions[region] = true;
        search(row + 1, col);
        usedColumns[col] = false;
        usedRegions[region] = false;
      }
    }

    search(0, -99);
    return count;
  }

  List<int>? _makeSolution(int size, Random rng) {
    final columns = List<int>.filled(size, -1);
    final used = List<bool>.filled(size, false);

    bool place(int row) {
      if (row == size) return true;
      final candidates = List<int>.generate(size, (i) => i)..shuffle(rng);
      for (final col in candidates) {
        if (used[col]) continue;
        if (row > 0 && (columns[row - 1] - col).abs() <= 1) continue;
        columns[row] = col;
        used[col] = true;
        if (place(row + 1)) return true;
        used[col] = false;
        columns[row] = -1;
      }
      return false;
    }

    return place(0) ? List<int>.from(columns) : null;
  }

  List<List<int>> _growRegions(int size, List<int> solution, Random rng) {
    final regions = List.generate(size, (_) => List.filled(size, -1));
    for (var row = 0; row < size; row++) {
      regions[row][solution[row]] = row;
    }

    var unassigned = size * size - size;
    const directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    while (unassigned > 0) {
      final frontier = <({int row, int col, List<int> regionChoices})>[];
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          if (regions[row][col] != -1) continue;
          final neighbors = <int>{};
          for (final (dr, dc) in directions) {
            final nr = row + dr;
            final nc = col + dc;
            if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
            if (regions[nr][nc] != -1) neighbors.add(regions[nr][nc]);
          }
          if (neighbors.isNotEmpty) {
            frontier.add((row: row, col: col, regionChoices: neighbors.toList()));
          }
        }
      }

      final chosen = frontier[rng.nextInt(frontier.length)];
      final region = chosen.regionChoices[rng.nextInt(chosen.regionChoices.length)];
      regions[chosen.row][chosen.col] = region;
      unassigned--;
    }

    return regions;
  }

  Set<CellPos> _placeLasers(
    int size,
    List<int> solution,
    int count,
    Random rng,
  ) {
    final candidates = <CellPos>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (solution[row] != col) candidates.add((row: row, col: col));
      }
    }
    candidates.shuffle(rng);
    return candidates.take(count).toSet();
  }
}

class PuzzleRules {
  static bool isSolved(Puzzle puzzle, List<List<CellMark>> marks) {
    if (marks.length != puzzle.size || marks.any((row) => row.length != puzzle.size)) {
      return false;
    }

    final size = puzzle.size;
    final rowCount = List<int>.filled(size, 0);
    final colCount = List<int>.filled(size, 0);
    final regionCount = List<int>.filled(size, 0);
    final thieves = <CellPos>[];

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (marks[row][col] != CellMark.thief) continue;
        if (puzzle.isLaser(row, col)) return false;
        rowCount[row]++;
        colCount[col]++;
        regionCount[puzzle.regions[row][col]]++;
        thieves.add((row: row, col: col));
      }
    }

    if (rowCount.any((n) => n != 1) ||
        colCount.any((n) => n != 1) ||
        regionCount.any((n) => n != 1)) {
      return false;
    }

    for (var i = 0; i < thieves.length; i++) {
      for (var j = i + 1; j < thieves.length; j++) {
        final dr = (thieves[i].row - thieves[j].row).abs();
        final dc = (thieves[i].col - thieves[j].col).abs();
        if (dr <= 1 && dc <= 1) return false;
      }
    }
    return true;
  }

  static Set<CellPos> conflicts(Puzzle puzzle, List<List<CellMark>> marks) {
    final result = <CellPos>{};
    final thieves = <CellPos>[];

    for (var row = 0; row < puzzle.size; row++) {
      for (var col = 0; col < puzzle.size; col++) {
        if (marks[row][col] == CellMark.thief) {
          final pos = (row: row, col: col);
          thieves.add(pos);
          if (puzzle.isLaser(row, col)) result.add(pos);
        }
      }
    }

    for (var i = 0; i < thieves.length; i++) {
      for (var j = i + 1; j < thieves.length; j++) {
        final a = thieves[i];
        final b = thieves[j];
        final sameRow = a.row == b.row;
        final sameCol = a.col == b.col;
        final sameRegion =
            puzzle.regions[a.row][a.col] == puzzle.regions[b.row][b.col];
        final touching =
            (a.row - b.row).abs() <= 1 && (a.col - b.col).abs() <= 1;
        if (sameRow || sameCol || sameRegion || touching) {
          result.add(a);
          result.add(b);
        }
      }
    }
    return result;
  }
}
