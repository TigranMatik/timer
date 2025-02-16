import 'package:flutter/material.dart';
import 'dart:math' as math;

class Habit {
  String id;
  String name;
  int streak;
  bool completed;
  String goal;
  DateTime? lastCompleted;
  List<String> milestones;
  List<String> unlockedMilestones;
  DateTime? lastStreakRecovery;
  
  // New fields for frequency and reminders
  FrequencyType frequencyType;
  int frequencyCount;
  List<TimeOfDay> reminderTimes;
  List<bool> activeDays; // For weekly habits, represents days from Monday (index 0) to Sunday (index 6)

  static const List<int> milestoneDays = [3, 7, 14, 30, 60, 90, 180, 365];
  static const Map<int, String> milestoneEmojis = {
    3: '🌱', // Seedling
    7: '🌿', // Growing
    14: '🌺', // Blooming
    30: '🌳', // Tree
    60: '⭐', // Star
    90: '🌟', // Glowing Star
    180: '🏆', // Trophy
    365: '👑', // Crown
  };

  Habit({
    required this.id,
    required this.name,
    this.streak = 0,
    this.completed = false,
    this.goal = 'Daily',
    this.lastCompleted,
    List<String>? milestones,
    List<String>? unlockedMilestones,
    this.lastStreakRecovery,
    this.frequencyType = FrequencyType.daily,
    this.frequencyCount = 1,
    List<TimeOfDay>? reminderTimes,
    List<bool>? activeDays,
  })  : milestones = milestones ?? [],
        unlockedMilestones = unlockedMilestones ?? [],
        reminderTimes = reminderTimes ?? [],
        activeDays = activeDays ?? List.generate(7, (index) => true);

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCompletedDate = DateTime(
      lastCompleted!.year,
      lastCompleted!.month,
      lastCompleted!.day,
    );
    return lastCompletedDate == today;
  }

  bool get isActiveToday {
    if (frequencyType != FrequencyType.weekly) return true;
    final now = DateTime.now();
    // Adjust to make Monday index 0
    final dayIndex = (now.weekday - 1) % 7;
    return activeDays[dayIndex];
  }

  bool canRecoverStreak() {
    if (lastStreakRecovery == null) return true;
    
    final now = DateTime.now();
    final lastRecoveryMonth = DateTime(
      lastStreakRecovery!.year,
      lastStreakRecovery!.month,
      1,
    );
    final currentMonth = DateTime(now.year, now.month, 1);
    
    return currentMonth.isAfter(lastRecoveryMonth);
  }

  void recoverStreak() {
    if (!canRecoverStreak()) return;
    
    final now = DateTime.now();
    lastStreakRecovery = now;
    lastCompleted = now;
    streak = math.max(1, streak); // Ensure at least 1 day streak
  }

  String get frequencyText {
    switch (frequencyType) {
      case FrequencyType.daily:
        return frequencyCount == 1 
          ? 'Once a day'
          : '$frequencyCount times a day';
      case FrequencyType.weekly:
        final activeDayCount = activeDays.where((day) => day).length;
        return '$frequencyCount time${frequencyCount > 1 ? 's' : ''} on $activeDayCount day${activeDayCount > 1 ? 's' : ''} a week';
      case FrequencyType.hourly:
        return 'Every $frequencyCount hour${frequencyCount > 1 ? 's' : ''}';
    }
  }

  void checkCompletion() {
    if (lastCompleted == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastCompletedDate = DateTime(
      lastCompleted!.year,
      lastCompleted!.month,
      lastCompleted!.day,
    );

    if (lastCompletedDate == yesterday) {
      // Streak continues
    } else if (lastCompletedDate != today && lastCompletedDate != yesterday) {
      // Streak broken
      streak = 0;
    }
  }

  void toggleCompletion() {
    final now = DateTime.now();
    
    if (!completed) {
      if (isCompletedToday) return; // Prevent multiple completions per day
      
      completed = true;
      
      if (lastCompleted != null) {
        final today = DateTime(now.year, now.month, now.day);
        final lastCompletedDate = DateTime(
          lastCompleted!.year,
          lastCompleted!.month,
          lastCompleted!.day,
        );
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (lastCompletedDate == yesterday) {
          streak++; // Continue streak
        } else if (lastCompletedDate != today) {
          streak = 1; // Start new streak
        }
      } else {
        streak = 1; // First completion
      }
      
      lastCompleted = now;
      checkMilestones();
    } else {
      if (isCompletedToday) {
        completed = false;
        streak = math.max(0, streak - 1);
        lastCompleted = null;
      }
    }
  }

  void checkMilestones() {
    for (final days in milestoneDays) {
      if (streak >= days) {
        final milestone = milestoneEmojis[days];
        if (milestone != null && !unlockedMilestones.contains(milestone)) {
          unlockedMilestones.add(milestone);
          milestones.add(milestone);
        }
      }
    }
  }

  String getNextMilestone() {
    for (final days in milestoneDays) {
      if (streak < days) {
        return '${milestoneEmojis[days]} $days days';
      }
    }
    return 'All milestones achieved! 🎉';
  }

  int getDaysUntilNextMilestone() {
    for (final days in milestoneDays) {
      if (streak < days) {
        return days - streak;
      }
    }
    return 0;
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      streak: json['streak'] as int,
      completed: json['completed'] as bool,
      goal: json['goal'] as String,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'] as String)
          : null,
      lastStreakRecovery: json['lastStreakRecovery'] != null
          ? DateTime.parse(json['lastStreakRecovery'] as String)
          : null,
      milestones: List<String>.from(json['milestones'] ?? []),
      unlockedMilestones: List<String>.from(json['unlockedMilestones'] ?? []),
      frequencyType: FrequencyType.values[json['frequencyType'] as int],
      frequencyCount: json['frequencyCount'] as int,
      reminderTimes: (json['reminderTimes'] as List<dynamic>?)?.map((time) {
        final parts = (time as String).split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList() ?? [],
      activeDays: List<bool>.from(json['activeDays'] ?? List.generate(7, (index) => true)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streak': streak,
      'completed': completed,
      'goal': goal,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'lastStreakRecovery': lastStreakRecovery?.toIso8601String(),
      'milestones': milestones,
      'unlockedMilestones': unlockedMilestones,
      'frequencyType': frequencyType.index,
      'frequencyCount': frequencyCount,
      'reminderTimes': reminderTimes.map((time) => '${time.hour}:${time.minute}').toList(),
      'activeDays': activeDays,
    };
  }
}

enum FrequencyType {
  daily,
  weekly,
  hourly,
} 