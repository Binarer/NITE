import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/food_item_model.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback? onTap;
  final bool selectable;
  final bool isSelected;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.selectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF9800) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: item.photoPath != null
                    ? Image.file(
                        File(item.photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
            ),
            // Контент
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name.isEmpty ? 'Без названия' : item.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectable && isSelected)
                        const Icon(Icons.check_circle,
                            size: 16, color: Color(0xFFFF9800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Калории
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(
                        '${item.calories.toStringAsFixed(0)} ккал / 100г',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // БЖУ
                  Row(
                    children: [
                      _MacroChip('Б', item.macros.proteins, const Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      _MacroChip('Ж', item.macros.fats, const Color(0xFFFF9800)),
                      const SizedBox(width: 4),
                      _MacroChip('У', item.macros.carbs, const Color(0xFF2196F3)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}г',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
