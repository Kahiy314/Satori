# Architecture

## Repository Layout

```text
Satori/
├── satori_flutter/       # Flutter main app
├── satori_miniprogram/   # WeChat Mini Program implementation
├── docs/                 # Public documentation
└── README.md             # GitHub repository landing page
```

## Flutter App

The Flutter app uses a feature-first layout:

- `lib/app`: app shell, tab navigation, global Riverpod providers.
- `lib/core`: design tokens, shared models, config, generic UI components.
- `lib/features`: user-facing modules.
- `lib/services`: persistence, sync, media, haptics, entitlements and platform abstractions.

The main data path is local-first:

```text
IncenseViewModel
  -> SessionRepository
  -> SupabaseSessionRepository
  -> LocalSessionRepository
  -> shared_preferences
```

When Supabase is configured and the user is signed in, `SupabaseSessionRepository` pushes completed local sessions through RPC and pulls remote sessions back into the local cache. Without Supabase, the same repository interface still works locally.

## Flutter Features

- `incense`: focus timer, session lifecycle, task tag, summary and short-focus filtering.
- `rain`: white noise playback.
- `qin`: local instrumental track playback.
- `stats`: overview, history, timeline, trend and heatmap.
- `settings`: auth entry, preferences and developer mode.
- `tea`: membership and entitlement presentation.

## Mini Program

The mini program uses WeChat-native pages and local storage:

- `pages/task`: task list and task creation.
- `pages/tomato`: pomodoro timer.
- `pages/calendar`: check-in calendar and quote modal.
- `pages/statistics`: local stats and AI-summary entry.
- `pages/setting`: theme, audio and rest-duration settings.
- `utils/storage.ts`: local persistence wrapper.
- `utils/algorithm.ts`: task list, calendar and statistics helpers.
- `utils/audio.ts`: white noise and rest bell playback.
- `utils/ai.ts`: AI summary adapter; defaults to local fallback until a server proxy is configured.

## Data Boundary

Flutter focus sessions and mini program pomodoro records are currently separate local data models. There is no shared sync contract between the Flutter app and the mini program yet.

