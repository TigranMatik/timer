import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/timer_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/settings_screen.dart';
import 'services/pro_service.dart';
import 'services/theme_service.dart';
import 'widgets/theme_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final proService = ProService(prefs);
  final themeService = ThemeService(prefs, proService);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock orientation to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: proService),
          ChangeNotifierProvider.value(value: themeService),
        ],
        child: const MainApp(),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = themeService.currentTheme;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flow',
      theme: theme.themeData.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: theme.primaryColor,
          secondary: theme.accentColor,
          surface: theme.cardColor,
          background: theme.primaryColor,
          onBackground: theme.textColor,
          onSurface: theme.textColor,
        ),
        iconTheme: theme.iconTheme,
        textTheme: theme.themeData.textTheme.apply(
          bodyColor: theme.textColor,
          displayColor: theme.textColor,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Initialize screens with navigation callbacks
    _screens.addAll([
      const HabitsScreen(),
      StatsScreen(
        onTimerTap: () {
          setState(() {
            _currentIndex = 2; // Timer tab index
          });
        },
      ),
      const TimerScreen(),
      const SettingsScreen(),
    ]);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _fadeController.forward(from: 0.7);
    });
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ThemePicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = themeService.currentTheme;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.backgroundGradient,
        ),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _screens[_currentIndex],
            ),
            if (_currentIndex == 0) // Only show theme button on Habits screen
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _showThemePicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.textColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.textColor.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.paintbrush,
                        color: theme.textColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.navBarColor.withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: theme.textColor.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
              backgroundColor: Colors.transparent,
              activeColor: theme.accentColor,
              inactiveColor: theme.textColor.withOpacity(0.4),
              iconSize: 24,
              border: null,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.star_outline),
                  activeIcon: Icon(Icons.star),
                  label: 'Habits',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer),
                  label: 'Timer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
