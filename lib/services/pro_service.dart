import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum SubscriptionTier {
  free,
  monthly,
  annual,
  lifetime,
}

class ProService extends ChangeNotifier {
  static const String _subscriptionKey = 'subscription_tier';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  final SharedPreferences _prefs;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  DateTime? _expiryDate;

  ProService(this._prefs) {
    _loadSubscriptionStatus();
  }

  bool get isPro => _currentTier != SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;
  DateTime? get expiryDate => _expiryDate;

  // Feature access controls
  bool get canCreateUnlimitedHabits => isPro;
  bool get hasAdvancedTimerFeatures => isPro;
  bool get hasDetailedAnalytics => isPro;
  bool get hasCloudSync => isPro;
  bool get hasCustomThemes => isPro;
  
  // Free tier limits
  static const int maxFreeHabits = 3;
  static const int maxFreeTimerPresets = 1;

  Future<void> _loadSubscriptionStatus() async {
    final tierIndex = _prefs.getInt(_subscriptionKey) ?? 0;
    _currentTier = SubscriptionTier.values[tierIndex];
    
    final expiryStr = _prefs.getString(_subscriptionExpiryKey);
    if (expiryStr != null) {
      _expiryDate = DateTime.parse(expiryStr);
      
      // Check if subscription has expired
      if (_expiryDate!.isBefore(DateTime.now()) && _currentTier != SubscriptionTier.lifetime) {
        _currentTier = SubscriptionTier.free;
        _expiryDate = null;
        await _saveSubscriptionStatus();
      }
    }
    
    notifyListeners();
  }

  Future<void> _saveSubscriptionStatus() async {
    await _prefs.setInt(_subscriptionKey, _currentTier.index);
    if (_expiryDate != null) {
      await _prefs.setString(_subscriptionExpiryKey, _expiryDate!.toIso8601String());
    } else {
      await _prefs.remove(_subscriptionExpiryKey);
    }
  }

  // Subscription management methods
  Future<void> activateSubscription(SubscriptionTier tier, Duration duration) async {
    _currentTier = tier;
    if (tier != SubscriptionTier.lifetime) {
      _expiryDate = DateTime.now().add(duration);
    } else {
      _expiryDate = null;
    }
    await _saveSubscriptionStatus();
    notifyListeners();
  }

  Future<void> cancelSubscription() async {
    _currentTier = SubscriptionTier.free;
    _expiryDate = null;
    await _saveSubscriptionStatus();
    notifyListeners();
  }

  // Helper methods for feature access
  int getMaxHabits() => isPro ? 999 : maxFreeHabits;
  int getMaxTimerPresets() => isPro ? 999 : maxFreeTimerPresets;

  String getSubscriptionName() {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.monthly:
        return 'Pro Monthly';
      case SubscriptionTier.annual:
        return 'Pro Annual';
      case SubscriptionTier.lifetime:
        return 'Pro Lifetime';
    }
  }

  // Subscription validation
  bool canAccessFeature(String featureId) {
    switch (featureId) {
      case 'unlimited_habits':
      case 'advanced_timer':
      case 'detailed_analytics':
      case 'cloud_sync':
      case 'custom_themes':
        return isPro;
      default:
        return true; // Free features
    }
  }
} 