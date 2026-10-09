import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/product_model.dart';

class PosProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const PosProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: product.isCombo ? AppColors.comboPurpleText.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: product.isCombo ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badges / Tags superiores
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (product.isCombo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.comboPurpleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🎁 COMBO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.comboPurpleText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (product.unitsPerBox > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📦 x${product.unitsPerBox}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: AppColors.primaryCharcoal,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '\$${product.priceRetailUsd.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Imagen del producto a la derecha
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              bottom: 36,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl!,
                  width: 65,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                ),
              ),
            )
          else
            Positioned(
              right: 0,
              top: 0,
              bottom: 36,
              child: _buildPlaceholderImage(),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 65,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.local_cafe_outlined, color: AppColors.textMuted, size: 24),
    );
  }
}
