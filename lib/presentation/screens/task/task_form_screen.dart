import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/food_item_repository.dart';
import '../../controllers/task_form_controller.dart';
import '../../widgets/priority_slider_widget.dart';
import '../../widgets/tag_picker_widget.dart';

class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TaskFormController>();
    final isEditing = c.editingTask != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать задачу' : 'Новая задача'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => c.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: c.saveTask,
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название
            _SectionLabel('Название'),
            TextField(
              controller: c.nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Название задачи',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Описание
            _SectionLabel('Описание'),
            TextField(
              controller: c.descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Необязательно',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Теги
            _SectionLabel('Теги'),
            TagPickerWidget(
              selectedIds: c.selectedTagIds,
              onToggle: c.toggleTag,
            ),
            const SizedBox(height: 20),

            // Дата
            _SectionLabel('Дата'),
            Obx(() => _DatePickerTile(
                  date: c.selectedDate.value,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: c.selectedDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => _darkDatePickerTheme(ctx, child),
                    );
                    if (picked != null) c.setDate(picked);
                  },
                )),
            const SizedBox(height: 16),

            // Время начала и конца
            _SectionLabel('Время'),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Начало',
                        minutes: c.startMinutes.value,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: c.startMinutes.value != null
                                ? TimeOfDay(
                                    hour: c.startMinutes.value! ~/ 60,
                                    minute: c.startMinutes.value! % 60)
                                : TimeOfDay.now(),
                            builder: (ctx, child) =>
                                _darkTimePickerTheme(ctx, child),
                          );
                          c.setStartTime(picked);
                        },
                        onClear: () => c.setStartTime(null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Конец',
                        minutes: c.endMinutes.value,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: c.endMinutes.value != null
                                ? TimeOfDay(
                                    hour: c.endMinutes.value! ~/ 60,
                                    minute: c.endMinutes.value! % 60)
                                : TimeOfDay.now(),
                            builder: (ctx, child) =>
                                _darkTimePickerTheme(ctx, child),
                          );
                          c.setEndTime(picked);
                        },
                        onClear: () => c.setEndTime(null),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 20),

            // Приоритет
            _SectionLabel('Приоритет'),
            Obx(() => PrioritySliderWidget(
                  value: c.priority.value,
                  onChanged: c.setPriority,
                )),
            const SizedBox(height: 16),

            // AI оценка приоритета
            Obx(() => _AiPriorityTile(
                  value: c.useAiPriority.value,
                  hasInternet: c.hasInternet.value,
                  onChanged: (v) => c.useAiPriority.value = v,
                )),
            const SizedBox(height: 20),

            // Привязка карточек еды (только если выбран тег "Еда")
            Obx(() {
              if (!c.hasFoodTag) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Продукты питания'),
                  // Список привязанных продуктов
                  ...c.foodItemIds.map((id) => Obx(() => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FoodItemTile(
                      foodItemId: id,
                      grams: c.foodItemGrams[id] ?? 100.0,
                      onGramsChanged: (g) => c.setFoodItemGrams(id, g),
                      onClear: () => c.removeFoodItem(id),
                    ),
                  ))),
                  // Кнопка добавить продукт
                  GestureDetector(
                    onTap: () async {
                      final result = await Get.toNamed(
                        AppRoutes.foodLibrary,
                        arguments: {'selectionMode': true},
                      );
                      if (result is String) c.addFoodItem(result);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            'Добавить продукт',
                            style: TextStyle(color: AppColors.textHint, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),

            // Подзадачи
            _SectionLabel('Подзадачи'),
            Obx(() {
              final subs = c.subtasks;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ReorderableListView для drag & drop
                  if (subs.isNotEmpty)
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final item = subs.removeAt(oldIndex);
                        subs.insert(newIndex, item);
                      },
                      proxyDecorator: (child, index, animation) =>
                          Material(
                            color: Colors.transparent,
                            child: child,
                          ),
                      children: subs.asMap().entries.map((entry) {
                        final s = entry.value;
                        final id = s['id'] as String;
                        final title = s['title'] as String;
                        final done = s['isCompleted'] as bool;
                        return Padding(
                          key: ValueKey(id),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              // Иконка перетаскивания
                              const Icon(Icons.drag_handle,
                                  size: 16, color: AppColors.textHint),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => c.toggleSubtask(id),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: done
                                          ? AppColors.textSecondary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                    color: done
                                        ? AppColors.textSecondary
                                        : Colors.transparent,
                                  ),
                                  child: done
                                      ? const Icon(Icons.check,
                                          size: 12,
                                          color: AppColors.textPrimary)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: done
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => c.removeSubtask(id),
                                child: const Icon(Icons.close,
                                    size: 14, color: AppColors.textHint),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  // Поле добавления новой подзадачи
                  _SubtaskAddField(onAdd: c.addSubtask),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Кнопка удаления (только при редактировании)
            if (isEditing) ...[
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Get.dialog(_DeleteConfirmDialog(
                      onConfirm: () async {
                        final task = c.editingTask;
                        if (task != null) {
                          await c.deleteTask(task.id);
                          Get.back(); // закрыть диалог
                          Get.back(); // закрыть форму
                        }
                      },
                    ));
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFF44336), size: 18),
                  label: const Text(
                    'Удалить задачу',
                    style: TextStyle(color: Color(0xFFF44336)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _darkDatePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.textSecondary,
          onPrimary: AppColors.textPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface),
      ),
      child: child!,
    );
  }

  Widget _darkTimePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.textSecondary,
          onPrimary: AppColors.textPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: AppColors.surface,
          hourMinuteColor: AppColors.surfaceVariant,
          hourMinuteTextColor: AppColors.textPrimary,
          dayPeriodColor: AppColors.surfaceVariant,
          dayPeriodTextColor: AppColors.textPrimary,
          dialBackgroundColor: AppColors.surfaceVariant,
          dialHandColor: AppColors.textSecondary,
          dialTextColor: AppColors.textPrimary,
          entryModeIconColor: AppColors.textSecondary,
        ),
      ),
      child: child!,
    );
  }
}

