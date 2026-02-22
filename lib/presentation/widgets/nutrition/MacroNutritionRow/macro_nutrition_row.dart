import 'package:flutter/material.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';

/// Цвета макронутриентов — единый источник для всего приложения.
class MacroColors {
  static const Color proteins = Color(0xFF4CAF50);
  static const Color fats = Color(0xFFFF9800);
  static const Color carbs = Color(0xFF2196F3);
  static const Color calories = Color(0xFFFFB300);
}

/// Стиль отображения КБЖУ.
enum MacroNutritionStyle {
  /// Компактная горизонтальная строка: «Б 12г · Ж 5г · У 30г»
  compact,

  /// Карточка с заголовком калорий и разделителем
  card,

  /// Чипы — каждый макрос в отдельном контейнере (как в task_form_screen)
  chips,
}

/// Универсальный виджет отображения КБЖУ.
///
/// Заменяет дублирующиеся реализации в:
/// - `food_detail_screen.dart` (_NutritionCard + _MacroItem)
/// - `task_form_screen.dart` (_MacroChip в _FoodItemTile)
/// - `task_detail_screen.dart` (инлайн-строка КБЖУ)
/// - `meal_plan_screen.dart` (_MealBlock макро-строка)
/// - `statistics_screen.dart` (_MacroCell)
///
/// Пример использования:
/// ```dart
/// MacroNutritionRow(
///   calories: 350,
///   proteins: 25,
///   fats: 10,
///   carbs: 40,
///   style: MacroNutritionStyle.card,
///   perLabel: 'на 100г',
/// )
/// ```
class MacroNutritionRow extends StatelessWidget {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final MacroNutritionStyle style;

  /// Подпись под калориями, например «на 100г» или «за день»
  final String? perLabel;

  /// Показывать ли блок калорий (для компактного и chips стилей)
  final bool showCalories;

  const MacroNutritionRow({
    super.key,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    this.style = MacroNutritionStyle.compact,
    this.perLabel,
    this.showCalories = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case MacroNutritionStyle.compact:
        return _buildCompact();
      case MacroNutritionStyle.card:
        return _buildCard();
      case MacroNutritionStyle.chips:
        return _buildChips();
    }
  }

  // ── Compact ──────────────────────────────────────────────────────────────

  Widget _buildCompact() {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        if (showCalories)
          _CompactItem(
            label: 'ккал',
            value: calories,
            color: MacroColors.calories,
            decimals: 0,
          ),
        _CompactItem(label: 'Б', value: proteins, color: MacroColors.proteins),
        _CompactItem(label: 'Ж', value: fats, color: MacroColors.fats),
        _CompactItem(label: 'У', value: carbs, color: MacroColors.carbs),
      ],
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Калории
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perLabel != null ? 'Калорийность $perLabel' : 'Калорийность',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${calories.toStringAsFixed(0)} ккал',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          // БЖУ
          if (perLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'БЖУ $perLabel',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CardMacroItem('Белки', proteins, MacroColors.proteins),
              _CardMacroItem('Жиры', fats, MacroColors.fats),
              _CardMacroItem('Углеводы', carbs, MacroColors.carbs),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chips ─────────────────────────────────────────────────────────────────

  Widget _buildChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (showCalories)
          _MacroChip(
            label: '${calories.toStringAsFixed(0)} ккал',
            color: MacroColors.calories,
          ),
        _MacroChip(
          label: 'Б ${proteins.toStringAsFixed(1)}г',
          color: MacroColors.proteins,
        ),
        _MacroChip(
          label: 'Ж ${fats.toStringAsFixed(1)}г',
          color: MacroColors.fats,
        ),
        _MacroChip(
          label: 'У ${carbs.toStringAsFixed(1)}г',
          color: MacroColors.carbs,
        ),
      ],
    );
  }
}

// ── Вспомогательные приватные виджеты ────────────────────────────────────────

class _CompactItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final int decimals;

  const _CompactItem({
    required this.label,
    required this.value,
    required this.color,
    this.decimals = 1,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value.toStringAsFixed(decimals),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMacroItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CardMacroItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}г',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
