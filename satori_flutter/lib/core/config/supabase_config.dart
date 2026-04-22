class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static String get missingConfigurationHint =>
      '未配置 Supabase。请通过 --dart-define=SUPABASE_URL=... 和 '
      '--dart-define=SUPABASE_ANON_KEY=... 启用云端登录与同步。';
}
