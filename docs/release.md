# Release

## Flutter Supabase Configuration

Release builds should inject Supabase config with `dart-define-from-file`:

```powershell
flutter build apk --release --dart-define-from-file=tool/supabase.production.json
```

Suggested production config shape:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "your-publishable-key",
  "SUPABASE_AUTH_REDIRECT_URL": "satori://auth/callback"
}
```

Do not commit production config files.

## Android

The public project uses:

```text
applicationId = io.github.kahiy314.satori
```

Release signing is not configured in Git. Create local signing material and keep it ignored:

- `android/key.properties`
- `*.jks` or `*.keystore`

Then add local signing config before producing store artifacts.

## iOS and macOS

The bundle identifier is:

```text
io.github.kahiy314.satori
```

Set your Apple Team ID, signing certificate and provisioning profiles locally in Xcode. Do not commit personal signing changes unless they are intentionally generic project settings.

## Web

Web metadata lives in:

- `satori_flutter/web/index.html`
- `satori_flutter/web/manifest.json`

Build with:

```powershell
flutter build web --release --dart-define-from-file=tool/supabase.production.json
```

## WeChat Mini Program

`project.config.json` uses `touristappid` in Git. Replace it locally with your real AppID in WeChat DevTools for upload and review.

Do not place AI provider keys in mini program code. Use a cloud function or API server proxy.

