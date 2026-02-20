import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/tag_controller.dart';

class TagPickerWidget extends StatelessWidget {
  final RxList<String> selectedIds;
  final void Function(String tagId) onToggle;

  const TagPickerWidget({
    super.key,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tagController = Get.find<TagController>();

    return Obx(() {
      final tags = tagController.tags;
      // Читаем selectedIds внутри Obx, чтобы реагировать на изменения
      final selected = selectedIds.toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          final isSelected = selected.contains(tag.id);
          return GestureDetector(
            onTap: () => onToggle(tag.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(tag.colorValue).withValues(alpha: 0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Color(tag.colorValue)
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    tag.name,
                    style: TextStyle(
                      color: isSelected
                          ? Color(tag.colorValue)
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
