import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';

class EditHabitDialog extends StatefulWidget {
  final Habit habit;
  final Function(Habit) onSave;

  const EditHabitDialog({
    super.key,
    required this.habit,
    required this.onSave,
  });

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController _nameController;
  late String _goal;
  bool hasError = false;
  String tempName = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _goal = widget.habit.goal;
    tempName = widget.habit.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Habit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  _buildMilestoneProgress(),
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
                          CupertinoIcons.star,
                          color: hasError 
                            ? Colors.red.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoTextField.borderless(
                            controller: _nameController,
                            placeholder: 'Enter habit name',
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
                                hasError = value.length > 30;
                              });
                            },
                          ),
                        ),
                        if (_nameController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _nameController.clear();
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
                  const SizedBox(height: 16),
                  _buildGoalSelector(),
                  const SizedBox(height: 16),
                  _buildMilestones(),
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
                        if (!hasError && tempName.isNotEmpty) {
                          final updatedHabit = Habit(
                            id: widget.habit.id,
                            name: tempName.trim(),
                            streak: widget.habit.streak,
                            completed: widget.habit.completed,
                            goal: _goal,
                            lastCompleted: widget.habit.lastCompleted,
                            milestones: widget.habit.milestones,
                            unlockedMilestones: widget.habit.unlockedMilestones,
                          );
                          widget.onSave(updatedHabit);
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: hasError || tempName.isEmpty
                            ? const Color(0xFFE0C1A3).withOpacity(0.5)
                            : const Color(0xFFE0C1A3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Color(0xFF17171A),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
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
  }

  Widget _buildGoalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: CupertinoSegmentedControl<String>(
            children: {
              'Daily': Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Daily',
                  style: TextStyle(
                    color: _goal == 'Daily'
                      ? const Color(0xFF17171A)
                      : Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              'Weekly': Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Weekly',
                  style: TextStyle(
                    color: _goal == 'Weekly'
                      ? const Color(0xFF17171A)
                      : Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            },
            onValueChanged: (value) {
              setState(() => _goal = value);
              HapticFeedback.selectionClick();
            },
            groupValue: _goal,
            padding: const EdgeInsets.all(4),
            borderColor: Colors.transparent,
            selectedColor: const Color(0xFFE0C1A3),
            pressedColor: const Color(0xFFE0C1A3).withOpacity(0.1),
            unselectedColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneProgress() {
    widget.habit.getDaysUntilNextMilestone();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0C1A3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0C1A3).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.flame_fill,
            color: Color(0xFFE0C1A3),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.habit.streak} day streak',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE0C1A3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Milestones',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: widget.habit.unlockedMilestones.map((milestone) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0C1A3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE0C1A3).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      milestone,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
              if (widget.habit.unlockedMilestones.isNotEmpty)
                const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.flag_fill,
                      color: Colors.white.withOpacity(0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next: ${widget.habit.getNextMilestone()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 