import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/models/focus_session.dart';
import 'redis_cache_service.dart';
import 'session_repository.dart';

class CachedSessionRepository implements SessionRepository {
  CachedSessionRepository({
    required SessionRepository delegate,
    required RedisCacheService cache,
  })  : _delegate = delegate,
        _cache = cache;

  final SessionRepository _delegate;
  final RedisCacheService _cache;

  static const _cachePrefix = 'satori:sessions';
  static const _ttlSeconds = 600;

  String _key(String suffix) => '$_cachePrefix:$suffix';

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Future<void> save(FocusSession session) async {
    await _delegate.save(session);
    unawaited(_invalidateAll());
  }

  @override
  Future<void> delete(String sessionId) async {
    await _delegate.delete(sessionId);
    unawaited(_invalidateAll());
  }

  Future<void> _invalidateAll() async {
    await _cache.delPattern('$_cachePrefix:*');
  }

  @override
  Future<FocusSession?> findById(String sessionId) async {
    final key = _key('id:$sessionId');
    final cached = await _cache.get(key);
    if (cached != null) {
      try {
        return FocusSession.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('缓存 findById 反序列化失败: $e');
      }
    }

    final session = await _delegate.findById(sessionId);
    if (session != null) {
      await _cache.set(
        key,
        jsonEncode(session.toJson()),
        ttlSeconds: _ttlSeconds,
      );
    }

    return session;
  }

  @override
  Future<List<FocusSession>> findAllCounted() async {
    return _cachedQuery(
      _key('all_counted'),
      () => _delegate.findAllCounted(),
    );
  }

  @override
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to) async {
    return _cachedQuery(
      _key('range:${_dateKey(from)}:${_dateKey(to)}'),
      () => _delegate.findByDateRange(from, to),
    );
  }

  @override
  Future<List<FocusSession>> findUncounted() async {
    return _cachedQuery(
      _key('uncounted'),
      () => _delegate.findUncounted(),
    );
  }

  @override
  Future<int> count() async {
    final key = _key('count');
    final cached = await _cache.get(key);
    if (cached != null) {
      final value = int.tryParse(cached);
      if (value != null) return value;
    }

    final result = await _delegate.count();
    await _cache.set(key, '$result', ttlSeconds: _ttlSeconds);
    return result;
  }

  Future<List<FocusSession>> _cachedQuery(
    String key,
    Future<List<FocusSession>> Function() query,
  ) async {
    final cached = await _cache.get(key);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        debugPrint('Redis 缓存命中: $key (${list.length} 条)');
        return list
            .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('缓存查询反序列化失败 ($key): $e');
      }
    }

    debugPrint('Redis 缓存未命中: $key，从底层加载...');
    final result = await query();
    final wrote = await _cache.set(
      key,
      jsonEncode(result.map((s) => s.toJson()).toList()),
      ttlSeconds: _ttlSeconds,
    );
    debugPrint('Redis 缓存写入: $key (${result.length} 条) → ${wrote ? "成功" : "失败(Redis 不可用)"}');
    return result;
  }
}
