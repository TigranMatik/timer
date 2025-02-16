import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_session.dart';
import '../services/timer_service.dart';
import 'package:confetti/confetti.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bounceController;
  late AnimationController _selectionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _selectionAnimation;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isPlaying = false;
  int _selectedDuration = 25 * 60;
  int _currentTime = 25 * 60;
  DateTime? _sessionStartTime;
  TimerSession? _currentSession;
  late TimerService _timerService;
  bool _isInitialized = false;
  late ConfettiController _confettiController;
  
  // Add variables to track timer state
  
  // Add list for recent timers
  final List<int> _recentTimers = [25 * 60]; // Start with default 25 minutes

  // Add new fields for timer names
  final Map<int, String> _timerNames = {25 * 60: 'Focus Timer'};

  // Add constants for timer naming
  static const int maxNameLength = 20;
  static const String defaultTimerName = 'Focus Timer';

  static const String _recentTimersKey = 'recent_timers';
  static const String _timerNamesKey = 'timer_names';
  static const String _timerStateKey = 'timer_state';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _initializeTimer();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.05)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_bounceController);
    _initializeServices();
    _loadTimerState();
  }

  @override
  void deactivate() {
    // Don't stop the timer when navigating away
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    // Update the UI to reflect current timer state
    if (_isPlaying) {
      setState(() {
        // Recalculate current time based on elapsed time
        if (_sessionStartTime != null) {
          final now = DateTime.now();
          final elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
          final remainingTime = _selectedDuration - elapsedSeconds;
          
          if (remainingTime > 0) {
            _currentTime = remainingTime;
            double progress = 1.0 - (remainingTime / _selectedDuration);
            _controller.forward(from: progress);
          } else {
            // Timer would have completed
            _currentTime = 0;
            _isPlaying = false;
            _onTimerComplete();
          }
        }
      });
    }
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timerService = TimerService(prefs);
      
      // Load recent timers
      final recentTimersJson = prefs.getString(_recentTimersKey);
      if (recentTimersJson != null) {
        final List<dynamic> decoded = json.decode(recentTimersJson);
        _recentTimers.clear();
        _recentTimers.addAll(decoded.cast<int>());
      }
      
      // Load timer names
      final timerNamesJson = prefs.getString(_timerNamesKey);
      if (timerNamesJson != null) {
        final Map<String, dynamic> decoded = json.decode(timerNamesJson);
        _timerNames.clear();
        decoded.forEach((key, value) {
          _timerNames[int.parse(key)] = value as String;
        });
      }
      
      _isInitialized = true;
    });
  }

  Future<void> _saveRecentTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_recentTimers);
    await prefs.setString(_recentTimersKey, encoded);
  }

  Future<void> _saveTimerNames() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> encoded = {};
    _timerNames.forEach((key, value) {
      encoded[key.toString()] = value;
    });
    await prefs.setString(_timerNamesKey, json.encode(encoded));
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final timerStateJson = prefs.getString(_timerStateKey);
    
    if (timerStateJson != null) {
      final Map<String, dynamic> timerState = json.decode(timerStateJson);
      final bool wasPlaying = timerState['isPlaying'] ?? false;
      final int savedTime = timerState['currentTime'] ?? _selectedDuration;
      final int savedDuration = timerState['selectedDuration'] ?? _selectedDuration;
      final String? sessionStartTimeStr = timerState['sessionStartTime'];
      
      setState(() {
        _selectedDuration = savedDuration;
        _currentTime = savedTime;
        
        if (sessionStartTimeStr != null) {
          _sessionStartTime = DateTime.parse(sessionStartTimeStr);
          _currentSession = TimerSession(
            name: _timerNames[_selectedDuration] ?? defaultTimerName,
            duration: _selectedDuration,
            startTime: _sessionStartTime!,
            id: DateTime.now().toIso8601String(),
            targetDuration: _selectedDuration,
          );
        }
        
        if (wasPlaying) {
          // Calculate elapsed time since last save
          final now = DateTime.now();
          if (_sessionStartTime != null) {
            final elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
            final remainingTime = _selectedDuration - elapsedSeconds;
            
            if (remainingTime > 0) {
              _currentTime = remainingTime;
              _isPlaying = true;
              double progress = 1.0 - (remainingTime / _selectedDuration);
              _controller.duration = Duration(seconds: _selectedDuration);
              _controller.forward(from: progress);
            } else {
              // Timer would have completed
              _currentTime = 0;
              _isPlaying = false;
              _onTimerComplete();
            }
          }
        }
      });
    }
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> timerState = {
      'isPlaying': _isPlaying,
      'currentTime': _currentTime,
      'selectedDuration': _selectedDuration,
      'sessionStartTime': _sessionStartTime?.toIso8601String(),
    };
    await prefs.setString(_timerStateKey, json.encode(timerState));
  }

  void _initializeTimer() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedDuration),
    );

    _controller.addListener(() {
      setState(() {
        _currentTime = (_selectedDuration * (1.0 - _controller.value)).ceil();
        if (_currentTime == 0 && _isPlaying) {
          _isPlaying = false;
          _controller.stop();
          _onTimerComplete();
        }
      });
    });
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    
    // Ensure we have a valid session before completing
    if (_currentSession == null && _sessionStartTime != null) {
      _currentSession = TimerSession(
        name: _timerNames[_selectedDuration] ?? defaultTimerName,
        duration: _selectedDuration,
        startTime: _sessionStartTime!,
        id: DateTime.now().toIso8601String(),
        targetDuration: _selectedDuration,
      );
    }
    
    // Complete the session first
    _completeCurrentSession(true);
    
    // Show completion screen immediately
    _showCompletionScreen();
    
    // Update state after showing completion screen
    setState(() {
      _isPlaying = false;
      _controller.stop();
    });
  }

  void _completeCurrentSession(bool completed) {
    if (_currentSession != null && _sessionStartTime != null) {
      final session = TimerSession(
        name: _currentSession!.name,
        duration: _currentSession!.duration,
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        isCompleted: completed,
        id: DateTime.now().toIso8601String(),
        targetDuration: _selectedDuration,
      );
      
      // Keep a reference to the completed session before clearing
      _currentSession = session;
      
      // Add to timer service
      _timerService.addSession(session);
      
      // Clear session data after completion screen is shown
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _sessionStartTime = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    _bounceController.dispose();
    _selectionController.dispose();
    // Clear any cached data
    _timerService.clearCache();
    _recentTimers.clear();
    _timerNames.clear();
    super.dispose();
  }

  String _formatTime(int timeInSeconds) {
    final hours = timeInSeconds ~/ 3600;
    final minutes = (timeInSeconds % 3600) ~/ 60;
    final seconds = timeInSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_currentTime == 0) {
        _resetTimer();
        return;
      }
      
      _isPlaying = !_isPlaying;
      
      if (_isPlaying) {
        // Start new session or resume existing one
        if (_currentSession == null) {
          _sessionStartTime = DateTime.now();
          _currentSession = TimerSession(
            name: _timerNames[_selectedDuration] ?? defaultTimerName,
            duration: _selectedDuration,
            startTime: _sessionStartTime!, 
            id: DateTime.now().toIso8601String(),
            targetDuration: _selectedDuration,
          );
          // Only set duration and start from beginning for new sessions
          _controller.duration = Duration(seconds: _selectedDuration);
          double progress = 1.0 - (_currentTime / _selectedDuration);
          _controller.forward(from: progress);
        } else {
          // Resume from current position
          _controller.forward();
        }
      } else {
        _controller.stop();
      }
      
      // Save timer state
      _saveTimerState();
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _controller.reset();
      _currentTime = _selectedDuration;
      _isPlaying = false;
      
      // Complete current session as cancelled
      if (_currentSession != null) {
        _completeCurrentSession(false);
      }
      
      // Clear saved timer state
      _sessionStartTime = null;
      _currentSession = null;
      _saveTimerState();
    });
  }

  void _removeRecentTimer(int seconds) {
    int index = _recentTimers.indexOf(seconds);
    if (index != -1) {
      // Remove from the list first
      setState(() {
        _recentTimers.removeAt(index);
        // Save immediately after removing
        _saveRecentTimers();
      });
      
      // Then handle the animation
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildRecentTimerButtonWithAnimation(
          seconds,
          animation.drive(CurveTween(curve: Curves.easeInOut)),
        ),
        duration: const Duration(milliseconds: 300),
      );
      
      HapticFeedback.mediumImpact();
    }
  }

  void _addRecentTimer(int seconds) {
    setState(() {
      // Remove if already exists
      int existingIndex = _recentTimers.indexOf(seconds);
      if (existingIndex != -1) {
        _recentTimers.removeAt(existingIndex);
        _listKey.currentState?.removeItem(
          existingIndex,
          (context, animation) => _buildRecentTimerButtonWithAnimation(seconds, animation),
          duration: const Duration(milliseconds: 200),
        );
      }
      
      // Add to beginning of list
      _recentTimers.insert(0, seconds);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
      
      // Keep only last 5 recent timers
      if (_recentTimers.length > 5) {
        int lastIndex = _recentTimers.length - 1;
        int removedSeconds = _recentTimers[lastIndex];
        _recentTimers.removeLast();
        _listKey.currentState?.removeItem(
          lastIndex,
          (context, animation) => _buildRecentTimerButtonWithAnimation(removedSeconds, animation),
          duration: const Duration(milliseconds: 200),
        );
      }
      
      // Save to SharedPreferences
      _saveRecentTimers();
    });
  }

  void _setNewTimer(int seconds, {String? name}) {
    // Start selection animation
    _selectionController.forward(from: 0);
    
    setState(() {
      // Always stop and reset the current timer
      _controller.stop();
      _isPlaying = false;
      
      // Update duration and reset
      _selectedDuration = seconds;
      _currentTime = _selectedDuration;
      _controller.duration = Duration(seconds: _selectedDuration);
      _controller.reset();
      
      // Store timer name
      if (name != null) {
        _timerNames[seconds] = name;
        _saveTimerNames();
      }
      
      // Add to recent timers
      _addRecentTimer(_selectedDuration);
    });
    HapticFeedback.mediumImpact();
  }

  Widget _buildRecentTimerButtonWithAnimation(int seconds, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildRecentTimerButton(seconds),
      ),
    );
  }

  Widget _buildRecentTimerButton(int seconds) {
    bool isActive = _selectedDuration == seconds;
    String timeStr = _formatTime(seconds);
    String timerName = _timerNames[seconds] ?? defaultTimerName;
    bool isDefaultName = timerName == defaultTimerName;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    
    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(seconds),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removeRecentTimer(seconds),
        confirmDismiss: (direction) async {
          bool? result = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete Timer'),
              content: Text(
                'Remove "$timerName" ($timeStr) from recent timers?',
                style: const TextStyle(fontSize: 13),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  isDefaultAction: true,
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, true),
                  isDestructiveAction: true,
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          return result ?? false;
        },
        background: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          alignment: Alignment.centerRight,
          child: Icon(
            CupertinoIcons.delete,
            color: Colors.red.withOpacity(0.8),
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        child: AnimatedBuilder(
          animation: _selectionAnimation,
          builder: (context, child) {
            final scale = isActive 
              ? Tween<double>(begin: 1.0, end: 1.05).evaluate(_selectionAnimation)
              : 1.0;
            final opacity = isActive
              ? Tween<double>(begin: 0.8, end: 1.0).evaluate(_selectionAnimation)
              : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onLongPress: () => _showEditTimerDialog(seconds),
            onTap: () {
              _setNewTimer(seconds, name: timerName);
              HapticFeedback.selectionClick();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE0C1A3).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? const Color(0xFFE0C1A3).withOpacity(0.3) : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFFE0C1A3).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive 
                          ? (isDefaultName ? CupertinoIcons.timer_fill : CupertinoIcons.star_fill)
                          : (isDefaultName ? CupertinoIcons.timer : CupertinoIcons.star),
                        size: isSmallScreen ? 12 : 14,
                        color: isActive ? const Color(0xFFE0C1A3) : Colors.white.withOpacity(0.5),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                          color: isActive ? const Color(0xFFE0C1A3) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDefaultName) ...[
                        Icon(
                          CupertinoIcons.pencil,
                          size: isSmallScreen ? 9 : 10,
                          color: isActive ? const Color(0xFFE0C1A3).withOpacity(0.8) : Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(width: isSmallScreen ? 3 : 4),
                      ],
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? 80 : 100,
                        ),
                        child: Text(
                          timerName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: isDefaultName ? FontWeight.w400 : FontWeight.w500,
                            color: isActive 
                              ? const Color(0xFFE0C1A3).withOpacity(isDefaultName ? 0.8 : 1.0)
                              : Colors.white.withOpacity(isDefaultName ? 0.5 : 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTimerDialog(int seconds) {
    String currentName = _timerNames[seconds] ?? defaultTimerName;
    String tempName = currentName;
    final textController = TextEditingController(text: currentName == defaultTimerName ? '' : currentName);
    final focusNode = FocusNode();
    bool hasError = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E23),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            'Rename Timer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${textController.text.length}/$maxNameLength',
                            style: TextStyle(
                              fontSize: 13,
                              color: textController.text.length >= maxNameLength 
                                ? Colors.red.withOpacity(0.8)
                                : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasError 
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.textformat,
                                  color: hasError 
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CupertinoTextField.borderless(
                                    controller: textController,
                                    focusNode: focusNode,
                                    placeholder: 'Enter timer name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    placeholderStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 16,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        tempName = value;
                                        hasError = value.length > maxNameLength;
                                      });
                                    },
                                    onSubmitted: (value) {
                                      if (!hasError && value.isNotEmpty) {
                                        _timerNames[seconds] = value.trim();
                                        Navigator.pop(context);
                                        HapticFeedback.mediumImpact();
                                      }
                                    },
                                  ),
                                ),
                                if (textController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        textController.clear();
                                        tempName = '';
                                        hasError = false;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Icon(
                                      CupertinoIcons.clear_circled_solid,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16),
                              child: Text(
                                'Name is too long',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!hasError) {
                                  String finalName = tempName.trim();
                                  if (finalName.isEmpty) {
                                    finalName = defaultTimerName;
                                  }
                                  _timerNames[seconds] = finalName;
                                  Navigator.pop(context);
                                  HapticFeedback.mediumImpact();
                                }
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: hasError || tempName.trim().isEmpty
                                    ? const Color(0xFFE0C1A3).withOpacity(0.5)
                                    : const Color(0xFFE0C1A3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.pencil,
                                      color: Color(0xFF17171A),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rename',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF17171A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      textController.dispose();
      focusNode.dispose();
    });
  }

  void _showCustomTimePicker() {
    int tempDuration = _selectedDuration;
    String tempName = '';
    TextEditingController textController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E23),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Text(
                              'Create Timer',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            if (_isPlaying) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0C1A3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Timer Running',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFE0C1A3),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.textformat,
                                color: Colors.white.withOpacity(0.8),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CupertinoTextField.borderless(
                                  controller: textController,
                                  placeholder: 'Timer Name (Optional)',
                                  style: const TextStyle(color: Colors.white),
                                  placeholderStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      tempName = value;
                                    });
                                  },
                                  maxLength: maxNameLength,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${tempName.length}/$maxNameLength',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 280,
                        child: CupertinoTimerPicker(
                          mode: CupertinoTimerPickerMode.hms,
                          initialTimerDuration: Duration(seconds: _selectedDuration),
                          backgroundColor: Colors.transparent,
                          onTimerDurationChanged: (Duration newDuration) {
                            tempDuration = newDuration.inSeconds;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _setNewTimer(
                                    tempDuration,
                                    name: tempName.isNotEmpty ? tempName : null,
                                  );
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0C1A3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.timer,
                                        color: Color(0xFF17171A),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Create Timer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF17171A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _bounceController.forward(from: 0);
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _bounceController.reverse();
          _toggleTimer();
        });
      },
      onTapCancel: () {
        _bounceController.reverse();
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _controller]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying ? const Color(0xFFE0C1A3) : Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: _isPlaying 
                      ? const Color(0xFFE0C1A3).withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
                border: Border.all(
                  color: _isPlaying 
                    ? Colors.transparent 
                    : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isPlaying ? 1.0 : 0.0,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE0C1A3).withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Icon with enhanced animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      key: ValueKey<bool>(_isPlaying),
                      color: _isPlaying ? const Color(0xFF17171A) : Colors.white.withOpacity(0.8),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentTimerName = _timerNames[_selectedDuration] ?? defaultTimerName;
    bool isDefaultName = currentTimerName == defaultTimerName;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.height < 700;

    return RepaintBoundary(
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF17171A),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF17171A),
                Color(0xFF1E1E23),
                Color(0xFF17171A),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showEditTimerDialog(_selectedDuration),
                          child: Row(
                            children: [
                              Icon(
                                isDefaultName ? CupertinoIcons.clock : CupertinoIcons.star,
                                color: Colors.white.withOpacity(0.7),
                                size: isSmallScreen ? 16 : 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  currentTimerName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.pencil,
                                color: Colors.white.withOpacity(0.3),
                                size: isSmallScreen ? 12 : 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showCustomTimePicker,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 10 : 12,
                            vertical: isSmallScreen ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.plus,
                            color: Colors.white.withOpacity(0.8),
                            size: isSmallScreen ? 16 : 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: isSmallScreen ? 240 : 280,
                            height: isSmallScreen ? 240 : 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE0C1A3).withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? 220 : 260,
                            height: isSmallScreen ? 220 : 260,
                            child: CustomPaint(
                              painter: TimerPainter(
                                animation: _controller,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                progressColor: const Color(0xFFE0C1A3),
                                shadowColor: const Color(0xFFE0C1A3).withOpacity(0.3),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(_currentTime),
                                style: TextStyle(
                                  fontFamily: '.SF Pro Display',
                                  fontSize: _currentTime >= 3600 
                                    ? (isSmallScreen ? 44 : 52)  // Smaller size for hours format
                                    : (isSmallScreen ? 56 : 64), // Larger size for minutes format
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isPlaying ? 'Focusing...' : _currentTime == 0 ? 'Time\'s up!' : 'minutes remaining',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(
                            icon: CupertinoIcons.refresh,
                            onTap: _resetTimer,
                          ),
                          SizedBox(width: isSmallScreen ? 24 : 32),
                          _buildPlayPauseButton(),
                          SizedBox(width: isSmallScreen ? 24 : 32),
                          _buildControlButton(
                            icon: CupertinoIcons.clock,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showHistorySheet();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                        top: isSmallScreen ? 16 : 24,
                        bottom: mediaQuery.padding.bottom + (isSmallScreen ? 16 : 24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Timers',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (_recentTimers.length > 1)
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) => CupertinoAlertDialog(
                                          title: const Text('Clear Recent Timers'),
                                          content: const Text(
                                            'Are you sure you want to clear all recent timers except the current one?',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          actions: [
                                            CupertinoDialogAction(
                                              onPressed: () => Navigator.pop(context),
                                              isDefaultAction: true,
                                              child: const Text('Cancel'),
                                            ),
                                            CupertinoDialogAction(
                                              onPressed: () {
                                                setState(() {
                                                  int currentTimer = _selectedDuration;
                                                  _recentTimers.clear();
                                                  _recentTimers.add(currentTimer);
                                                  _listKey.currentState?.removeAllItems(
                                                    (context, animation) => Container(),
                                                    duration: const Duration(milliseconds: 300),
                                                  );
                                                });
                                                Navigator.pop(context);
                                              },
                                              isDestructiveAction: true,
                                              child: const Text('Clear All'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Clear All',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: isSmallScreen ? 72 : 80,
                            child: AnimatedList(
                              key: _listKey,
                              scrollDirection: Axis.horizontal,
                              initialItemCount: _recentTimers.length,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemBuilder: (context, index, animation) {
                                return _buildRecentTimerButtonWithAnimation(
                                  _recentTimers[index],
                                  animation,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E23),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.delete,
                      color: Colors.red.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clear Timer History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to clear all timer history?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Close the confirmation dialog
                            Navigator.pop(context);
                            
                            // Clear sessions
                            await _timerService.clearSessions();
                            
                            // Close history sheet and rebuild the widget
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            
                            // Force rebuild of the widget
                            setState(() {});
                            
                            // Show success message
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF32D74B).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.checkmark_alt,
                                          color: const Color(0xFF32D74B).withOpacity(0.8),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Timer history cleared',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                backgroundColor: const Color(0xFF1E1E23),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.delete,
                                  color: Colors.red.withOpacity(0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Clear History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    if (!_isInitialized) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sessions = _timerService.sessions;
            final totalSessions = _timerService.totalSessions;
            final totalTime = _timerService.formatDuration(_timerService.totalFocusTime);
            final averageTime = _timerService.formatDuration(_timerService.averageSessionDuration);
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E23),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timer History',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        if (sessions.isNotEmpty)
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _showClearHistoryDialog,
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: CupertinoIcons.timer,
                          value: totalSessions.toString(),
                          label: 'Sessions',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          icon: CupertinoIcons.clock,
                          value: totalTime,
                          label: 'Total Time',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          icon: CupertinoIcons.star,
                          value: averageTime,
                          label: 'Average',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sessions.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.timer,
                              size: 48,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Timer History',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete your first timer to see it here',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _buildHistoryItem(session);
                        },
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        addSemanticIndexes: false,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFFE0C1A3),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(TimerSession session) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: session.isCompleted 
                  ? const Color(0xFFE0C1A3).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.isCompleted ? CupertinoIcons.checkmark_alt : CupertinoIcons.xmark,
                color: session.isCompleted 
                  ? const Color(0xFFE0C1A3)
                  : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.formattedDuration} • ${session.formattedTime}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: session.isCompleted 
                  ? const Color(0xFFE0C1A3).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.isCompleted ? 'Completed' : 'Cancelled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: session.isCompleted 
                    ? const Color(0xFFE0C1A3)
                    : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionScreen() {
    if (_currentSession == null) return;

    // Reduce particle count for better performance
    _confettiController.play();
    
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return RepaintBoundary(
          child: Scaffold(
            backgroundColor: const Color(0xFF17171A),
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: math.pi / 2,
                    maxBlastForce: 5,
                    minBlastForce: 2,
                    emissionFrequency: 0.05,
                    numberOfParticles: 50,
                    gravity: 0.1,
                    colors: const [
                      Color(0xFFE0C1A3),
                      Colors.white,
                      Color(0xFFFFC107),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0C1A3).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Color(0xFFE0C1A3),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'Timer Complete!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentSession!.name,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildCompletionStat(
                                icon: CupertinoIcons.clock,
                                label: 'Duration',
                                value: _currentSession!.formattedDuration,
                              ),
                              const SizedBox(height: 16),
                              _buildCompletionStat(
                                icon: CupertinoIcons.calendar,
                                label: 'Completed at',
                                value: _currentSession!.formattedTime,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0C1A3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF17171A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      barrierDismissible: false,
      barrierColor: Colors.black,
    );
  }

  Widget _buildCompletionStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE0C1A3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFE0C1A3),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor;
  final Color progressColor;
  final Color shadowColor;

  TimerPainter({
    required this.animation,
    required this.backgroundColor,
    required this.progressColor,
    required this.shadowColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.0;

    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final shadowPaint = Paint()
      ..color = shadowColor
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    double progress = animation.value * 2 * math.pi;
    
    // Draw shadow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi - progress,
      false,
      shadowPaint,
    );

    // Draw main progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi - progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        backgroundColor != oldDelegate.backgroundColor ||
        progressColor != oldDelegate.progressColor ||
        shadowColor != oldDelegate.shadowColor;
  }
} 