# Supabase

Supabase is optional. The Flutter app works in local mode without it.

## Runtime Configuration

The Flutter app reads Supabase settings from `dart-define`:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_AUTH_REDIRECT_URL`, optional, defaults to `satori://auth/callback`

Local debug:

```powershell
cd satori_flutter
copy tool\supabase.local.example.json tool\supabase.local.json
tool\run-cloud.cmd
```

Release build:

```powershell
flutter build apk --release --dart-define-from-file=tool/supabase.production.json
```

Do not commit real local or production config files.

## Dashboard Setup

In Supabase:

1. Enable Authentication Email provider.
2. Add `satori://auth/callback` to `Authentication -> URL Configuration -> Redirect URLs`.
3. Execute the migration at `satori_flutter/supabase/migrations/202604230001_harden_focus_sessions_security.sql`.

## Schema

The migration creates:

- `public.user_profiles`
- `public.focus_sessions`
- indexes for user/start and user/update queries
- row-level security policies
- `upsert_client_focus_session`
- `delete_client_focus_session`

The client does not directly insert, update or delete `focus_sessions`; writes go through RPC.

## Sync Rules

- Signed-out users write only to local storage.
- After login, local sessions are pushed to Supabase as `client_reported` sessions.
- Remote sessions are pulled back into local storage.
- Conflict replacement uses `updated_at`, plus trust-level, score and user ownership changes.
- Stats and history only count records with `is_counted_in_history = true`.

## Security Notes

`SUPABASE_PUBLISHABLE_KEY` is not a service-role secret, but it must be paired with strict RLS and RPC permissions. Never ship a `service_role` key in Flutter, mini program, web, or any other client.

