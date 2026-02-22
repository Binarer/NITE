import 'package:flutter/material.dart';

import 'package:nite/core/theme/AppTheme/app_theme.dart';

class PrioritySliderWidget extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const PrioritySliderWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> _labels = [
    'Нет', 'Очень низкий', 'Низкий', 'Средний', 'Высокий', 'Максимальный'
  ];

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Цветной индикатор
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_labels[value]} ($value)',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.border,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        // Метки 0–5
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => Text(
              '$i',
              style: TextStyle(
                color: i == value ? color : AppColors.textHint,
                fontSize: 11,
                fontWeight: i == value ? FontWeight.bold : FontWeight.normal,
              ),
            )),
          ),
        ),
      ],
    );
  }
}
