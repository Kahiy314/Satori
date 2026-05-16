# Mini Program

The WeChat Mini Program is a parallel Satori implementation built with TypeScript, WXML and WXSS.

Original collaboration repository: <https://gitee.com/avan0/clock>

The source in this GitHub repository is kept as a cleaned vendor copy. The upstream Gitee history is not imported directly because earlier commits contained client-side secret material. If we later need full history inside this repository, create a sanitized mirror first and import that mirror with `git subtree`.

## Project Shape

```text
satori_miniprogram/
├── miniprogram/
│   ├── pages/
│   │   ├── task/
│   │   ├── tomato/
│   │   ├── calendar/
│   │   ├── statistics/
│   │   └── setting/
│   ├── components/
│   ├── utils/
│   └── assets/
├── typings/
├── project.config.json
├── package.json
└── tsconfig.json
```

## Features

- Task list with task creation, filtering, searching and sorting.
- Pomodoro timer with work/rest cycles, incense visual, white noise and rest bell.
- Calendar check-in with quote modal.
- Statistics panel with local summary and trend chart.
- Settings for theme, default white noise, rest sound and rest duration.

## Local Storage

The mini program stores data with `wx.setStorageSync` through `utils/storage.ts`.

Main keys:

- `incense_tasks`
- `incense_lists`
- `incense_focus_records`
- `incense_checkins`
- `incense_settings`

## AI Summary

`utils/ai.ts` intentionally has no hardcoded API key. It returns a local fallback summary until a server proxy is configured.

Recommended production path:

```text
Mini Program -> Cloud Function / API Server -> AI Provider
```

The provider key should live only on the server side.

## Known Gaps

- Statistics currently still contain some mock values and should be wired to `FocusRecord` aggregation before release.
- Some algorithm examples are intentionally educational and more complex than the product requires.
- Mini program assets need the same provenance audit as Flutter assets.
- `project.config.json` uses `touristappid` for public sharing; replace it locally for real development.
