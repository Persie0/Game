# Architecture

## Product boundary

Museum Heist is a turn-based grid puzzle, so Flutter is the rendering/application layer while the actual game engine stays pure Dart. No real-time game engine is required.

## Modules

- `lib/game/puzzle.dart` — model, procedural generator, unique-solution solver, rules and difficulty analysis.
- `lib/game/hints.dart` — explainable forced-move and contradiction hints.
- `lib/game/session.dart` — marks, auto-cross transactions, undo history, hints/mistakes and serialization.
- `lib/game/progress.dart` — settings, XP/ranks, streaks, records and persistent active-game metadata.
- `lib/data/app_repository.dart` — persistence abstraction and `SharedPreferencesAsync` implementation.
- `lib/services/*` — sound/haptics, purchases and ads behind cross-platform contracts.
- `lib/app_controller.dart` — orchestration, active-game restore, completion rewards and monetization gates.
- `lib/ui/*` — onboarding, home, gameplay, statistics, settings and Pro UI.

## Puzzle invariants

A solution has exactly one thief per row, column and region. Thieves cannot touch orthogonally or diagonally. Laser cells are forbidden. Generation starts from a valid non-touching permutation, grows regions from each solution cell, then rejects any board whose solver count is not exactly one.

## Hint correctness

Hints do not guess. The hint engine first reports conflicts, then finds rows with exactly one candidate that can still complete the puzzle. If no immediate forced placement exists, it tests candidate assumptions; an assumption that leaves zero full solutions is a valid contradiction and can be marked X.

## Persistence and versioning

Only authored state is stored: generator version, seed, mode, difficulty, session marks/history, elapsed time, settings and progression. A saved game with an incompatible generator version is discarded instead of being regenerated into a different board. Daily seeds also include the generator version.

## Retention and progression

Completion awards XP based on base difficulty, solver-derived puzzle complexity, move efficiency, hints and perfect-clear status. Daily rewards are idempotent per date and difficulty, so replaying cannot farm XP. Consecutive daily dates drive the streak. Cosmetic skins unlock only from local reputation level and do not affect puzzle rules.

## Monetization boundary

`in_app_purchase` is isolated behind `PurchaseService`; `google_mobile_ads` is isolated behind `AdService`. Web and unsupported desktop targets compile against safe fallbacks. Ad requests are gated behind Google UMP consent information. The core rules and persistence do not depend on either SDK.

The client currently grants Pro from a store purchased/restored event and persists the result locally. For a high-value production economy, add server-side receipt/token verification before treating entitlement as authoritative.
