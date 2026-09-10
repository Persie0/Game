import 'dart:math';

enum CellMark { empty, blocked, thief }

enum HeistDifficulty {
  rookie(size: 5, laserCount: 2, label: 'Rookie', baseXp: 100),
  professional(size: 6, laserCount: 4, label: 'Professional', baseXp: 170),
  mastermind(size: 7, laserCount: 7, label: 'Mastermind', baseXp: 260);

  const HeistDifficulty({
    required this.size,
    required this.laserCount,
    required this.label,
    required this.baseXp,
  });

  final int size;
  final int laserCount;
  final String label;
  final int baseXp;
}

typedef CellPos = ({int row, int col});

class Puzzle {
  const Puzzle({
    required this.size,
    required this.regions,
    required this.solution,
    required this.lasers,
    required this.seed,
    this.version = PuzzleGenerator.generatorVersion,
  });

  final int size;
  final List<List<int>> regions;
  final List<int> solution;
  final Set<CellPos> lasers;
  final int seed;
  final int version;

  bool isLaser(int row, int col) => lasers.contains((row: row, col: col));
}

class PuzzleAnalysis {
  const PuzzleAnalysis({
    required this.score,
    required this.visitedNodes,
    required this.deadEnds,
    required this.label,
  });

  final int score;
  final int visitedNodes;
  final int deadEnds;
  final String label;
}

class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  // Increment whenever generation changes so saved/daily puzzles never silently
  // resolve to a different board after an app update.
  static const int generatorVersion = 3;
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

    for (var attempt = 0; attempt < 5000; attempt++) {
      final solution = _makeSolution(size, rng);
      if (solution == null) {
        continue;
      }

      final regions = _growRegions(size, solution, rng);
      final lasers = <CellPos>{};
      var essentialLasers = 0;

      // Instead of accepting a board that was already unique and sprinkling
      // decorative lasers onto it, repeatedly block a cell from an alternative
      // solution. At least one laser therefore contributes to the logic when
      // this difficulty uses lasers.
      while (lasers.length < laserCount) {
        final current = Puzzle(
          size: size,
          regions: regions,
          solution: solution,
          lasers: Set<CellPos>.unmodifiable(lasers),
          seed: effectiveSeed,
        );
        final alternative = PuzzleSolver.findAlternative(current, solution);
        if (alternative == null) {
          break;
        }

        final blockers = <CellPos>[];
        for (var row = 0; row < size; row++) {
          final col = alternative[row];
          final pos = (row: row, col: col);
          if (solution[row] != col && !lasers.contains(pos)) {
            blockers.add(pos);
          }
        }
        if (blockers.isEmpty) {
          break;
        }
        lasers.add(blockers[rng.nextInt(blockers.length)]);
        essentialLasers++;
      }

      final constrained = Puzzle(
        size: size,
        regions: regions,
        solution: solution,
        lasers: Set<CellPos>.unmodifiable(lasers),
        seed: effectiveSeed,
      );
      if (PuzzleSolver.countSolutions(constrained, limit: 2) != 1) {
        continue;
      }
      if (laserCount > 0 && essentialLasers == 0) {
        continue;
      }

      if (lasers.length < laserCount) {
        final filler = _laserCandidates(size, solution)
          ..removeWhere(lasers.contains)
          ..shuffle(rng);
        lasers.addAll(filler.take(laserCount - lasers.length));
      }

      final puzzle = Puzzle(
        size: size,
        regions: regions,
        solution: solution,
        lasers: Set<CellPos>.unmodifiable(lasers),
        seed: effectiveSeed,
      );
      if (puzzle.lasers.length == laserCount &&
          PuzzleSolver.countSolutions(puzzle, limit: 2) == 1) {
        return puzzle;
      }
    }

    throw StateError(
      'Could not generate a unique $size×$size puzzle for seed $effectiveSeed.',
    );
  }

  int dailySeed(DateTime localDate, HeistDifficulty difficulty) {
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    return generatorVersion * 1000000000 +
        date.year * 100000 +
        date.month * 1000 +
        date.day * 10 +
        difficulty.index;
  }

  int countSolutions(Puzzle puzzle, {int limit = 2}) =>
      PuzzleSolver.countSolutions(puzzle, limit: limit);

  List<int>? _makeSolution(int size, Random rng) {
    final columns = List<int>.filled(size, -1);
    final used = List<bool>.filled(size, false);

    bool place(int row) {
      if (row == size) {
        return true;
      }
      final candidates = List<int>.generate(size, (i) => i)..shuffle(rng);
      for (final col in candidates) {
        if (used[col]) {
          continue;
        }
        if (row > 0 && (columns[row - 1] - col).abs() <= 1) {
          continue;
        }
        columns[row] = col;
        used[col] = true;
        if (place(row + 1)) {
          return true;
        }
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
          if (regions[row][col] != -1) {
            continue;
          }
          final neighbors = <int>{};
          for (final (dr, dc) in directions) {
            final nr = row + dr;
            final nc = col + dc;
            if (nr < 0 || nr >= size || nc < 0 || nc >= size) {
              continue;
            }
            if (regions[nr][nc] != -1) {
              neighbors.add(regions[nr][nc]);
            }
          }
          if (neighbors.isNotEmpty) {
            frontier.add((
              row: row,
              col: col,
              regionChoices: neighbors.toList(),
            ));
          }
        }
      }

      if (frontier.isEmpty) {
        throw StateError('Region growth lost its frontier.');
      }
      final chosen = frontier[rng.nextInt(frontier.length)];
      final region =
          chosen.regionChoices[rng.nextInt(chosen.regionChoices.length)];
      regions[chosen.row][chosen.col] = region;
      unassigned--;
    }

    return regions;
  }

  List<CellPos> _laserCandidates(int size, List<int> solution) {
    final candidates = <CellPos>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (solution[row] != col) {
          candidates.add((row: row, col: col));
        }
      }
    }
    return candidates;
  }
}

