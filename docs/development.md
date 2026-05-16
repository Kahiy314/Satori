# Development

## Flutter

Recommended local toolchain:

- Flutter 3.27 or newer. The current workspace was verified with Flutter 3.41.4 and Dart 3.11.1.
- Android Studio / Android SDK for Android emulator builds.
- Xcode for iOS and macOS builds.

Common commands:

```powershell
cd satori_flutter
flutter pub get
flutter analyze
flutter test
flutter run
```

Cloud-mode debug:

```powershell
copy tool\supabase.local.example.json tool\supabase.local.json
tool\run-cloud.cmd
```

`tool/supabase.local.json` is ignored by Git. Keep real keys local.

## WeChat Mini Program

Recommended local toolchain:

- Node.js 18 or newer.
- WeChat DevTools.

Common commands:

```powershell
cd satori_miniprogram
npm install
npm run typecheck
```

Then open `satori_miniprogram` in WeChat DevTools. Replace `touristappid` locally if you need real upload or device testing.

## CI

GitHub Actions validates the Flutter project with:

```powershell
flutter pub get
flutter analyze
flutter test
```

GitHub Actions validates the mini program TypeScript layer with:

```powershell
npm ci
npm run typecheck
```

This is a static type check only; full WeChat DevTools preview/upload still needs local manual verification.
