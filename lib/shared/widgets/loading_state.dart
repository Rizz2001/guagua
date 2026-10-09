import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryCharcoal,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
