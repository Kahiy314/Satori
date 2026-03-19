import '../core/models/focus_session.dart';

/// 会话仓储接口 — Phase P1 定义，Phase P3 实现。
///
/// 提供增删查改和聚合查询接口，具体持久化策略（JSON / Isar / sqflite）
/// 由实现类决定。
abstract class SessionRepository {
  /// 保存一条会话（新增或更新）
  Future<void> save(FocusSession session);

  /// 按 sessionId 查询
  Future<FocusSession?> findById(String sessionId);

  /// 查询所有记入历史的会话（isCountedInHistory == true），
  /// 按 startAt 降序。
  Future<List<FocusSession>> findAllCounted();

  /// 查询指定日期范围内的会话（闭区间），只含计入历史部分。
  Future<List<FocusSession>> findByDateRange(DateTime from, DateTime to);

  /// 查询低于最短有效阈值但仍保留的轻量事件（用于提示计数）。
  Future<List<FocusSession>> findUncounted();

  /// 删除一条会话
  Future<void> delete(String sessionId);

  /// 全部会话数量（含计入与未计入）
  Future<int> count();
}
