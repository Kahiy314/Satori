import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Supabase 初始化失败: $error');
      debugPrintStack(stackTrace: stackTrace);
      _initialized = false;
    }
  }
}
