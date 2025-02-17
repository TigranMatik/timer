import 'package:flutter/foundation.dart';
import '../config/subscription_config.dart';
import 'pro_service.dart';

enum PurchaseResult {
  success,
  failed,
  canceled,
  pending,
}

class SubscriptionManager {
  final ProService _proService;
  
  SubscriptionManager(this._proService);

  // Purchase handling
  Future<PurchaseResult> purchaseSubscription(SubscriptionPlan plan) async {
    try {
      // TODO: Implement actual purchase logic with RevenueCat or in-app purchases
      
      // For development/testing, we'll simulate a successful purchase
      if (kDebugMode) {
        switch (plan.period) {
          case 'month':
            await _proService.activateSubscription(
              SubscriptionTier.monthly,
              const Duration(days: 30),
            );
            break;
          case 'year':
            await _proService.activateSubscription(
              SubscriptionTier.annual,
              const Duration(days: 365),
            );
            break;
          case 'lifetime':
            await _proService.activateSubscription(
              SubscriptionTier.lifetime,
              const Duration(days: 36500), // 100 years
            );
            break;
        }
        return PurchaseResult.success;
      }
      
      return PurchaseResult.pending;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return PurchaseResult.failed;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      // TODO: Implement actual restore logic with RevenueCat or in-app purchases
      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      // TODO: Implement actual cancellation logic
      await _proService.cancelSubscription();
      return true;
    } catch (e) {
      debugPrint('Cancellation failed: $e');
      return false;
    }
  }

  // Get current subscription details
  Map<String, dynamic> getCurrentSubscriptionDetails() {
    final tier = _proService.currentTier;
    final expiryDate = _proService.expiryDate;
    
    return {
      'tier': tier,
      'isActive': _proService.isPro,
      'expiryDate': expiryDate,
      'planName': _proService.getSubscriptionName(),
    };
  }

  // Check if a feature is accessible
  bool canAccessFeature(String featureId) {
    return _proService.canAccessFeature(featureId);
  }

  // Get remaining free tier usage
  Map<String, int> getFreeUsageLimits() {
    return {
      'remainingHabits': _proService.getMaxHabits(),
      'remainingPresets': _proService.getMaxTimerPresets(),
    };
  }
} 