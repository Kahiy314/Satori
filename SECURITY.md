# Security

## Reporting

Please do not open a public issue for vulnerabilities or leaked secrets. Contact the maintainer privately first, or open a minimal issue asking for a secure contact channel.

## Secrets

Never commit:

- Supabase service-role keys.
- AI provider keys.
- WeChat AppSecret.
- Android keystores or passwords.
- Apple signing credentials.

Client-side Flutter, Web and Mini Program code must only contain public client configuration. Any privileged API call should go through Supabase RLS/RPC, a cloud function or a server you control.

