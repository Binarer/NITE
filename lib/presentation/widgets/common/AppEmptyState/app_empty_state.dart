import 'package:flutter/material.dart';

import 'package:nite/core/theme/AppTheme/app_theme.dart';

/// Универсальный виджет пустого состояния экрана.
/// Заменяет копипаст «эмодзи + текст + подзаголовок» в food_library_screen,
/// scenario_list_screen, reports_screen, home_screen и др.
///
/// Пример использования:
/// ```dart
/// AppEmptyState(
///   emoji: '🍽️',
///   title: 'Библиотека пуста',
///   subtitle: 'Добавьте первый продукт',
///   action: ElevatedButton(
///     onPressed: _addItem,
///     child: const Text('Добавить'),
///   ),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...
              [
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                ),
              ],
            if (action != null) ...
              [
                const SizedBox(height: 20),
                action!,
              ],
          ],
        ),
      ),
    );
  }
}
