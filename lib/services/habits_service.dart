import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer/services/pro_service.dart';
import '../models/habit.dart';
import 'package:flutter/foundation.dart';

class HabitsService {
  final SharedPreferences _prefs;
  final ProService _proService;
  List<Habit> _habits = [];
  bool _isInitialized = false;
  bool _isDirty = false;
  static const String _habitsKey = 'habits';

  HabitsService(this._prefs, this._proService);

  bool get isInitialized => _isInitialized;
  List<Habit> get habits => List.unmodifiable(_habits);
  int get totalHabits => _habits.length;
  int get completedHabitsToday => _habits.where((h) => h.isCompletedToday).length;
  bool get canAddMoreHabits => _proService.isPro || totalHabits < _proService.getMaxHabits();
  int get maxHabits => _proService.getMaxHabits();

  double get todayCompletionRate {
    if (_habits.isEmpty) return 0.0;
    return completedHabitsToday / totalHabits;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final habitsJson = _prefs.getString(_habitsKey);
      if (habitsJson != null) {
        // Initialize with empty list if data is invalid
        _habits = [];
        
        final dynamic decoded = json.decode(habitsJson);
        if (decoded is List) {
          _habits = decoded
              .whereType<Map<String, dynamic>>()
              .map((json) => Habit.fromJson(json))
              .toList();
        }
        
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
      } else {
        _habits = [];
      }
    } catch (e) {
      debugPrint('Error initializing habits: $e');
      _habits = [];
    }
    
    _isInitialized = true;
  }

  Future<bool> addHabit(Habit habit) async {
    if (!canAddMoreHabits) {
      return false;
    }
    
    _habits.add(habit);
    _isDirty = true;
    await _saveHabits();
    return true;
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
      final List<Map<String, dynamic>> habitsJson = _habits.map((h) => h.toJson()).toList();
      final String encoded = json.encode(habitsJson);
      await _prefs.setString(_habitsKey, encoded);
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