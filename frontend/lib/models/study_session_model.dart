class StudySession {
  final String id;
  final String subject;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  StudySession({
    required this.id,
    required this.subject,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      subject: json['subject'] as String,
      duration: Duration(seconds: json['duration'] as int),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'duration': duration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'notes': notes,
    };
  }
}
