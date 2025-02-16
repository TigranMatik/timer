class TimerSession {
  final String name;
  final int duration;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final String id;
  final int targetDuration;

  const TimerSession({
    required this.name,
    required this.duration,
    required this.startTime,
    required this.id,
    required this.targetDuration,
    this.endTime,
    this.isCompleted = false,
  });

  // Calculate actual duration in seconds
  int get actualDuration {
    if (!isCompleted || endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }

  // Format duration for display (optimized)
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Format time for display (optimized)
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(startTime.year, startTime.month, startTime.day);
    final timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    
    if (sessionDate == today) {
      return 'Today at $timeStr';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    }
    return '${startTime.day}/${startTime.month} at $timeStr';
  }

  // Create from JSON (optimized)
  factory TimerSession.fromJson(Map<String, dynamic> json) => TimerSession(
    name: json['name'] as String,
    duration: json['duration'] as int,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    isCompleted: json['isCompleted'] as bool,
    id: json['id'] as String,
    targetDuration: json['targetDuration'] as int,
  );

  // Convert to JSON (optimized)
  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': duration,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'isCompleted': isCompleted,
    'id': id,
    'targetDuration': targetDuration,
  };

  @override
  String toString() => 'TimerSession(name: $name, duration: $duration, isCompleted: $isCompleted)';
} 