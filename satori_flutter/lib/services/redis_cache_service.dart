import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:redis/redis.dart';

class RedisCacheService {
  RedisCacheService({
    String host = 'localhost',
    int port = 6379,
    String? password,
  })  : _host = host,
        _port = port,
        _password = password;

  final String _host;
  final int _port;
  final String? _password;

  Command? _command;
  bool _initialized = false;

  bool get isConnected => _command != null;

  static bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_isTestEnvironment) {
      debugPrint('Redis 缓存: 测试环境，跳过连接');
      return;
    }

    try {
      final conn = RedisConnection();
      _command = await conn.connect(_host, _port);
      if (_password != null && _password.isNotEmpty) {
        await _command!.send_object(['AUTH', _password]);
      }
      debugPrint('Redis 缓存已连接: $_host:$_port');
    } catch (e) {
      debugPrint('Redis 缓存连接失败 ($_host:$_port): $e，将回退到无缓存模式');
      _command = null;
    }

    debugPrint(
        'Redis 缓存状态: ${isConnected ? "可用 ✅" : "不可用 ❌ (无缓存模式)"}');
  }

  Future<String?> get(String key) async {
    if (_command == null) return null;
    try {
      final result = await _command!.send_object(['GET', key]);
      return result is String ? result : null;
    } catch (e) {
      debugPrint('Redis GET 失败 ($key): $e');
      return null;
    }
  }

  Future<bool> ping() async {
    if (_command == null) return false;
    try {
      final result = await _command!.send_object(['PING']);
      return result == 'PONG';
    } catch (e) {
      return false;
    }
  }

  Future<bool> set(String key, String value, {int ttlSeconds = 600}) async {
    if (_command == null) return false;
    try {
      await _command!.send_object(['SETEX', key, '$ttlSeconds', value]);
      return true;
    } catch (e) {
      debugPrint('Redis SET 失败 ($key): $e');
      return false;
    }
  }

  Future<bool> del(String key) async {
    if (_command == null) return false;
    try {
      await _command!.send_object(['DEL', key]);
      return true;
    } catch (e) {
      debugPrint('Redis DEL 失败 ($key): $e');
      return false;
    }
  }

  Future<int> delPattern(String pattern) async {
    if (_command == null) return 0;
    try {
      final keys = await _command!.send_object(['KEYS', pattern]);
      if (keys is! List || keys.isEmpty) return 0;

      final keyList = keys.cast<String>().toList();
      await _command!.send_object(['DEL', ...keyList]);
      return keyList.length;
    } catch (e) {
      debugPrint('Redis DEL pattern 失败 ($pattern): $e');
      return 0;
    }
  }

  Future<T?> getOrCompute<T>(
    String key,
    Future<T?> Function() compute, {
    int ttlSeconds = 600,
    T Function(String)? fromJson,
  }) async {
    final cached = await get(key);
    if (cached != null) {
      try {
        if (fromJson != null) {
          return fromJson(cached);
        }
        return cached as T;
      } catch (e) {
        debugPrint('Redis 缓存反序列化失败 ($key): $e');
      }
    }

    final value = await compute();
    if (value != null) {
      String serialized;
      if (value is String) {
        serialized = value;
      } else if (value is List || value is Map) {
        serialized = jsonEncode(value);
      } else if (value is int || value is double || value is bool) {
        serialized = '$value';
      } else {
        serialized = '$value';
      }
      await set(key, serialized, ttlSeconds: ttlSeconds);
    }

    return value;
  }

  Future<void> dispose() async {
    _initialized = false;
    _command = null;
  }
}
