import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/focus_session.dart';
import 'session_repository.dart';

/// 基于 shared_preferences 的轻量 JSON 持久化实现。
/// 数据量尚小时足够；若后续记录规模明显增长，可升级为 Isar / sqflite。
class LocalSessionRepository implements SessionRepository {
  static const _storageKey = 'focus_sessions';

  List<FocusSession>? _cache;

  Future<List<FocusSession>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_cache!.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  @override
  Future<void> save(FocusSession session) async {
    final sessions = await _load();
    final idx = sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    await _persist();
  }

  @override
  Future<FocusSession?> findById(String sessionId) async {
    final sessions = await _load();
    try {
      return sessions.firstWhere((s) => s.sessionId == sessionId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<FocusSession>> findAllCounted() async {
    final sessions = await _load();
    return sessions
        .where((s) => s.isCountedInHistory)
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to) async {
    final sessions = await _load();
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return sessions
        .where((s) =>
            s.isCountedInHistory &&
            !s.startAt.isBefore(fromDay) &&
            !s.startAt.isAfter(toDay))
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Future<List<FocusSession>> findUncounted() async {
    final sessions = await _load();
    return sessions
        .where((s) => !s.isCountedInHistory)
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Future<void> delete(String sessionId) async {
    final sessions = await _load();
    sessions.removeWhere((s) => s.sessionId == sessionId);
    await _persist();
  }

  @override
  Future<int> count() async {
    final sessions = await _load();
    return sessions.length;
  }
}
