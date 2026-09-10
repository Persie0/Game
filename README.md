# Museum Heist

Museum Heist is a production-oriented, cross-platform Queens-style logic game built in Flutter/Dart. Place one thief in each row, column, and colored security zone; thieves cannot touch and laser rooms are forbidden.

## Release feature set

- Deterministic Daily Heist and unlimited Free Play
- Rookie 5×5, Professional 6×6, Mastermind 7×7
- Procedural contiguous security zones with solver-confirmed unique solutions
- Generator versioning so persisted and daily games never silently change
- Solver-derived difficulty score and labels
- Logical hints based on forced placements and contradiction testing
- Auto-X marking with transaction-level undo, conflict feedback, reset and resume
- Full local persistence of board, undo history, settings and progression
- XP, levels, five reputation ranks, daily streaks, perfect clears and personal records
- Achievements plus unlockable Classic, Noir, Emerald and Neon museum skins
- First-launch onboarding, light/dark/system theme and reduced-motion support
- Color-accessibility region labels, semantics, haptics and sound feedback
- Consent-aware Android/iOS AdMob banners, rewarded hints and paced interstitials
- Lifetime Pro purchase/restore through Flutter's official in-app-purchase API
- Web/Windows/Linux-safe fallbacks for mobile-only monetization
- Analyzer, unit/widget tests and release web build in GitHub Actions

## Run

```bash
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get
flutter test
flutter run
```

## Store configuration

The repository contains no private credentials. Create the non-consumable product `museum_heist_pro_lifetime` in Google Play Console and App Store Connect.

Ad unit IDs are injected at build time, for example:

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ANDROID=... \
  --dart-define=ADMOB_REWARDED_ANDROID=... \
  --dart-define=ADMOB_INTERSTITIAL_ANDROID=...
```

iOS uses the corresponding `*_IOS` defines. Google Mobile Ads also requires the AdMob app ID in the generated Android/iOS runner configuration. See `docs/RELEASE.md`.

## Architecture

Puzzle generation, solving, hints and sessions remain pure Dart. Persistence, advertising and purchases sit behind small service interfaces so unsupported platforms do not invoke mobile SDKs. See `docs/ARCHITECTURE.md`.
