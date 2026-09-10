# Museum Heist

A modern, cross-platform Queens-style logic puzzle built with Flutter/Dart.

You are planning a museum infiltration. Place exactly one thief in every row, column, and colored security zone. Thieves may not touch, even diagonally, and laser rooms are permanently forbidden.

## Included MVP

- Daily deterministic puzzle and unlimited free-play mode
- Rookie 5×5, Professional 6×6, and Mastermind 7×7 boards
- Procedurally grown contiguous security zones
- Backtracking solver that rejects non-unique generated boards
- Laser-cell constraint unique to the Museum Heist theme
- Tap cycle and long-press X marking
- Live conflict highlighting
- Undo, reset, and hint controls
- Responsive Material 3 UI, light/dark themes, semantic labels
- Pure-Dart puzzle/session separation with unit tests
- GitHub Actions for formatting, analysis, tests, and a release web build

## Why Flutter

This is a turn-based, touch-first puzzle rather than a physics-heavy real-time game. Flutter gives one UI codebase across Android, iOS, web, Windows, macOS, and Linux and has first-party guidance specifically for casual turn-based games. The game logic stays pure Dart. Flame is intentionally optional and can be added later only if richer game-loop effects justify it.

## Run locally

Install a current stable Flutter SDK, then:

```bash
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get
flutter test
flutter run
```

For a web build:

```bash
flutter build web --release
```

## Product direction

The MVP is intentionally small. Commercial expansion should focus on retention rather than mechanical bloat: daily heists, streaks, museum chapters, logical hints, cosmetic themes, achievements/leaderboards, and optional rewarded ads / ad-removal IAP.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for design constraints and the production roadmap.
