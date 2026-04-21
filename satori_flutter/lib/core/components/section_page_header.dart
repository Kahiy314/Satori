import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SectionPageHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const SectionPageHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(
      SatoriTheme.spacingL,
      SatoriTheme.spacingM,
      SatoriTheme.spacingL,
      0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : SatoriColors.inkSmoke.withValues(alpha: 0.72);

    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: SatoriTypography.subtitle.copyWith(
            color: textColor,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}