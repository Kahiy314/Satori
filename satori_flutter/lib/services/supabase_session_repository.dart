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

    final remoteSession = await _upsertRemote(enriched);
    if (remoteSession != null) {
      await _localRepository.save(remoteSession);
    }
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
    if (_client == null || _currentUserId == null) {
      await _localRepository.delete(sessionId);
      return;
    }

    try {
      await _client.rpc(
        'delete_client_focus_session',
        params: {'p_session_id': sessionId},
      );
      await _localRepository.delete(sessionId);
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

    for (final session in localSessions) {
      final syncedSession = session.copyWith(
        userId: userId,
        updatedAt: session.updatedAt ?? DateTime.now(),
      );

      final remoteSession = await _upsertRemote(syncedSession);
      if (remoteSession != null) {
        await _localRepository.save(remoteSession);
      }
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

  Future<FocusSession?> _upsertRemote(FocusSession session) async {
    if (_client == null || _currentUserId == null) return null;

    try {
      final payload = await _client.rpc(
        'upsert_client_focus_session',
        params: _toRpcParams(session),
      );
      if (payload == null) return null;

      return _fromRow(Map<String, dynamic>.from(payload as Map));
    } catch (error, stackTrace) {
      debugPrint('写入远端 focus_session 失败: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  bool _shouldReplaceLocal(
      FocusSession? localSession, FocusSession remoteSession) {
    if (localSession == null) return true;

    final localUpdatedAt = localSession.updatedAt ?? localSession.createdAt;
    final remoteUpdatedAt = remoteSession.updatedAt ?? remoteSession.createdAt;
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) return true;
    if (remoteUpdatedAt.isBefore(localUpdatedAt)) return false;

    return remoteSession.trustLevel != localSession.trustLevel ||
        remoteSession.serverScore != localSession.serverScore ||
        remoteSession.userId != localSession.userId ||
        remoteSession.isCountedInHistory != localSession.isCountedInHistory;
  }

  Map<String, dynamic> _toRpcParams(FocusSession session) {
    return {
      'p_session_id': session.sessionId,
      'p_start_at': session.startAt.toIso8601String(),
      'p_end_at': session.endAt?.toIso8601String(),
      'p_actual_duration': session.actualDuration,
      'p_mode': session.mode.name,
      'p_status': session.status.name,
      'p_planned_duration': session.plannedDuration,
      'p_task_tag': session.taskTag,
      'p_summary_note': session.summaryNote,
      'p_reflection_mood': session.reflectionMood?.name,
      'p_is_counted_in_history': session.isCountedInHistory,
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
      trustLevel: row['trust_level'] as String?,
      serverScore: (row['server_score'] as num?)?.toInt() ?? 0,
      taskTag: row['task_tag'] as String?,
      summaryNote: row['summary_note'] as String?,
      reflectionMood: row['reflection_mood'] != null
          ? ReflectionMood.values.byName(row['reflection_mood'] as String)
          : null,
      isCountedInHistory: row['is_counted_in_history'] as bool? ?? true,
    );
  }
}
