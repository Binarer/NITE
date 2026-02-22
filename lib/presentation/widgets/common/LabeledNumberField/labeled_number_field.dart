import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nite/core/theme/AppTheme/app_theme.dart';

/// Универсальное числовое поле ввода с лейблом.
///
/// Заменяет повторяющийся паттерн Column(Text(label), SizedBox, TextField(number))
/// в meal_plan_screen (_TargetField), food_form_screen (_macroField),
/// statistics_screen (поля роста/веса/возраста), settings_screen (_NutritionGoalsCard).
///
/// Пример использования:
/// ```dart
/// LabeledNumberField(
///   label: 'Белки',
///   controller: _proteinController,
///   suffix: 'г',
///   accentColor: Color(0xFF4CAF50),
///   decimal: true,
/// )
/// ```
class LabeledNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final Color? accentColor;
  final bool decimal;
  final double? min;
  final double? max;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  /// Ширина поля. null = занимает всё доступное пространство.
  final double? width;

  const LabeledNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.accentColor,
    this.decimal = false,
    this.min,
    this.max,
    this.onChanged,
    this.validator,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.textSecondary;

    Widget field = TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        decimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        color: accentColor != null ? color : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: (v) {
        if (onChanged != null) onChanged!(v);
        // Клamp при потере фокуса не делаем здесь — пусть вызывающий контроллер сам решает.
      },
    );

    if (width != null) {
      field = SizedBox(width: width, child: field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentColor != null ? color : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
