import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/pro_service.dart';
import '../services/theme_service.dart';
import '../screens/pro_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPro = false; // TODO: Implement subscription check
  bool _isDarkMode = true;
  bool _enableNotifications = true;
  bool _enableSounds = true;
  bool _enableHaptics = true;
  int _defaultTimerDuration = 25; // in minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPro = prefs.getBool('is_pro') ?? false;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _enableSounds = prefs.getBool('enable_sounds') ?? true;
      _enableHaptics = prefs.getBool('enable_haptics') ?? true;
      _defaultTimerDuration = prefs.getInt('default_timer_duration') ?? 25;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('enable_notifications', _enableNotifications);
    await prefs.setBool('enable_sounds', _enableSounds);
    await prefs.setBool('enable_haptics', _enableHaptics);
    await prefs.setInt('default_timer_duration', _defaultTimerDuration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    
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
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize your experience',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSubscriptionSection(),
                  _buildSectionHeader('Appearance'),
                  _buildSettingItem(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme throughout the app',
                    trailing: CupertinoSwitch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        _saveSettings();
                        HapticFeedback.selectionClick();
                      },
                      activeColor: theme.accentColor,
                    ),
                    isFirst: true,
                    isLast: true,
                  ),
                  _buildSectionHeader('Timer'),
                  _buildSettingItem(
                    title: 'Default Duration',
                    subtitle: '$_defaultTimerDuration minutes',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_defaultTimerDuration > 5) {
                              setState(() => _defaultTimerDuration -= 5);
                              _saveSettings();
                              HapticFeedback.selectionClick();
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Icon(
                              CupertinoIcons.minus,
                              color: _defaultTimerDuration > 5
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.3),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() => _defaultTimerDuration += 5);
                            _saveSettings();
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isFirst: true,
                  ),
                  _buildSettingItem(
                    title: 'Sound Effects',
                    trailing: CupertinoSwitch(
                      value: _enableSounds,
                      onChanged: (value) {
                        setState(() => _enableSounds = value);
                        _saveSettings();
                        HapticFeedback.selectionClick();
                      },
                      activeColor: theme.accentColor,
                    ),
                  ),
                  _buildSettingItem(
                    title: 'Haptic Feedback',
                    trailing: CupertinoSwitch(
                      value: _enableHaptics,
                      onChanged: (value) {
                        setState(() => _enableHaptics = value);
                        _saveSettings();
                        if (_enableHaptics) {
                          HapticFeedback.selectionClick();
                        }
                      },
                      activeColor: theme.accentColor,
                    ),
                    isLast: true,
                  ),
                  _buildSectionHeader('Notifications'),
                  _buildSettingItem(
                    title: 'Enable Notifications',
                    subtitle: 'Get reminders for habits and timers',
                    trailing: CupertinoSwitch(
                      value: _enableNotifications,
                      onChanged: (value) {
                        setState(() => _enableNotifications = value);
                        _saveSettings();
                        HapticFeedback.selectionClick();
                      },
                      activeColor: theme.accentColor,
                    ),
                    isFirst: true,
                    isLast: true,
                  ),
                  _buildSectionHeader('Support'),
                  _buildSettingItem(
                    title: 'Help Center',
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                    onTap: () {
                      // TODO: Implement help center
                      HapticFeedback.selectionClick();
                    },
                    isFirst: true,
                  ),
                  _buildSettingItem(
                    title: 'Privacy Policy',
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                    onTap: () {
                      // TODO: Implement privacy policy
                      HapticFeedback.selectionClick();
                    },
                  ),
                  _buildSettingItem(
                    title: 'Terms of Service',
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                    onTap: () {
                      // TODO: Implement terms of service
                      HapticFeedback.selectionClick();
                    },
                    isLast: true,
                  ),
                  if (kDebugMode) ...[
                    _buildSectionHeader('Debug'),
                    _buildSettingItem(
                      title: 'Pro Features',
                      subtitle: 'Toggle Pro features for testing',
                      trailing: CupertinoSwitch(
                        value: _isPro,
                        onChanged: (value) async {
                          final prefs = await SharedPreferences.getInstance();
                          setState(() => _isPro = value);
                          await prefs.setBool('is_pro', value);
                          
                          // Update ProService subscription status
                          if (value) {
                            final proService = Provider.of<ProService>(context, listen: false);
                            await proService.activateSubscription(
                              SubscriptionTier.lifetime,
                              const Duration(days: 36500), // 100 years
                            );
                          } else {
                            final proService = Provider.of<ProService>(context, listen: false);
                            await proService.cancelSubscription();
                          }
                          
                          HapticFeedback.selectionClick();
                        },
                        activeColor: theme.accentColor,
                      ),
                      isFirst: true,
                    ),
                    _buildSettingItem(
                      title: 'Clear All Data',
                      subtitle: 'Reset all app data (cannot be undone)',
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final shouldClear = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Clear All Data?'),
                              content: const Text(
                                'This will reset all app data including habits, timer sessions, and settings. This action cannot be undone.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (shouldClear == true) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            
                            // Reset services
                            final proService = Provider.of<ProService>(context, listen: false);
                            await proService.cancelSubscription();
                            
                            // Reset UI state
                            setState(() {
                              _isPro = false;
                              _isDarkMode = true;
                              _enableNotifications = true;
                              _enableSounds = true;
                              _enableHaptics = true;
                              _defaultTimerDuration = 25;
                            });
                            
                            // Show confirmation
                            if (mounted) {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Data Cleared'),
                                  content: const Text(
                                    'All app data has been reset. Please restart the app for changes to take effect.',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        child: const Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.destructiveRed,
                          size: 24,
                        ),
                      ),
                      isLast: true,
                    ),
                  ],
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.navBarColor.withOpacity(0.05),
          border: Border(
            top: isFirst ? BorderSide(color: theme.textColor.withOpacity(0.1)) : BorderSide.none,
            bottom: BorderSide(color: theme.textColor.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textColor.withOpacity(0.9),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    if (_isPro) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ProScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.accentColor.withOpacity(0.2),
                theme.accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                color: theme.accentColor,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                'Luro Pro',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thanks for supporting Luro!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Manage Subscription',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.navBarColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.accentColor.withOpacity(0.2),
              theme.accentColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.star_fill,
              color: theme.accentColor,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get access to advanced features and support development.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'View Plans',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.navBarColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 