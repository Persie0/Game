# Architecture

## Technology choice

Museum Heist is deliberately implemented in Flutter/Dart rather than a full game engine. The core interaction is a turn-based grid puzzle, so most complexity is UI, state, progression, monetization, persistence, accessibility, and store integration rather than physics or frame-by-frame simulation.

The puzzle engine is pure Dart and kept independent from widgets. This makes generation and validation deterministic and cheap to test. Flutter owns rendering and input. Flame is intentionally not a dependency; it can be introduced later for effects without moving the puzzle rules out of Dart.

## Modules

- `lib/game/puzzle.dart`: puzzle model, seeded generator, uniqueness solver, laser constraints, validation.
- `lib/game/session.dart`: mutable play session, cell marks, undo, hints, reset.
- `lib/main.dart`: responsive Material 3 app and board presentation.

## Puzzle invariants

A valid solution contains exactly one thief in every row, every column, and every security region. No two thieves may touch orthogonally or diagonally. Laser cells are forbidden.

Generation starts from a valid non-touching permutation, grows contiguous security regions outward from solution cells, then accepts only boards with exactly one solver-confirmed solution. Laser cells are selected only from cells outside the known solution.

## Cross-platform strategy

Flutter targets Android, iOS, web, Windows, macOS and Linux from the same Dart codebase. Platform runner projects can be generated with `flutter create . --platforms=android,ios,web,windows,macos,linux`; CI does this before analysis and tests to keep this repository focused on authored source rather than generated boilerplate.

## Production next steps

1. Persist daily completions, streaks, settings, undo state and statistics.
2. Add a difficulty scorer based on solver deductions rather than board size alone.
3. Add logical hint explanations instead of revealing raw solution cells.
4. Add authored laser patterns / camera-line constraints for later chapters.
5. Add onboarding, haptics, sound, celebration effects and reduced-motion support.
6. Add localization before content production.
7. Add ads/IAP behind service abstractions so the core game stays testable.
8. Add deterministic daily puzzle versioning so generator changes never alter historical dailies.
