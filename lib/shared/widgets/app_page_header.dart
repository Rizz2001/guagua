import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive_breakpoints.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? context.width : context.width * 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: isCompact ? 12 : 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}