class PuzzleSolver {
  static int countSolutions(
    Puzzle puzzle, {
    List<List<CellMark>>? marks,
    CellPos? forceThief,
    int limit = 2,
  }) {
    if (limit <= 0 || !_validPuzzleShape(puzzle)) {
      return 0;
    }
    if (!_validMarks(puzzle, marks)) {
      return 0;
    }
    if (forceThief != null && !_inBounds(puzzle, forceThief)) {
      return 0;
    }

    final size = puzzle.size;
    final fixed = List<int>.filled(size, -1);
    if (marks != null) {
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          if (marks[row][col] != CellMark.thief) {
            continue;
          }
          if (fixed[row] != -1) {
            return 0;
          }
          fixed[row] = col;
        }
      }
    }
    if (forceThief != null) {
      if (fixed[forceThief.row] != -1 &&
          fixed[forceThief.row] != forceThief.col) {
        return 0;
      }
      fixed[forceThief.row] = forceThief.col;
    }

    final usedColumns = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    var count = 0;

    void search(int row, int previousColumn) {
      if (count >= limit) {
        return;
      }
      if (row == size) {
        count++;
        return;
      }

      final candidates = fixed[row] == -1
          ? List<int>.generate(size, (index) => index)
          : <int>[fixed[row]];
      for (final col in candidates) {
        if (puzzle.isLaser(row, col) || usedColumns[col]) {
          continue;
        }
        if (marks != null && marks[row][col] == CellMark.blocked) {
          continue;
        }
        final region = puzzle.regions[row][col];
        if (region < 0 || region >= size || usedRegions[region]) {
          continue;
        }
        if (row > 0 && (col - previousColumn).abs() <= 1) {
          continue;
        }

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

  static List<int>? findAlternative(Puzzle puzzle, List<int> intended) {
    if (!_validPuzzleShape(puzzle) || intended.length != puzzle.size) {
      return null;
    }
    final size = puzzle.size;
    final usedColumns = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    final columns = List<int>.filled(size, -1);
    List<int>? alternative;

    void search(int row, int previousColumn) {
      if (alternative != null) {
        return;
      }
      if (row == size) {
        var differs = false;
        for (var index = 0; index < size; index++) {
          if (columns[index] != intended[index]) {
            differs = true;
            break;
          }
        }
        if (differs) {
          alternative = List<int>.from(columns);
        }
        return;
      }

      for (var col = 0; col < size; col++) {
        if (puzzle.isLaser(row, col) || usedColumns[col]) {
          continue;
        }
        final region = puzzle.regions[row][col];
        if (region < 0 || region >= size || usedRegions[region]) {
          continue;
        }
        if (row > 0 && (col - previousColumn).abs() <= 1) {
          continue;
        }
        columns[row] = col;
        usedColumns[col] = true;
        usedRegions[region] = true;
        search(row + 1, col);
        usedColumns[col] = false;
        usedRegions[region] = false;
        columns[row] = -1;
        if (alternative != null) {
          return;
        }
      }
    }

    search(0, -99);
    return alternative;
  }

  static PuzzleAnalysis analyze(Puzzle puzzle) {
    if (!_validPuzzleShape(puzzle)) {
      return const PuzzleAnalysis(
        score: 1,
        visitedNodes: 0,
        deadEnds: 0,
        label: 'Invalid',
      );
    }

    final size = puzzle.size;
    final usedColumns = List<bool>.filled(size, false);
    final usedRegions = List<bool>.filled(size, false);
    var visitedNodes = 0;
    var deadEnds = 0;
    var found = 0;

    void search(int row, int previousColumn) {
      if (found > 1) {
        return;
      }
      visitedNodes++;
      if (row == size) {
        found++;
        return;
      }
      var options = 0;
      for (var col = 0; col < size; col++) {
        if (puzzle.isLaser(row, col) || usedColumns[col]) {
          continue;
        }
        final region = puzzle.regions[row][col];
        if (region < 0 || region >= size || usedRegions[region]) {
          continue;
        }
        if (row > 0 && (col - previousColumn).abs() <= 1) {
          continue;
        }
        options++;
        usedColumns[col] = true;
        usedRegions[region] = true;
        search(row + 1, col);
        usedColumns[col] = false;
        usedRegions[region] = false;
      }
      if (options == 0) {
        deadEnds++;
      }
    }

    search(0, -99);
    final complexity = log(visitedNodes + deadEnds + 1) / ln2;
    final raw = 18 + size * 6 + complexity * 7 - puzzle.lasers.length * 0.8;
    final score = raw.round().clamp(1, 100);
    final label = switch (score) {
      <= 40 => 'Light',
      <= 58 => 'Clever',
      <= 74 => 'Tough',
      <= 88 => 'Expert',
      _ => 'Brutal',
    };
    return PuzzleAnalysis(
      score: score,
      visitedNodes: visitedNodes,
      deadEnds: deadEnds,
      label: label,
    );
  }

  static List<CellPos> viableCandidatesForRow(
    Puzzle puzzle,
    List<List<CellMark>> marks,
    int row,
  ) {
    if (!_validMarks(puzzle, marks) || row < 0 || row >= puzzle.size) {
      return const [];
    }
    if (marks[row].contains(CellMark.thief)) {
      return const [];
    }
    final viable = <CellPos>[];
    for (var col = 0; col < puzzle.size; col++) {
      if (marks[row][col] == CellMark.blocked || puzzle.isLaser(row, col)) {
        continue;
      }
      final pos = (row: row, col: col);
      if (countSolutions(puzzle, marks: marks, forceThief: pos, limit: 1) > 0) {
        viable.add(pos);
      }
    }
    return viable;
  }

  static bool _validMarks(Puzzle puzzle, List<List<CellMark>>? marks) =>
      marks == null ||
      (marks.length == puzzle.size &&
          marks.every((row) => row.length == puzzle.size));

  static bool _validPuzzleShape(Puzzle puzzle) =>
      puzzle.size >= 1 &&
      puzzle.solution.length == puzzle.size &&
      puzzle.regions.length == puzzle.size &&
      puzzle.regions.every((row) => row.length == puzzle.size);

  static bool _inBounds(Puzzle puzzle, CellPos pos) =>
      pos.row >= 0 &&
      pos.row < puzzle.size &&
      pos.col >= 0 &&
      pos.col < puzzle.size;
}

class PuzzleRules {
  static bool isSolved(Puzzle puzzle, List<List<CellMark>> marks) {
    if (marks.length != puzzle.size ||
        marks.any((row) => row.length != puzzle.size) ||
        puzzle.regions.length != puzzle.size ||
        puzzle.regions.any((row) => row.length != puzzle.size)) {
      return false;
    }

    final size = puzzle.size;
    final rowCount = List<int>.filled(size, 0);
    final colCount = List<int>.filled(size, 0);
    final regionCount = List<int>.filled(size, 0);
    final thieves = <CellPos>[];

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (marks[row][col] != CellMark.thief) {
          continue;
        }
        if (puzzle.isLaser(row, col)) {
          return false;
        }
        final region = puzzle.regions[row][col];
        if (region < 0 || region >= size) {
          return false;
        }
        rowCount[row]++;
        colCount[col]++;
        regionCount[region]++;
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
        if (_touching(thieves[i], thieves[j])) {
          return false;
        }
      }
    }
    return true;
  }

  static Set<CellPos> conflicts(Puzzle puzzle, List<List<CellMark>> marks) {
    final result = <CellPos>{};
    if (marks.length != puzzle.size ||
        marks.any((row) => row.length != puzzle.size) ||
        puzzle.regions.length != puzzle.size ||
        puzzle.regions.any((row) => row.length != puzzle.size)) {
      return result;
    }

    final thieves = <CellPos>[];
    for (var row = 0; row < puzzle.size; row++) {
      for (var col = 0; col < puzzle.size; col++) {
        if (marks[row][col] == CellMark.thief) {
          final pos = (row: row, col: col);
          thieves.add(pos);
          if (puzzle.isLaser(row, col)) {
            result.add(pos);
          }
        }
      }
    }

    for (var i = 0; i < thieves.length; i++) {
      for (var j = i + 1; j < thieves.length; j++) {
        final a = thieves[i];
        final b = thieves[j];
        final sameRow = a.row == b.row;
        final sameCol = a.col == b.col;
        final regionA = puzzle.regions[a.row][a.col];
        final regionB = puzzle.regions[b.row][b.col];
        final sameRegion = regionA >= 0 && regionA == regionB;
        if (sameRow || sameCol || sameRegion || _touching(a, b)) {
          result.add(a);
          result.add(b);
        }
      }
    }
    return result;
  }

  static bool attacks(Puzzle puzzle, CellPos thief, CellPos cell) {
    if (thief == cell) {
      return false;
    }
    final sameRegion = puzzle.regions.length == puzzle.size &&
        thief.row >= 0 &&
        thief.row < puzzle.size &&
        cell.row >= 0 &&
        cell.row < puzzle.size &&
        puzzle.regions[thief.row].length == puzzle.size &&
        puzzle.regions[cell.row].length == puzzle.size &&
        thief.col >= 0 &&
        thief.col < puzzle.size &&
        cell.col >= 0 &&
        cell.col < puzzle.size &&
        puzzle.regions[thief.row][thief.col] ==
            puzzle.regions[cell.row][cell.col];
    return thief.row == cell.row ||
        thief.col == cell.col ||
        sameRegion ||
        _touching(thief, cell);
  }

  static bool _touching(CellPos a, CellPos b) =>
      (a.row - b.row).abs() <= 1 && (a.col - b.col).abs() <= 1;
}
