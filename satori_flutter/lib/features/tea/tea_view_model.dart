import 'package:flutter/material.dart';
import '../../core/models/member_tier.dart';

/// 品茗 ViewModel（赞助 / 会员）
class TeaViewModel extends ChangeNotifier {
  MemberTier currentTier = MemberTier.free;
  int points = 0;
  bool showPurchaseSheet = false;
  MemberTier? selectedTier;

  void selectTier(MemberTier tier) {
    selectedTier = tier;
    showPurchaseSheet = true;
    notifyListeners();
  }

  void purchase() {
    if (selectedTier == null) return;
    // TODO: StoreKit / Google Play 购买流程
    currentTier = selectedTier!;
    showPurchaseSheet = false;
    notifyListeners();
  }
}
