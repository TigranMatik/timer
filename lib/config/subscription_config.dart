class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
  });
}

class SubscriptionConfig {
  static const monthlyPlan = SubscriptionPlan(
    id: 'pro_monthly',
    name: 'Pro Monthly',
    description: 'Full access to all Flow features',
    price: 4.99,
    period: 'month',
    features: [
      'Unlimited habits',
      'Advanced timer features',
      'Detailed analytics',
      'Cloud sync & backup',
      'Custom themes',
      'Priority support',
    ],
  );

  static const annualPlan = SubscriptionPlan(
    id: 'pro_annual',
    name: 'Pro Annual',
    description: 'Save 33% with annual billing',
    price: 39.99,
    period: 'year',
    features: [
      'Unlimited habits',
      'Advanced timer features',
      'Detailed analytics',
      'Cloud sync & backup',
      'Custom themes',
      'Priority support',
    ],
  );

  static const lifetimePlan = SubscriptionPlan(
    id: 'pro_lifetime',
    name: 'Pro Lifetime',
    description: 'One-time purchase for lifetime access',
    price: 79.99,
    period: 'lifetime',
    features: [
      'Unlimited habits',
      'Advanced timer features',
      'Detailed analytics',
      'Cloud sync & backup',
      'Custom themes',
      'Priority support',
      'Lifetime updates',
    ],
  );

  static const List<SubscriptionPlan> allPlans = [
    monthlyPlan,
    annualPlan,
    lifetimePlan,
  ];

  // Feature descriptions
  static const Map<String, String> featureDescriptions = {
    'Unlimited habits': 'Create and track unlimited daily habits',
    'Advanced timer features': 'Custom presets, ambient sounds, and more',
    'Detailed analytics': 'In-depth insights and progress tracking',
    'Cloud sync & backup': 'Sync your data across all devices',
    'Custom themes': 'Personalize your Flow experience',
    'Priority support': 'Get help when you need it',
    'Lifetime updates': 'Access to all future updates',
  };

  // Free tier limitations
  static const int maxFreeHabits = 3;
  static const int maxFreeTimerPresets = 1;

  // Pro features
  static const List<String> proFeatures = [
    'unlimited_habits',
    'advanced_timer',
    'detailed_analytics',
    'cloud_sync',
    'custom_themes',
  ];
} 