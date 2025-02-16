import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';

class CreateHabitDialog extends StatefulWidget {
  final Function(Habit) onSave;

  const CreateHabitDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<CreateHabitDialog> createState() => _CreateHabitDialogState();
}

class _CreateHabitDialogState extends State<CreateHabitDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  FrequencyType _frequencyType = FrequencyType.daily;
  int _frequencyCount = 1;
  final List<TimeOfDay> _reminderTimes = [];
  final List<bool> _activeDays = List.generate(7, (index) => true);
  bool hasError = false;
  String tempName = '';
  late AnimationController _frequencyController;
  late Animation<double> _frequencyAnimation;

  @override
  void initState() {
    super.initState();
    _frequencyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _frequencyAnimation = CurvedAnimation(
      parent: _frequencyController,
      curve: Curves.easeOutCubic,
    );
    _frequencyController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  void _addReminder() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: const Color(0xFF1E1E23),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Add'),
                    onPressed: () {
                      final now = TimeOfDay.now();
                      setState(() {
                        _reminderTimes.add(now);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      _reminderTimes.last = TimeOfDay.fromDateTime(newTime);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
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
          child: Column(
            children: [
              CupertinoSegmentedControl<FrequencyType>(
                children: {
                  FrequencyType.daily: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Daily',
                      style: TextStyle(
                        color: _frequencyType == FrequencyType.daily
                          ? const Color(0xFF17171A)
                          : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  FrequencyType.weekly: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        color: _frequencyType == FrequencyType.weekly
                          ? const Color(0xFF17171A)
                          : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  FrequencyType.hourly: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Hourly',
                      style: TextStyle(
                        color: _frequencyType == FrequencyType.hourly
                          ? const Color(0xFF17171A)
                          : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  setState(() => _frequencyType = value);
                  _frequencyController.reset();
                  _frequencyController.forward();
                  HapticFeedback.selectionClick();
                },
                groupValue: _frequencyType,
                padding: const EdgeInsets.all(4),
                borderColor: Colors.transparent,
                selectedColor: const Color(0xFFE0C1A3),
                pressedColor: const Color(0xFFE0C1A3).withOpacity(0.1),
                unselectedColor: Colors.transparent,
              ),
              const SizedBox(height: 16),
              if (_frequencyType == FrequencyType.weekly)
                SizeTransition(
                  sizeFactor: _frequencyAnimation,
                  child: FadeTransition(
                    opacity: _frequencyAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Days',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (int i = 0; i < 7; i++)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _activeDays[i] = !_activeDays[i];
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _activeDays[i]
                                        ? const Color(0xFFE0C1A3)
                                        : Colors.white.withOpacity(0.1),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                      style: TextStyle(
                                        color: _activeDays[i]
                                          ? const Color(0xFF17171A)
                                          : Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repeat',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_frequencyCount > 1) {
                              setState(() => _frequencyCount--);
                              HapticFeedback.selectionClick();
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Icon(
                              CupertinoIcons.minus,
                              color: _frequencyCount > 1
                                ? Colors.white.withOpacity(0.8)
                                : Colors.white.withOpacity(0.3),
                              size: 18,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_frequencyCount',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _frequencyCount++);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _frequencyType == FrequencyType.daily
                            ? 'time${_frequencyCount > 1 ? 's' : ''} a day'
                            : _frequencyType == FrequencyType.weekly
                              ? 'time${_frequencyCount > 1 ? 's' : ''} a week'
                              : 'hour${_frequencyCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders',
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
            children: [
              for (int i = 0; i < _reminderTimes.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.bell_fill,
                        color: Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatTime(_reminderTimes[i]),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _reminderTimes.removeAt(i);
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _addReminder,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled,
                        color: const Color(0xFFE0C1A3).withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFFE0C1A3).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                children: [
                  Text(
                    'New Habit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 24),
                    _buildFrequencySelector(),
                    const SizedBox(height: 24),
                    _buildReminderSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
                          final habit = Habit(
                            id: DateTime.now().toString(),
                            name: tempName.trim(),
                            frequencyType: _frequencyType,
                            frequencyCount: _frequencyCount,
                            reminderTimes: _reminderTimes,
                            activeDays: _activeDays,
                          );
                          widget.onSave(habit);
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
                              CupertinoIcons.star,
                              color: Color(0xFF17171A),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create Habit',
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
} 