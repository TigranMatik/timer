import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer/services/pro_service.dart';
import '../models/habit.dart';
import '../services/habits_service.dart';
import '../widgets/edit_habit_dialog.dart';
import '../widgets/milestone_celebration.dart';
import '../widgets/create_habit_dialog.dart';
import '../widgets/upgrade_prompt_dialog.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with TickerProviderStateMixin {
  late AnimationController _addButtonController;
  late Animation<double> _addButtonAnimation;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late Future<HabitsService> _habitServiceFuture;

  @override
  void initState() {
    super.initState();
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addButtonAnimation = CurvedAnimation(
      parent: _addButtonController,
      curve: Curves.easeOutCubic,
    );
    _habitServiceFuture = _initializeServices();
  }

  Future<HabitsService> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final proService = ProService(prefs);
    final service = HabitsService(prefs, proService);
    await service.initialize();
    return service;
  }

  @override
  void dispose() {
    _addButtonController.dispose();
    super.dispose();
  }

  void _showAddHabitSheet() async {
    final service = await _habitServiceFuture;
    
    if (!service.canAddMoreHabits) {
      // Show upgrade prompt
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => UpgradePromptDialog(
          title: 'Unlock Unlimited Habits',
          message: "You've reached the free limit of ${service.maxHabits} habits. Upgrade to Flow Pro to create unlimited habits and unlock more features!",
          onUpgrade: () {
            Navigator.pop(context);
            // TODO: Navigate to subscription screen
          },
        ),
      );
      return;
    }

    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateHabitDialog(
        onSave: (habit) async {
          final success = await service.addHabit(habit);
          if (success) {
            setState(() {});
            HapticFeedback.mediumImpact();
          }
        },
      ),
    );
  }

  void _showEditHabitDialog(Habit habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EditHabitDialog(
        habit: habit,
        onSave: (updatedHabit) async {
          final service = await _habitServiceFuture;
          await service.updateHabit(habit.id, updatedHabit);
          setState(() {});
        },
      ),
    );
  }

  void _showMilestoneCelebration(Habit habit, String milestone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: MilestoneCelebration(
          habit: habit,
          milestone: milestone,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showStreakRecoveryDialog(Habit habit) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Streak?'),
        content: Text(
          'You missed a day for "${habit.name}". Would you like to restore your streak?\n\n(1 use per month)',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDefaultAction: true,
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ).then((shouldRecover) async {
      if (shouldRecover == true) {
        final service = await _habitServiceFuture;
        habit.recoverStreak();
        await service.updateHabit(habit.id, habit);
        setState(() {});
        HapticFeedback.mediumImpact();
      }
    });
  }

  Widget _buildHabitCard(Habit habit) {
    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          final service = await _habitServiceFuture;
          await service.deleteHabit(habit.id);
          setState(() {});
          HapticFeedback.mediumImpact();
        },
        confirmDismiss: (direction) async {
          bool? result = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Delete Habit'),
              content: Text(
                'Are you sure you want to delete "${habit.name}"?',
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
          margin: const EdgeInsets.only(bottom: 16),
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
            size: 20,
          ),
        ),
        child: GestureDetector(
          onTap: () => _showEditHabitDialog(habit),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0C1A3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.flame_fill,
                                  size: 12,
                                  color: Color(0xFFE0C1A3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${habit.streak} day streak',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFE0C1A3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              habit.goal,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          if (habit.unlockedMilestones.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0C1A3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                habit.unlockedMilestones.last,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (habit.streak > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habit.streak / 30, // Progress towards 30-day milestone
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: const Color(0xFFE0C1A3).withOpacity(0.3),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    final service = await _habitServiceFuture;
                    
                    // Check if streak should be reset and show recovery dialog
                    if (!habit.completed && habit.streak > 0 && !habit.isCompletedToday) {
                      final now = DateTime.now();
                      if (habit.lastCompleted != null) {
                        final daysSinceLastCompleted = now.difference(habit.lastCompleted!).inDays;
                        if (daysSinceLastCompleted > 1 && habit.canRecoverStreak()) {
                          _showStreakRecoveryDialog(habit);
                          return;
                        }
                      }
                    }
                    
                    habit.toggleCompletion();
                    await service.updateHabit(habit.id, habit);
                    setState(() {});
                    
                    // Check if new milestone was unlocked
                    if (habit.unlockedMilestones.isNotEmpty) {
                      final previousMilestones = List<String>.from(habit.unlockedMilestones);
                      if (habit.unlockedMilestones.length > previousMilestones.length) {
                        final newMilestone = habit.unlockedMilestones.last;
                        _showMilestoneCelebration(habit, newMilestone);
                      }
                    }
                    
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.completed
                          ? const Color(0xFFE0C1A3)
                          : Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: habit.completed
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        habit.completed
                            ? CupertinoIcons.checkmark_alt
                            : CupertinoIcons.circle,
                        color: habit.completed
                            ? const Color(0xFF17171A)
                            : Colors.white.withOpacity(0.8),
                        size: 24,
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

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Habits',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your progress',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<HabitsService>(
                    future: _habitServiceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading habits',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        );
                      }

                      final habitsService = snapshot.data!;
                      final habits = habitsService.habits;

                      return habits.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.star,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Habits Yet',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first habit to start tracking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: habits.length,
                              itemBuilder: (context, index) {
                                return _buildHabitCard(habits[index]);
                              },
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              addSemanticIndexes: false,
                            );
                    },
                  ),
                  Positioned(
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    child: GestureDetector(
                      onTap: _showAddHabitSheet,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0C1A3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE0C1A3).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.plus,
                          color: Color(0xFF17171A),
                          size: 24,
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
    );
  }
} 