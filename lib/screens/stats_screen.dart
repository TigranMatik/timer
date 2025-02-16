import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/habits_service.dart';
import '../models/habit.dart';
import 'dart:math' as math;

class StatsScreen extends StatefulWidget {
  final VoidCallback onTimerTap;
  
  const StatsScreen({
    super.key,
    required this.onTimerTap,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  late Future<(HabitsService, TimerService)> _servicesFuture;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create staggered animations for cards
    _cardAnimations = List.generate(4, (index) {
      final start = index * 0.1;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, start + 0.6, curve: Curves.easeOutCubic),
        ),
      );
    });
    
    _animationController.forward();
    _servicesFuture = _initializeServices();
  }

  Future<(HabitsService, TimerService)> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsService = HabitsService(prefs);
    final timerService = TimerService(prefs);
    await habitsService.initialize();
    return (habitsService, timerService);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(HabitsService, TimerService)>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            backgroundColor: Color(0xFF17171A),
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return CupertinoPageScaffold(
            backgroundColor: const Color(0xFF17171A),
            child: Center(
              child: Text(
                'Error loading stats',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          );
        }

        final (habitsService, timerService) = snapshot.data!;
        final topStreaks = habitsService.getTopStreaks();
        final completionRate = (habitsService.todayCompletionRate * 100).toInt();
        final totalHabits = habitsService.totalHabits;
        final completedToday = habitsService.completedHabitsToday;
        final totalFocusTime = timerService.totalFocusTime;
        final averageSessionDuration = timerService.averageSessionDuration;

        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFF17171A),
          navigationBar: const CupertinoNavigationBar(
            middle: Text(
              'Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Color(0xFF17171A),
            border: null,
          ),
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Habits Section
                  Text(
                    'Habits',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completion Rate',
                          value: '$completionRate%',
                          progress: completionRate / 100,
                          icon: CupertinoIcons.chart_bar_fill,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completed Today',
                          value: '$completedToday/$totalHabits',
                          progress: totalHabits > 0 ? completedToday / totalHabits : 0,
                          icon: CupertinoIcons.checkmark_circle_fill,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                    ],
                  ),
                  if (topStreaks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildTopStreaks(topStreaks),
                  ],
                  
                  // Timer Section
                  const SizedBox(height: 32),
                  Text(
                    'Timer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Focus Time',
                          value: _formatDuration(totalFocusTime),
                          progress: math.min(1.0, totalFocusTime.inHours / 8), // 8 hours daily goal
                          icon: CupertinoIcons.timer,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Avg. Session',
                          value: _formatDuration(averageSessionDuration),
                          progress: math.min(1.0, averageSessionDuration.inMinutes / 60), // 1 hour session goal
                          icon: CupertinoIcons.time,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Sessions',
                          value: timerService.totalSessions.toString(),
                          progress: math.min(1.0, timerService.totalSessions / 100), // Goal of 100 sessions
                          icon: CupertinoIcons.number,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Longest Session',
                          value: _formatDuration(timerService.longestSession),
                          progress: math.min(1.0, timerService.longestSession.inMinutes / 120), // 2 hour max
                          icon: CupertinoIcons.chart_bar_alt_fill,
                          iconColor: const Color(0xFFE0C1A3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required double progress,
    required IconData icon,
    Color? iconColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Colors.white.withOpacity(0.6),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(60, 60),
                    painter: CircularProgressPainter(
                      progress: animValue,
                      color: const Color(0xFFE0C1A3),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStreaks(List<Habit> topStreaks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.flame_fill,
                color: Color(0xFFE0C1A3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Streaks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topStreaks.map((habit) {
            final glowIntensity = math.min(1.0, habit.streak / 30); // Max glow at 30 days
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: habit.streak > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE0C1A3).withOpacity(0.1),
                            blurRadius: 8 * glowIntensity,
                            spreadRadius: 2 * glowIntensity,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: habit.streak > 0
                            ? const Color(0xFFE0C1A3).withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.flame_fill,
                            color: habit.streak > 0
                                ? const Color(0xFFE0C1A3)
                                : Colors.white.withOpacity(0.3),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.streak} days',
                            style: TextStyle(
                              fontSize: 13,
                              color: habit.streak > 0
                                  ? const Color(0xFFE0C1A3)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 4.0;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
} 