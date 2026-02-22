import 'package:flutter/material.dart';

import 'package:get/get.dart';

/// Универсальный диалог подтверждения действия.
/// Заменяет копипаст AlertDialog во всех экранах.
///
/// Пример использования:
/// ```dart
/// final confirmed = await showAppConfirmDialog(
///   title: 'Удалить задачу?',
///   content: 'Это действие нельзя отменить.',
///   confirmLabel: 'Удалить',
///   destructive: true,
/// );
/// if (confirmed) { ... }
/// ```
Future<bool> showAppConfirmDialog({
  required String title,
  String? content,
  String confirmLabel = 'Подтвердить',
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AppConfirmDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmLabel = 'Подтвердить',
    this.cancelLabel = 'Отмена',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor = destructive
        ? const Color(0xFFF44336)
        : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: confirmColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
