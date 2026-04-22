import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/focus_session.dart';
import 'local_session_repository.dart';
import 'session_repository.dart';

class SupabaseSessionRepository implements SessionRepository {
  SupabaseSessionRepository({
    required LocalSessionRepository localRepository,
    SupabaseClient? client,
  })  : _localRepository = localRepository,
        _client = client;

  final LocalSessionRepository _localRepository;
  final SupabaseClient? _client;

  String? get _currentUserId => _client?.auth.currentUser?.id;

  Future<void> syncWithCloud() async {
    if (_client == null || _currentUserId == null) return;

    try {
      await _pushLocalSessions();
      await _pullRemoteSessions();
    } catch (error, stackTrace) {
      debugPrint('focus_sessions 同步失败: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> save(FocusSession session) async {
    final enriched = session.copyWith(
      userId: _currentUserId ?? session.userId,
      updatedAt: DateTime.now(),
    );
    await _localRepository.save(enriched);
    await _upsertRemote(enriched);
  }

  @override
  Future<FocusSession?> findById(String sessionId) {
    return _localRepository.findById(sessionId);
  }

  @override
  Future<List<FocusSession>> findAllCounted() {
    return _localRepository.findAllCounted();
  }

  @override
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to) {
    return _localRepository.findByDateRange(from, to);
  }

  @override
  Future<List<FocusSession>> findUncounted() {
    return _localRepository.findUncounted();
  }

  @override
  Future<void> delete(String sessionId) async {
    await _localRepository.delete(sessionId);
    if (_client == null || _currentUserId == null) return;

    try {
      await _client
          .from('focus_sessions')
          .delete()
          .eq('user_id', _currentUserId!)
          .eq('session_id', sessionId);
    } catch (error, stackTrace) {
      debugPrint('删除远端 focus_session 失败: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<int> count() {
    return _localRepository.count();
  }

  Future<void> _pushLocalSessions() async {
    final userId = _currentUserId;
    if (_client == null || userId == null) return;

    final localSessions = await _localRepository.allSessions();
    if (localSessions.isEmpty) return;

    final rows = localSessions.map((session) {
      final syncedSession = session.copyWith(
        userId: userId,
        updatedAt: session.updatedAt ?? DateTime.now(),
      );
      return _toRow(syncedSession);
    }).toList();

    await _client
        .from('focus_sessions')
        .upsert(rows, onConflict: 'user_id,session_id');

    for (final session in localSessions) {
      if (session.userId == userId && session.updatedAt != null) continue;
      await _localRepository.save(
        session.copyWith(
          userId: userId,
          updatedAt: session.updatedAt ?? DateTime.now(),
        ),
      );
    }
  }

  Future<void> _pullRemoteSessions() async {
    final userId = _currentUserId;
    if (_client == null || userId == null) return;

    final rows = (await _client
        .from('focus_sessions')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)) as List<dynamic>;

    for (final row in rows.cast<Map<String, dynamic>>()) {
      final remoteSession = _fromRow(row);
      final localSession =
          await _localRepository.findById(remoteSession.sessionId);
      if (_shouldReplaceLocal(localSession, remoteSession)) {
        await _localRepository.save(remoteSession);
      }
    }
  }

  Future<void> _upsertRemote(FocusSession session) async {
    if (_client == null || _currentUserId == null) return;

    try {
      await _client
          .from('focus_sessions')
          .upsert(_toRow(session), onConflict: 'user_id,session_id');
    } catch (error, stackTrace) {
      debugPrint('写入远端 focus_session 失败: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _shouldReplaceLocal(
      FocusSession? localSession, FocusSession remoteSession) {
    if (localSession == null) return true;
    final localUpdatedAt = localSession.updatedAt ?? localSession.createdAt;
    final remoteUpdatedAt = remoteSession.updatedAt ?? remoteSession.createdAt;
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  Map<String, dynamic> _toRow(FocusSession session) {
    return {
      'session_id': session.sessionId,
      'user_id': _currentUserId ?? session.userId,
      'start_at': session.startAt.toIso8601String(),
      'end_at': session.endAt?.toIso8601String(),
      'planned_duration': session.plannedDuration,
      'actual_duration': session.actualDuration,
      'mode': session.mode.name,
      'status': session.status.name,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': (session.updatedAt ?? DateTime.now()).toIso8601String(),
      'task_tag': session.taskTag,
      'summary_note': session.summaryNote,
      'reflection_mood': session.reflectionMood?.name,
      'is_counted_in_history': session.isCountedInHistory,
    };
  }

  FocusSession _fromRow(Map<String, dynamic> row) {
    return FocusSession(
      sessionId: row['session_id'] as String,
      userId: row['user_id'] as String?,
      startAt: DateTime.parse(row['start_at'] as String),
      endAt: row['end_at'] != null
          ? DateTime.parse(row['end_at'] as String)
          : null,
      plannedDuration: (row['planned_duration'] as num?)?.toDouble(),
      actualDuration: (row['actual_duration'] as num).toDouble(),
      mode: FocusMode.values.byName(row['mode'] as String),
      status: SessionStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      taskTag: row['task_tag'] as String?,
      summaryNote: row['summary_note'] as String?,
      reflectionMood: row['reflection_mood'] != null
          ? ReflectionMood.values.byName(row['reflection_mood'] as String)
          : null,
      isCountedInHistory: row['is_counted_in_history'] as bool? ?? true,
    );
  }
}
