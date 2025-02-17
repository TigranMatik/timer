import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_session.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class TimerService {
  static const String _sessionsKey = 'timer_sessions';
  static const String _timerNamesKey = 'timer_names';
  static const int _maxSessions = 100;
  final SharedPreferences _prefs;
  List<TimerSession> _sessions = [];
  Set<String> _timerNames = {};
  bool _isDirty = false;

  TimerService(this._prefs) {
    loadSessions();
    _loadTimerNames();
  }

  // Load sessions from storage
  void loadSessions() {
    try {
      final String? sessionsJson = _prefs.getString(_sessionsKey);
      if (sessionsJson != null) {
        final List<dynamic> decoded = json.decode(sessionsJson);
        _sessions = decoded.map((json) => TimerSession.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading timer sessions: $e');
      _sessions = [];
    }
  }

  // Load timer names from storage
  void _loadTimerNames() {
    try {
      final String? namesJson = _prefs.getString(_timerNamesKey);
      if (namesJson != null) {
        final dynamic decoded = json.decode(namesJson);
        if (decoded is List) {
          _timerNames = Set<String>.from(decoded);
        } else if (decoded is Map) {
          _timerNames = Set<String>.from(decoded.values);
        }
      }
    } catch (e) {
      debugPrint('Error loading timer names: $e');
      _timerNames = {};
    }
  }

  // Save sessions to storage
  Future<void> _saveSessions() async {
    if (!_isDirty) return;
    
    try {
      final sessionsJson = _sessions.map((s) => s.toJson()).toList();
      await _prefs.setString(_sessionsKey, json.encode(sessionsJson));
      _isDirty = false;
    } catch (e) {
      debugPrint('Error saving timer sessions: $e');
    }
  }

  // Save timer names to storage
  Future<void> _saveTimerNames() async {
    final String encoded = json.encode(_timerNames.toList());
    await _prefs.setString(_timerNamesKey, encoded);
  }

  // Add new session
  Future<void> addSession(TimerSession session) async {
    _sessions.insert(0, session);
    _isDirty = true;
    
    // Keep only last 100 sessions
    if (_sessions.length > _maxSessions) {
      _sessions = _sessions.sublist(0, _maxSessions);
    }
    
    _timerNames.add(session.name);
    await _saveSessions();
    await _saveTimerNames();
  }

  // Update existing session
  Future<void> updateSession(TimerSession oldSession, TimerSession newSession) async {
    final index = _sessions.indexOf(oldSession);
    if (index != -1) {
      _sessions[index] = newSession;
      _timerNames.add(newSession.name);
      await Future.wait([
        _saveSessions(),
        _saveTimerNames(),
      ]);
    }
  }

  // Clear all sessions
  Future<void> clearSessions() async {
    _sessions.clear();
    _isDirty = true;
    await _saveSessions();
  }

  // Get all sessions
  List<TimerSession> get sessions => List.unmodifiable(_sessions);

  // Get saved timer names
  List<String> get timerNames => _timerNames.toList();

  // Get total number of sessions
  int get totalSessions => _sessions.length;

  // Get total focus time in seconds (optimized to only count completed sessions)
  Duration get totalFocusTime {
    if (_sessions.isEmpty) return Duration.zero;
    return Duration(seconds: _sessions
        .where((s) => s.isCompleted)
        .fold(0, (sum, session) => sum + session.actualDuration));
  }

  // Get average session duration in seconds (optimized)
  Duration get averageSessionDuration {
    final completedSessions = _sessions.where((s) => s.isCompleted).toList();
    if (completedSessions.isEmpty) return Duration.zero;
    
    final totalSeconds = completedSessions.fold(0, (sum, session) => sum + session.actualDuration);
    return Duration(seconds: totalSeconds ~/ completedSessions.length);
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void clearCache() {
    _sessions.clear();
    _isDirty = false;
  }

  // Get longest completed session duration
  Duration get longestSession {
    if (_sessions.isEmpty) return Duration.zero;
    
    return Duration(seconds: _sessions
        .where((s) => s.isCompleted)
        .fold(0, (maxDuration, session) => 
            math.max(maxDuration, session.actualDuration)));
  }
} 