import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nite/core/routes/AppRoutes/app_routes.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/TaskModel/task_model.dart';
import 'package:nite/data/repositories/FoodItemRepository/food_item_repository.dart';
import 'package:nite/presentation/controllers/TagController/tag_controller.dart';
import 'package:nite/presentation/controllers/TaskController/task_controller.dart';


class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final task = Get.arguments as TaskModel;
    final tagController = Get.find<TagController>();
    final taskController = Get.find<TaskController>();
    final tags = tagController.getByIds(task.tagIds);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Задача'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Кнопка выполнено в AppBar
          Obx(() {
            // Получаем актуальный статус из контроллера
            final current = taskController.allTasks
                .firstWhereOrNull((t) => t.id == task.id);
            final isCompleted = current?.isCompleted ?? task.isCompleted;
            return IconButton(
              icon: Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : AppColors.textSecondary,
              ),
              tooltip: isCompleted ? 'Отметить невыполненной' : 'Отметить выполненной',
              onPressed: () => taskController.toggleComplete(
                current ?? task,
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название
                  Text(
                    task.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Статус выполнения
                  Obx(() {
                    final current = taskController.allTasks
                        .firstWhereOrNull((t) => t.id == task.id);
                    final isCompleted = current?.isCompleted ?? task.isCompleted;
                    if (!isCompleted) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E5E2E)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: Color(0xFF4CAF50)),
                          SizedBox(width: 6),
                          Text(
                            'Выполнено',
                            style: TextStyle(
                                color: Color(0xFF4CAF50), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Теги
                  if (tags.isNotEmpty) ...[
                    _DetailLabel('Теги'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(tag.colorValue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(tag.colorValue).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tag.emoji,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                tag.name,
                                style: TextStyle(
                                  color: Color(tag.colorValue),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Дата и время
                  _DetailLabel('Дата и время'),
                  _DetailCard(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Дата',
                          value: DateFormat('d MMMM yyyy, EEEE', 'ru')
                              .format(task.date),
                        ),
                        if (task.startMinutes != null) ...[
                          const Divider(
                              color: AppColors.border, height: 16),
                          _DetailRow(
                            icon: Icons.access_time,
                            label: 'Начало',
                            value: _minutesToTime(task.startMinutes!),
                          ),
                        ],
                        if (task.endMinutes != null) ...[
                          const Divider(
                              color: AppColors.border, height: 16),
                          _DetailRow(
                            icon: Icons.access_time_filled,
                            label: 'Конец',
                            value: _minutesToTime(task.endMinutes!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Приоритет
                  _DetailLabel('Приоритет'),
                  _DetailCard(
                    child: Row(
                      children: [
                        _priorityBar(task.priority),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _priorityLabel(task.priority),
                              style: TextStyle(
                                color: _priorityColor(task.priority),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Уровень ${task.priority} из 5',
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 11),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (task.useAiPriority)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A3A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFF3A3A6A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🤖',
                                    style: TextStyle(fontSize: 11)),
                                SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                      color: Color(0xFF8888FF),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  if (task.description.isNotEmpty) ...[
                    _DetailLabel('Описание'),
                    _DetailCard(
                      child: Text(
                        task.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Подзадачи
                  if (task.subtasks.isNotEmpty) ...[
                    _DetailLabel('Подзадачи'),
                    _DetailCard(
                      child: Column(
                        children: task.subtasks.asMap().entries.map((e) {
                          final i = e.key;
                          final s = e.value;
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    i < task.subtasks.length - 1 ? 10 : 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: s.isCompleted
                                          ? AppColors.textSecondary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                    color: s.isCompleted
                                        ? AppColors.textSecondary
                                        : Colors.transparent,
                                  ),
                                  child: s.isCompleted
                                      ? const Icon(Icons.check,
                                          size: 10,
                                          color: AppColors.textPrimary)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: TextStyle(
                                      color: s.isCompleted
                                          ? AppColors.textHint
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      decoration: s.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Продукты питания
                  if (task.foodItemIds.isNotEmpty) ...[
                    _DetailLabel('Продукты питания'),
                    ...task.foodItemIds.map((id) {
                      try {
                        final repo = Get.find<FoodItemRepository>();
                        final item = repo.getById(id);
                        if (item == null) return const SizedBox.shrink();
                        // Используем per-item граммы, fallback на legacy foodGrams
                        final grams = task.foodItemGrams.containsKey(id)
                            ? task.foodItemGrams[id]!
                            : task.foodGrams;
                        final ratio = grams / 100.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DetailCard(
                            child: Row(
                              children: [
                                const Text('🍽️',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${grams.toStringAsFixed(0)}г  •  '
                                        '${(item.calories * ratio).toStringAsFixed(0)} ккал  •  '
                                        'Б ${(item.macros.proteins * ratio).toStringAsFixed(1)}г  '
                                        'Ж ${(item.macros.fats * ratio).toStringAsFixed(1)}г  '
                                        'У ${(item.macros.carbs * ratio).toStringAsFixed(1)}г',
                                        style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    }),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Кнопка редактирования снизу
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Редактировать',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    // Получаем актуальную задачу из контроллера
                    final taskController = Get.find<TaskController>();
                    final current = taskController.allTasks
                        .firstWhereOrNull((t) => t.id == task.id);
                    Get.back(); // закрываем предпросмотр
                    Get.toNamed(
                      AppRoutes.taskEdit,
                      arguments: current ?? task,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _priorityLabel(int p) {
    switch (p) {
      case 0: return 'Без приоритета';
      case 1: return 'Очень низкий';
      case 2: return 'Низкий';
      case 3: return 'Средний';
      case 4: return 'Высокий';
      case 5: return 'Максимальный';
      default: return 'Без приоритета';
    }
  }

  Color _priorityColor(int p) {
    switch (p) {
      case 0: return AppColors.textHint;
      case 1: return const Color(0xFF7B8B6F);
      case 2: return const Color(0xFF4A90D9);
      case 3: return const Color(0xFFF5A623);
      case 4: return const Color(0xFFE8534A);
      case 5: return const Color(0xFFC0392B);
      default: return AppColors.textHint;
    }
  }

  Widget _priorityBar(int p) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _priorityColor(p),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;
  const _DetailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textHint, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
