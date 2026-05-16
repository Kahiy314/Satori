class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'satori://auth/callback',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static String get missingConfigurationHint =>
      '未配置 Supabase。请通过 --dart-define=SUPABASE_URL=... 和 '
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=... 启用云端登录与同步。';
}
