import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/pro_service.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> with TickerProviderStateMixin {
  bool _isYearly = true;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Advanced Statistics & Analytics',
      'description': 'See deeper insights into focus trends',
      'icon': CupertinoIcons.graph_circle_fill,
    },
    {
      'title': 'More Customization Options',
      'description': 'Personalize timers, streak settings, and more',
      'icon': CupertinoIcons.slider_horizontal_3,
    },
    {
      'title': 'Unlimited Habit Tracking',
      'description': 'No limit on saved habits & streaks',
      'icon': CupertinoIcons.infinite,
    },
    {
      'title': 'Streak Recovery Perks',
      'description': 'Restore 2 streaks per month',
      'icon': CupertinoIcons.arrow_counterclockwise_circle_fill,
    },
    {
      'title': 'Early Access to Beta Features',
      'description': 'Be the first to try new features',
      'icon': CupertinoIcons.star_circle_fill,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, ThemeService themeService, bool isVisible) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeService.currentTheme.textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.currentTheme.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeService.currentTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: themeService.currentTheme.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.currentTheme.textColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.currentTheme.textColor.withOpacity(0.6),
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

  Widget _buildPricingSection(ThemeService themeService, bool isPro) {
    if (isPro) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: themeService.currentTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeService.currentTheme.accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.star_circle_fill,
              color: themeService.currentTheme.accentColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Thank You for Being a Pro Member!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeService.currentTheme.textColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have access to all premium features',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: themeService.currentTheme.textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                // TODO: Implement subscription management
                HapticFeedback.mediumImpact();
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: themeService.currentTheme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.gear,
                      color: themeService.currentTheme.navBarColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manage Subscription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeService.currentTheme.navBarColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: themeService.currentTheme.textColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isYearly = false);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: !_isYearly
                          ? themeService.currentTheme.accentColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: !_isYearly
                            ? themeService.currentTheme.navBarColor
                            : themeService.currentTheme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isYearly = true);
                    HapticFeedback.selectionClick();
                  },
                  child: Stack(
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isYearly
                              ? themeService.currentTheme.accentColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Yearly',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _isYearly
                                ? themeService.currentTheme.navBarColor
                                : themeService.currentTheme.textColor,
                          ),
                        ),
                      ),
                      if (_isYearly)
                        Positioned(
                          right: 8,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: themeService.currentTheme.navBarColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save 15%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: themeService.currentTheme.accentColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeService.currentTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeService.currentTheme.accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _isYearly ? '\$50' : '\$4.99',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: themeService.currentTheme.textColor,
                ),
              ),
              Text(
                _isYearly ? 'per year' : 'per month',
                style: TextStyle(
                  fontSize: 15,
                  color: themeService.currentTheme.textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // TODO: Implement subscription purchase
                  HapticFeedback.mediumImpact();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: themeService.currentTheme.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.star_fill,
                        color: themeService.currentTheme.navBarColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upgrade to Luro Pro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeService.currentTheme.navBarColor,
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
    final themeService = Provider.of<ThemeService>(context);
    final proService = Provider.of<ProService>(context);
    final isPro = proService.isPro;
    final theme = themeService.currentTheme;

    return AnimatedBuilder(
      animation: _pageAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - _pageAnimation.value), 0),
          child: Opacity(
            opacity: _pageAnimation.value,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: BoxDecoration(
                  gradient: theme.backgroundGradient,
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Background gradient overlay for depth
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.primaryColor.withOpacity(0.0),
                                theme.primaryColor.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Main content
                      CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: theme.textColor.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.textColor.withOpacity(0.1),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        CupertinoIcons.back,
                                        color: theme.textColor.withOpacity(0.8),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Luro Pro',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor.withOpacity(0.9),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isPro)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.accentColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.accentColor.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.star_fill,
                                            color: theme.accentColor,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'PRO',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < _features.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: _buildFeatureCard(
                                      _features[index],
                                      themeService,
                                      true,
                                    ),
                                  );
                                }
                                return null;
                              },
                              childCount: _features.length,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                _buildPricingSection(themeService, isPro),
                                const SizedBox(height: 32),
                              ],
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
      },
    );
  }
} 