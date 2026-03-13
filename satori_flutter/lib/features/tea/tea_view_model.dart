import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

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

enum MemberTier {
  free('清茶', '免费', [
    '基础焚香计时',
    '3种白噪音',
    '2首琴曲'
  ]),
  silver('银针', '¥12/月', [
    '全部白噪音',
    '6首琴曲',
    '沉香·香料皮肤'
  ]),
  gold('龙井', '¥28/月', [
    '全部琴曲',
    '名贵香料皮肤',
    '统计报表'
  ]),
  premium('大红袍', '¥68/月', [
    '全部功能',
    '稀有琴曲抢先听',
    '专属香炉外观'
  ]);

  const MemberTier(this.label, this.price, this.benefits);
  final String label;
  final String price;
  final List<String> benefits;

  Color get color {
    switch (this) {
      case MemberTier.free:
        return Colors.grey;
      case MemberTier.silver:
        return const Color(0xFFA8B5C0);
      case MemberTier.gold:
        return SatoriColors.stringGold;
      case MemberTier.premium:
        return SatoriColors.incenseEmber;
    }
  }
}
