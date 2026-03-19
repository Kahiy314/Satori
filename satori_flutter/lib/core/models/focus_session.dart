// 焚香专注会话模型 — Phase P1
//
// 最小专注会话记录，用于本地统计、历史回顾与小结。
// status 显式区分 completed / abandoned / interrupted，
// 避免后续统计把完成和中途退出混为一类。

class FocusSession {
  /// 会话唯一标识
  final String sessionId;

  /// 会话实际开始时间（首次 start，不含 idle）
  final DateTime startAt;

  /// 会话结束时间（completed / abandoned / interrupted 时写入）
  final DateTime? endAt;

  /// 用户设定的计划时长（秒）；正计时模式下为 null
  final double? plannedDuration;

  /// 实际专注时长（秒），含暂停前已累积部分
  final double actualDuration;

  /// 计时模式
  final FocusMode mode;

  /// 会话终态
  final SessionStatus status;

  /// 会话创建时间（进入 idle 或 start 前的时间戳）
  final DateTime createdAt;

  // ── 可选字段：标签、小结、复盘 ──

  /// 用户为本次专注添加的任务标签
  final String? taskTag;

  /// 专注结束后的小结备注
  final String? summaryNote;

  /// 专注结束后的完成感受（如 focused / distracted / productive 等）
  final ReflectionMood? reflectionMood;

  /// 是否计入历史与统计聚合。
  /// 短于最短有效阈值的会话置为 false，但仍保留记录以供提示计数。
  final bool isCountedInHistory;

  const FocusSession({
    required this.sessionId,
    required this.startAt,
    this.endAt,
    this.plannedDuration,
    required this.actualDuration,
    required this.mode,
    required this.status,
    required this.createdAt,
    this.taskTag,
    this.summaryNote,
    this.reflectionMood,
    this.isCountedInHistory = true,
  });

  /// 从 JSON Map 还原
  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      sessionId: json['sessionId'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt'] as String)
          : null,
      plannedDuration: (json['plannedDuration'] as num?)?.toDouble(),
      actualDuration: (json['actualDuration'] as num).toDouble(),
      mode: FocusMode.values.byName(json['mode'] as String),
      status: SessionStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      taskTag: json['taskTag'] as String?,
      summaryNote: json['summaryNote'] as String?,
      reflectionMood: json['reflectionMood'] != null
          ? ReflectionMood.values.byName(json['reflectionMood'] as String)
          : null,
      isCountedInHistory: json['isCountedInHistory'] as bool? ?? true,
    );
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'mode': mode.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'taskTag': taskTag,
      'summaryNote': summaryNote,
      'reflectionMood': reflectionMood?.name,
      'isCountedInHistory': isCountedInHistory,
    };
  }

  /// 不可变更新
  FocusSession copyWith({
    String? sessionId,
    DateTime? startAt,
    DateTime? endAt,
    double? plannedDuration,
    double? actualDuration,
    FocusMode? mode,
    SessionStatus? status,
    DateTime? createdAt,
    String? taskTag,
    String? summaryNote,
    ReflectionMood? reflectionMood,
    bool? isCountedInHistory,
  }) {
    return FocusSession(
      sessionId: sessionId ?? this.sessionId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      taskTag: taskTag ?? this.taskTag,
      summaryNote: summaryNote ?? this.summaryNote,
      reflectionMood: reflectionMood ?? this.reflectionMood,
      isCountedInHistory: isCountedInHistory ?? this.isCountedInHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() => 'FocusSession($sessionId, $status, ${actualDuration}s)';
}

/// 计时模式（与 IncenseViewModel 的 TimerMode 对齐）
enum FocusMode {
  /// 倒计时：用户设定时长，到 0 完成
  countdown,

  /// 正计时：自由计时，用户手动停止
  countUp,
}

/// 会话终态
enum SessionStatus {
  /// 正常完成（倒计时跑完 / 用户主动结束正计时）
  completed,

  /// 用户主动放弃（点了重置 / 退出）
  abandoned,

  /// 异常中断（系统杀进程、后台恢复失败等）
  interrupted,
}

/// 完成感受
enum ReflectionMood {
  /// 专注
  focused,

  /// 分心
  distracted,

  /// 高效
  productive,

  /// 平静
  calm,

  /// 疲惫
  tired,
}
