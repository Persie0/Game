# Release checklist

## Store products

Create the non-consumable product ID `museum_heist_pro_lifetime` in Google Play Console and App Store Connect. Test purchases with Play license testers and StoreKit sandbox accounts, including restore after reinstall/sign-in.

The current client grants Pro after a purchased/restored event from the platform store and persists it locally. Before scaling a valuable account-based economy, validate Play purchase tokens / App Store transactions on a trusted server and restore entitlement from that source.

## Google Mobile Ads

Runtime ad unit IDs are supplied through Dart defines:

- `ADMOB_BANNER_ANDROID`
- `ADMOB_REWARDED_ANDROID`
- `ADMOB_INTERSTITIAL_ANDROID`
- `ADMOB_BANNER_IOS`
- `ADMOB_REWARDED_IOS`
- `ADMOB_INTERSTITIAL_IOS`

The native AdMob app ID is separate. After `flutter create`, add the Android app ID as `com.google.android.gms.ads.APPLICATION_ID` metadata in `android/app/src/main/AndroidManifest.xml`, and the iOS app ID as `GADApplicationIdentifier` in `ios/Runner/Info.plist`.

Do not ship Google's test ad-unit IDs.

## Privacy and consent

The app runs Google's UMP consent-information update and consent form before initializing ads, calls `canRequestAds` before making requests, and exposes privacy choices in Settings whenever ads are configured. Configure the privacy message in AdMob and keep the privacy policy and Play/App Store data disclosures aligned with the exact SDK configuration you ship.

If no ad unit IDs are supplied, advertising remains disabled.

## Native platform runners

This repository keeps generated Flutter platform projects out of source control. Generate them with:

```bash
flutter create . --platforms=android,ios,web,windows,macos,linux
```

Then configure the final application IDs/bundle IDs, signing, app icons, launch assets, AdMob app IDs, minimum deployment targets, privacy manifests/descriptions where required, and store capabilities before submission.

## Release builds

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
flutter build appbundle --release
flutter build ipa --release
```

Desktop release commands can be run on their target operating systems. Android/iOS/macOS signing is account-specific and should use protected CI secrets or local secure keychains; never commit signing keys or store credentials.

## Pre-submission QA

Verify onboarding, all three board sizes, daily replay reward deduplication, resume after process restart, undo after auto-cross, hint gating, rewarded hint completion, Pro purchase/restore, ad removal after Pro, consent/privacy options, dark mode, region labels, reduced motion, large text, screen-reader semantics, airplane/offline play, and repeated puzzle generation.
