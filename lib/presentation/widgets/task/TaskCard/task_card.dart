import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/FoodItemModel/food_item_model.dart';
import 'package:nite/data/models/TagModel/tag_model.dart';
import 'package:nite/data/models/TaskModel/task_model.dart';
import 'package:nite/data/repositories/FoodItemRepository/food_item_repository.dart';
import 'package:nite/presentation/controllers/TaskController/task_controller.dart';


class TaskCard extends StatefulWidget {
  final TaskModel task;
  final List<TagModel> tags;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.tags,
    this.onTap,
    this.onToggleComplete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showPreview(BuildContext context) {
    final repo = Get.find<FoodItemRepository>();
    final taskCtrl = Get.find<TaskController>();
    // Собираем все продукты: из foodItemIds и из legacy foodItemId
    final ids = widget.task.foodItemIds.isNotEmpty
        ? widget.task.foodItemIds
        : (widget.task.foodItemId != null ? [widget.task.foodItemId!] : <String>[]);
    final foodItems = ids
        .map((id) => repo.getById(id))
        .whereType<FoodItemModel>()
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TaskPreviewSheet(
        task: widget.task,
        tags: widget.tags,
        foodItems: foodItems,
        onEdit: widget.onTap,
        onToggleComplete: widget.onToggleComplete,
        onToggleSubtask: (subtaskId) => taskCtrl.toggleSubtask(widget.task, subtaskId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final tags = widget.tags;
    final priorityColor = AppColors.priorityColor(task.priority);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: () => _showPreview(context),
          child: AnimatedOpacity(
            opacity: task.isCompleted ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Цветная полоска приоритета слева
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                    // Контент
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.name,
                                    style: TextStyle(
                                      color: task.isCompleted
                                          ? AppColors.textHint
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Кружок выполнения
                                GestureDetector(
                                  onTap: widget.onToggleComplete,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: task.isCompleted
                                            ? AppColors.textSecondary
                                            : AppColors.border,
                                        width: 1.5,
                                      ),
                                      color: task.isCompleted
                                          ? AppColors.textSecondary
                                          : Colors.transparent,
                                    ),
                                    child: task.isCompleted
                                        ? const Icon(Icons.check,
                                            size: 12,
                                            color: AppColors.textPrimary)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            // Время
                            if (task.startTimeString != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 11, color: AppColors.textHint),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.endTimeString != null
                                        ? '${task.startTimeString} – ${task.endTimeString}'
                                        : task.startTimeString!,
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Теги-эмодзи
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 4,
                                children: tags
                                    .map((tag) => Text(
                                          tag.emoji,
                                          style:
                                              const TextStyle(fontSize: 13),
                                        ))
                                    .toList(),
                              ),
                            ],
                            // Подзадачи (прогресс-бар + превью чекбоксов)
                            if (task.subtasks.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _SubtaskProgressBar(subtasks: task.subtasks),
                              const SizedBox(height: 4),
                              ...task.subtasks.take(3).map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 13,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: s.isCompleted
                                                  ? AppColors.textSecondary
                                                  : AppColors.border,
                                              width: 1.2,
                                            ),
                                            color: s.isCompleted
                                                ? AppColors.textSecondary
                                                : Colors.transparent,
                                          ),
                                          child: s.isCompleted
                                              ? const Icon(Icons.check,
                                                  size: 8,
                                                  color: AppColors.textPrimary)
                                              : null,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            s.title,
                                            style: TextStyle(
                                              color: s.isCompleted
                                                  ? AppColors.textHint
                                                  : AppColors.textSecondary,
                                              fontSize: 11,
                                              decoration: s.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              if (task.subtasks.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text(
                                    '+ ещё ${task.subtasks.length - 3}',
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Лист предпросмотра задачи (long press)
// ─────────────────────────────────────────────

class _TaskPreviewSheet extends StatefulWidget {
  final TaskModel task;
  final List<TagModel> tags;
  final List<FoodItemModel> foodItems;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleComplete;
  final void Function(String subtaskId)? onToggleSubtask;

  const _TaskPreviewSheet({
    required this.task,
    required this.tags,
    required this.foodItems,
    this.onEdit,
    this.onToggleComplete,
    this.onToggleSubtask,
  });

  @override
  State<_TaskPreviewSheet> createState() => _TaskPreviewSheetState();
}

class _TaskPreviewSheetState extends State<_TaskPreviewSheet> {
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  void _toggleSubtask(String subtaskId) {
    widget.onToggleSubtask?.call(subtaskId);
    // Обновляем локальный стейт для мгновенного отклика UI
    setState(() {
      _task = _task.copyWith(
        subtasks: _task.subtasks.map((s) {
          if (s.id == subtaskId) {
            return s.copyWith(isCompleted: !s.isCompleted);
          }
          return s;
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorityColor(_task.priority);
    final hasFoodTag = widget.tags.any((t) => t.id == TagModel.foodTagId);

    double totalCalories = 0;
    double totalProteins = 0;
    double totalFats = 0;
    double totalCarbs = 0;
    for (final f in widget.foodItems) {
      totalCalories += f.calories;
      totalProteins += f.macros.proteins;
      totalFats += f.macros.fats;
      totalCarbs += f.macros.carbs;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Цветная полоса приоритета сверху
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название + теги
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _task.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: widget.tags
                            .map((t) => Text(t.emoji,
                                style: const TextStyle(fontSize: 18)))
                            .toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Время
                if (_task.startTimeString != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _task.endTimeString != null
                            ? '${_task.startTimeString} – ${_task.endTimeString}'
                            : _task.startTimeString!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                // Приоритет
                if (_task.priority > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Приоритет: ${_task.priority}/5',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                // Описание
                if (_task.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _task.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
                // Подзадачи
                if (_task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Подзадачи (${_task.subtasks.where((s) => s.isCompleted).length}/${_task.subtasks.length})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._task.subtasks.map((s) => GestureDetector(
                        onTap: () => _toggleSubtask(s.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20,
                                height: 20,
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
                                        size: 12,
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
                                    fontSize: 14,
                                    decoration: s.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                // БЖУ (только если тег "Еда" и есть продукты)
                if (hasFoodTag && widget.foodItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    widget.foodItems.length == 1
                        ? '🍽️  ${widget.foodItems.first.name}'
                        : '🍽️  Продукты (${widget.foodItems.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.foodItems.length > 1) ...[
                    const SizedBox(height: 6),
                    ...widget.foodItems.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(f.name,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ),
                              Text(
                                '${f.calories.toStringAsFixed(0)} ккал',
                                style: const TextStyle(
                                    color: AppColors.textHint, fontSize: 12),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 8),
                  // Суммарное БЖУ
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutriCell(
                          label: widget.foodItems.length > 1 ? 'Итого ккал' : 'Калории',
                          value: '${totalCalories.toStringAsFixed(0)} ккал',
                          color: const Color(0xFFFFB74D),
                        ),
                        _NutriCell(
                          label: 'Белки',
                          value: '${totalProteins.toStringAsFixed(1)} г',
                          color: const Color(0xFF64B5F6),
                        ),
                        _NutriCell(
                          label: 'Жиры',
                          value: '${totalFats.toStringAsFixed(1)} г',
                          color: const Color(0xFFE57373),
                        ),
                        _NutriCell(
                          label: 'Углеводы',
                          value: '${totalCarbs.toStringAsFixed(1)} г',
                          color: const Color(0xFF81C784),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 4),
                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onEdit?.call();
                        },
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.textSecondary),
                        label: const Text('Изменить',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onToggleComplete?.call();
                        },
                        icon: Icon(
                          _task.isCompleted
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle_outline,
                          size: 16,
                          color: _task.isCompleted
                              ? AppColors.textSecondary
                              : const Color(0xFF66BB6A),
                        ),
                        label: Text(
                          _task.isCompleted ? 'Снять отметку' : 'Выполнено',
                          style: TextStyle(
                            color: _task.isCompleted
                                ? AppColors.textSecondary
                                : const Color(0xFF66BB6A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskProgressBar extends StatelessWidget {
  final List subtasks;
  const _SubtaskProgressBar({required this.subtasks});

  @override
  Widget build(BuildContext context) {
    final total = subtasks.length;
    if (total == 0) return const SizedBox.shrink();
    final done = subtasks.where((s) => s.isCompleted as bool).length;
    final progress = done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      done == total
                          ? const Color(0xFF66BB6A)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$done/$total',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NutriCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutriCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
      ],
    );
  }
}
