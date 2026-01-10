class TrainingRecord {
  final String? id;
  final DateTime date;
  final String activity; // 何をしたか
  final String duration; // どれくらいやったか
  final String? comment; // コメント（任意）
  final String? location; // どこでやったか（任意）
  final int monthlyCount; // 月の運動回数
  final DateTime createdAt;

  TrainingRecord({
    this.id,
    required this.date,
    required this.activity,
    required this.duration,
    this.comment,
    this.location,
    required this.monthlyCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Slackメッセージ形式に変換
  String toSlackMessage() {
    final dateText =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final monthText = '${date.month}月の運動回数';

    final List<String> messageLines = [];
    messageLines.add('*日付*');
    messageLines.add(dateText);
    messageLines.add('*何をしたか*');
    messageLines.add(activity);
    messageLines.add('*どれくらいやったか*');
    messageLines.add(duration);

    if (comment != null && comment!.trim().isNotEmpty) {
      messageLines.add('*コメント*');
      messageLines.add(comment!);
    }
    if (location != null && location!.trim().isNotEmpty) {
      messageLines.add('*どこでやったか*');
      messageLines.add(location!);
    }
    messageLines.add('*$monthText*');
    messageLines.add(monthlyCount.toString());

    return messageLines.join('\n');
  }

  /// JSON形式に変換（永続化用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'activity': activity,
      'duration': duration,
      'comment': comment,
      'location': location,
      'monthlyCount': monthlyCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSONから生成
  factory TrainingRecord.fromJson(Map<String, dynamic> json) {
    return TrainingRecord(
      id: json['id'] as String?,
      date: DateTime.parse(json['date'] as String),
      activity: json['activity'] as String,
      duration: json['duration'] as String,
      comment: json['comment'] as String?,
      location: json['location'] as String?,
      monthlyCount: json['monthlyCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// コピーを作成（一部のプロパティを変更）
  TrainingRecord copyWith({
    String? id,
    DateTime? date,
    String? activity,
    String? duration,
    String? comment,
    String? location,
    int? monthlyCount,
    DateTime? createdAt,
  }) {
    return TrainingRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      activity: activity ?? this.activity,
      duration: duration ?? this.duration,
      comment: comment ?? this.comment,
      location: location ?? this.location,
      monthlyCount: monthlyCount ?? this.monthlyCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