// --- Вспомогательные виджеты ---

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMMM yyyy, EEEE', 'ru').format(date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              formatted,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final int? minutes;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _TimePickerTile({
    required this.label,
    required this.minutes,
    required this.onTap,
    required this.onClear,
  });

  String get _timeString {
    if (minutes == null) return label;
    final h = minutes! ~/ 60;
    final m = minutes! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _timeString,
                style: TextStyle(
                  color: minutes != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontSize: 14,
                ),
              ),
            ),
            if (minutes != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiPriorityTile extends StatelessWidget {
  final bool value;
  final bool hasInternet;
  final void Function(bool) onChanged;

  const _AiPriorityTile({
    required this.value,
    required this.hasInternet,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оценить приоритет через AI',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hasInternet
                      ? 'Mistral AI определит приоритет при сохранении'
                      : 'Нет подключения к интернету',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value && hasInternet,
            onChanged: hasInternet ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _FoodItemTile extends StatefulWidget {
  final String? foodItemId;
  final double grams;
  final void Function(double) onGramsChanged;
  final VoidCallback onClear;

  const _FoodItemTile({
    required this.foodItemId,
    required this.grams,
    required this.onGramsChanged,
    required this.onClear,
  });

  @override
  State<_FoodItemTile> createState() => _FoodItemTileState();
}

class _FoodItemTileState extends State<_FoodItemTile> {
  late final TextEditingController _gramsCtrl;

  @override
  void initState() {
    super.initState();
    _gramsCtrl = TextEditingController(
      text: widget.grams == widget.grams.roundToDouble()
          ? widget.grams.toInt().toString()
          : widget.grams.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(_FoodItemTile old) {
    super.didUpdateWidget(old);
    // Обновляем текст только если пользователь не редактирует прямо сейчас
    final parsed = double.tryParse(_gramsCtrl.text);
    if (parsed != widget.grams) {
      final newText = widget.grams == widget.grams.roundToDouble()
          ? widget.grams.toInt().toString()
          : widget.grams.toStringAsFixed(1);
      if (_gramsCtrl.text != newText) {
        _gramsCtrl.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String label = 'Продукт';
    double? caloriesPer100;
    double? proteinsPer100;
    double? fatsPer100;
    double? carbsPer100;

    if (widget.foodItemId != null) {
      try {
        final repo = Get.find<FoodItemRepository>();
        final item = repo.getById(widget.foodItemId!);
        if (item != null) {
          label = item.name;
          caloriesPer100 = item.calories;
          proteinsPer100 = item.macros.proteins;
          fatsPer100 = item.macros.fats;
          carbsPer100 = item.macros.carbs;
        }
      } catch (_) {}
    }

    // Автомножитель: КБЖУ × (граммы / 100)
    final ratio = widget.grams / 100.0;
    final kcal = caloriesPer100 != null ? caloriesPer100 * ratio : null;
    final proteins = proteinsPer100 != null ? proteinsPer100 * ratio : null;
    final fats = fatsPer100 != null ? fatsPer100 * ratio : null;
    final carbs = carbsPer100 != null ? carbsPer100 * ratio : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Строка: эмодзи + название + крестик
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClear,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.textHint),
              ),
            ],
          ),

          if (caloriesPer100 != null) ...[
            const SizedBox(height: 10),
            // Поле ввода граммов
            Row(
              children: [
                const Text(
                  'Количество:',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  height: 32,
                  child: TextField(
                    controller: _gramsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                            color: AppColors.textSecondary),
                      ),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        widget.onGramsChanged(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'г',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Пересчитанное КБЖУ
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip('🔥', '${kcal!.toStringAsFixed(0)} ккал',
                      const Color(0xFFFF9800)),
                  _MacroChip('💪', 'Б ${proteins!.toStringAsFixed(1)}г',
                      const Color(0xFF4CAF50)),
                  _MacroChip('🥑', 'Ж ${fats!.toStringAsFixed(1)}г',
                      const Color(0xFFFFEB3B)),
                  _MacroChip('🍞', 'У ${carbs!.toStringAsFixed(1)}г',
                      const Color(0xFF2196F3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _MacroChip(this.emoji, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SubtaskAddField extends StatefulWidget {
  final void Function(String) onAdd;
  const _SubtaskAddField({required this.onAdd});

  @override
  State<_SubtaskAddField> createState() => _SubtaskAddFieldState();
}

class _SubtaskAddFieldState extends State<_SubtaskAddField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Добавить подзадачу...',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submit,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add,
                size: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Удалить задачу?',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: const Text(
        'Это действие нельзя отменить.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Отмена',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Удалить',
              style: TextStyle(color: Color(0xFFF44336))),
        ),
      ],
    );
  }
}
