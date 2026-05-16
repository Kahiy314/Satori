# Contributing

Thanks for taking an interest in Satori.

## Before You Start

- Keep changes scoped to one feature, fix or documentation area.
- Prefer the existing feature-first structure.
- Do not commit local secrets, signing files, generated build output or unverified third-party assets.
- For Flutter changes, run `flutter analyze` and `flutter test`.

## Flutter

```powershell
cd satori_flutter
flutter pub get
flutter analyze
flutter test
```

## Mini Program

```powershell
cd satori_miniprogram
npm install
npm run typecheck
```

## Pull Requests

Please include:

- What changed.
- How you tested it.
- Any screenshots for UI changes.
- Any asset provenance if you add or replace media.

