import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'package:flutter/foundation.dart';

class HabitsService {
  final SharedPreferences _prefs;
  List<Habit> _habits = [];
  bool _isInitialized = false;
  bool _isDirty = false;
  static const String _habitsKey = 'habits';

  HabitsService(this._prefs);

  bool get isInitialized => _isInitialized;
  List<Habit> get habits => List.unmodifiable(_habits);
  int get totalHabits => _habits.length;
  int get completedHabitsToday => _habits.where((h) => h.isCompletedToday).length;

  double get todayCompletionRate {
    if (_habits.isEmpty) return 0.0;
    return completedHabitsToday / totalHabits;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final habitsJson = _prefs.getString(_habitsKey);
      if (habitsJson != null) {
        final List<dynamic> decoded = json.decode(habitsJson);
        _habits = decoded.map((json) => Habit.fromJson(json)).toList();
        
        // Check completion status for each habit
        final now = DateTime.now();
        for (var habit in _habits) {
          if (habit.lastCompleted != null) {
            final lastCompletedDate = DateTime(
              habit.lastCompleted!.year,
              habit.lastCompleted!.month,
              habit.lastCompleted!.day,
            );
            final today = DateTime(now.year, now.month, now.day);
            if (lastCompletedDate != today) {
              habit.completed = false;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      _habits = [];
    }
    
    _isInitialized = true;
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    _isDirty = true;
    await _saveHabits();
  }

  Future<void> updateHabit(String id, Habit updatedHabit) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      _isDirty = true;
      await _saveHabits();
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _isDirty = true;
    await _saveHabits();
  }

  List<Habit> getTopStreaks() {
    if (_habits.isEmpty) return [];
    
    final sortedHabits = List<Habit>.from(_habits)
      ..sort((a, b) => b.streak.compareTo(a.streak));
    
    return sortedHabits.take(3).toList();
  }

  Future<void> _saveHabits() async {
    if (!_isDirty) return;
    
    try {
      final habitsJson = _habits.map((h) => h.toJson()).toList();
      await _prefs.setString(_habitsKey, json.encode(habitsJson));
      _isDirty = false;
    } catch (e) {
      debugPrint('Error saving habits: $e');
    }
  }

  void clearCache() {
    _habits.clear();
    _isDirty = false;
    _isInitialized = false;
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
} 