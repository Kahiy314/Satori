import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/member_tier.dart';

class EntitlementController extends ChangeNotifier {
  static const _developerModeKey = 'developer_mode_enabled';
  static const _memberTierKey = 'member_tier';
  static const _developerModePassword = '123456';

  EntitlementController({
    MemberTier initialPurchasedTier = MemberTier.free,
    bool initialDeveloperMode = false,
    bool loadFromStorage = true,
  })  : _purchasedTier = initialPurchasedTier,
        _developerModeEnabled = initialDeveloperMode {
    if (loadFromStorage) {
      _ready = _load();
    } else {
      _isReady = true;
      _ready = Future.value();
    }
  }

  late final Future<void> _ready;
  MemberTier _purchasedTier;
  bool _developerModeEnabled;
  bool _isReady = false;

  Future<void> get ready => _ready;
  bool get isReady => _isReady;
  MemberTier get purchasedTier => _purchasedTier;
  bool get isDeveloperModeEnabled => _developerModeEnabled;
  MemberTier get effectiveTier =>
      _developerModeEnabled ? MemberTier.premium : _purchasedTier;

  bool hasAccess(MemberTier requiredTier) =>
      effectiveTier.includes(requiredTier);

  Future<bool> unlockDeveloperMode(String password) async {
    if (password.trim() != _developerModePassword) {
      return false;
    }

    if (_developerModeEnabled) {
      return true;
    }

    _developerModeEnabled = true;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> setDeveloperModeEnabled(bool enabled) async {
    if (_developerModeEnabled == enabled) {
      return;
    }

    _developerModeEnabled = enabled;
    await _persist();
    notifyListeners();
  }

  Future<void> setPurchasedTier(MemberTier tier) async {
    if (_purchasedTier == tier) {
      return;
    }

    _purchasedTier = tier;
    await _persist();
    notifyListeners();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    _developerModeEnabled =
        preferences.getBool(_developerModeKey) ?? _developerModeEnabled;

    final storedTierName = preferences.getString(_memberTierKey);
    if (storedTierName != null) {
      _purchasedTier = MemberTier.values.firstWhere(
        (tier) => tier.name == storedTierName,
        orElse: () => _purchasedTier,
      );
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_developerModeKey, _developerModeEnabled);
    await preferences.setString(_memberTierKey, _purchasedTier.name);
  }
}
