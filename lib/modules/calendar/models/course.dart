class Course {
  final String id;
  final String title;
  final String? description;
  final String? teacherName;
  final DateTime startTime;
  final int durationMinutes;
  final String? telegramLink;
  final String recurrence; // 'once', 'weekly', 'daily'
  final int? recurrenceDay; // 0=Monday...6=Sunday
  final String color;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.teacherName,
    required this.startTime,
    this.durationMinutes = 60,
    this.telegramLink,
    this.recurrence = 'once',
    this.recurrenceDay,
    this.color = '#009688',
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
  });

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  bool get isRecurring => recurrence != 'once';

  String get recurrenceLabel {
    switch (recurrence) {
      case 'weekly':
        return 'Chaque semaine';
      case 'daily':
        return 'Chaque jour';
      default:
        return 'Unique';
    }
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherName: json['teacher_name'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      telegramLink: json['telegram_link'] as String?,
      recurrence: json['recurrence'] as String? ?? 'once',
      recurrenceDay: json['recurrence_day'] as int?,
      color: json['color'] as String? ?? '#009688',
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'teacher_name': teacherName,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'telegram_link': telegramLink,
      'recurrence': recurrence,
      'recurrence_day': recurrenceDay,
      'color': color,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  Course copyWith({
    String? title,
    String? description,
    String? teacherName,
    DateTime? startTime,
    int? durationMinutes,
    String? telegramLink,
    String? recurrence,
    int? recurrenceDay,
    String? color,
    bool? isActive,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherName: teacherName ?? this.teacherName,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      telegramLink: telegramLink ?? this.telegramLink,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
