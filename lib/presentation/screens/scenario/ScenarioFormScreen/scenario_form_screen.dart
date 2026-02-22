import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/constants/AppConstants/app_constants.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/ScenarioModel/scenario_model.dart';
import 'package:nite/data/models/SubtaskModel/subtask_model.dart';
import 'package:nite/presentation/controllers/FoodItemController/food_item_controller.dart';
import 'package:nite/presentation/controllers/ScenarioController/scenario_controller.dart';
import 'package:nite/presentation/controllers/TagController/tag_controller.dart';
import 'package:nite/presentation/widgets/common/TagPickerWidget/tag_picker_widget.dart';
import 'package:uuid/uuid.dart';


class ScenarioFormScreen extends StatefulWidget {
  const ScenarioFormScreen({super.key});

  @override
  State<ScenarioFormScreen> createState() => _ScenarioFormScreenState();
}

class _ScenarioFormScreenState extends State<ScenarioFormScreen> {
  late ScenarioModel _scenario;
  late bool _isEditing;
  final ScenarioController _c = Get.find<ScenarioController>();
  final _nameCtr = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is ScenarioModel) {
      _scenario = ScenarioModel(
        id: args.id,
        name: args.name,
        tasks: List<ScenarioTask>.from(args.tasks),
      );
      _isEditing = args.name.isNotEmpty;
    } else {
      _scenario = _c.createEmpty();
      _isEditing = false;
    }
    _nameCtr.text = _scenario.name;
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Ошибка', 'Введите название сценария',
          backgroundColor: const Color(0xFF2A2A2A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final saved = ScenarioModel(
        id: _scenario.id,
        name: name,
        tasks: _scenario.tasks,
      );
      await _c.saveScenario(saved);
      Get.back();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text('Удалить сценарий?',
          style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary))),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Удалить',
                style: TextStyle(color: Color(0xFFF44336)))),
      ],
    ));
    if (confirm == true) {
      await _c.deleteScenario(_scenario.id);
      Get.back();
    }
  }

  void _addTask(int weekday) async {
    final newTask = _c.createEmptyTask(weekday);
    final result = await _showTaskDialog(newTask);
    if (result != null) {
      setState(() => _scenario = ScenarioModel(
            id: _scenario.id,
            name: _scenario.name,
            tasks: [..._scenario.tasks, result],
          ));
    }
  }

  void _editTask(ScenarioTask task) async {
    final result = await _showTaskDialog(task);
    if (result != null) {
      setState(() {
        final tasks = _scenario.tasks.map((t) => t.id == result.id ? result : t).toList();
        _scenario = ScenarioModel(id: _scenario.id, name: _scenario.name, tasks: tasks);
      });
    }
  }

  void _deleteTask(String taskId) {
    setState(() {
      final tasks = _scenario.tasks.where((t) => t.id != taskId).toList();
      _scenario = ScenarioModel(id: _scenario.id, name: _scenario.name, tasks: tasks);
    });
  }

  Future<ScenarioTask?> _showTaskDialog(ScenarioTask task) async {
    return await Get.dialog<ScenarioTask>(
      _ScenarioTaskDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать сценарий' : 'Новый сценарий'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textSecondary),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Сохранить',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название
            _label('Название сценария'),
            TextField(
              controller: _nameCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'Например: Спортивная неделя'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Недельный планировщик
            _label('Задачи по дням недели'),
            ...List.generate(7, (i) => _DaySection(
              weekdayIndex: i,
              tasks: _scenario.tasks.where((t) => t.weekday == i).toList(),
              onAdd: () => _addTask(i),
              onEdit: _editTask,
              onDelete: _deleteTask,
            )),

            const SizedBox(height: 16),

            // Применить кнопка
            if (_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Применить сценарий'),
                  onPressed: () async {
                    await _save();
                    final updated = _c.getById(_scenario.id);
                    if (updated != null) await _c.showApplyDialog(updated);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFF44336), size: 18),
                  label: const Text('Удалить сценарий',
                      style: TextStyle(color: Color(0xFFF44336))),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

// --- Секция одного дня ---
class _DaySection extends StatelessWidget {
  final int weekdayIndex;
  final List<ScenarioTask> tasks;
  final VoidCallback onAdd;
  final void Function(ScenarioTask) onEdit;
  final void Function(String) onDelete;

  const _DaySection({
    required this.weekdayIndex,
    required this.tasks,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок дня
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  AppConstants.weekdayFullNames[weekdayIndex],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: const Icon(Icons.add,
                      size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Задачи
          if (tasks.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            ...tasks.map((task) => _ScenarioTaskTile(
                  task: task,
                  onTap: () => onEdit(task),
                  onDelete: () => onDelete(task.id),
                )),
          ],
        ],
      ),
    );
  }
}

// --- Тайл задачи в сценарии ---
class _ScenarioTaskTile extends StatelessWidget {
  final ScenarioTask task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScenarioTaskTile({
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  String? _timeStr(int? minutes) {
    if (minutes == null) return null;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = _timeStr(task.startMinutes);
    final end = _timeStr(task.endMinutes);
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      title: Text(
        task.name.isEmpty ? 'Без названия' : task.name,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
      subtitle: start != null
          ? Text(
              end != null ? '$start – $end' : start,
              style:
                  const TextStyle(color: AppColors.textHint, fontSize: 11),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.close,
            size: 16, color: AppColors.textHint),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

// --- Диалог создания/редактирования задачи сценария ---
class _ScenarioTaskDialog extends StatefulWidget {
  final ScenarioTask task;
  const _ScenarioTaskDialog({required this.task});

  @override
  State<_ScenarioTaskDialog> createState() => _ScenarioTaskDialogState();
}

class _ScenarioTaskDialogState extends State<_ScenarioTaskDialog> {
  late ScenarioTask _task;
  late TextEditingController _nameCtr;
  late TextEditingController _descCtr;
  late List<SubtaskModel> _subtasks;
  late List<String> _foodItemIds;
  late Map<String, double> _foodItemGrams;
  final _subtaskCtr = TextEditingController();
  final _uuid = const Uuid();

  // Определяем, есть ли тег «еда» среди выбранных
  bool get _hasFoodTag {
    try {
      final tagCtrl = Get.find<TagController>();
      return _task.tagIds.any((id) {
        final tag = tagCtrl.tags.firstWhereOrNull((t) => t.id == id);
        return tag != null &&
            (tag.name.toLowerCase().contains('еда') ||
                tag.name.toLowerCase().contains('food') ||
                tag.name.toLowerCase().contains('питани'));
      });
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _nameCtr = TextEditingController(text: _task.name);
    _descCtr = TextEditingController(text: _task.description);
    _subtasks = List<SubtaskModel>.from(_task.subtasks);
    _foodItemIds = List<String>.from(_task.foodItemIds);
    _foodItemGrams = Map<String, double>.from(_task.foodItemGrams);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    _subtaskCtr.dispose();
    super.dispose();
  }

  void _setTime(bool isStart) async {
    final current = isStart ? _task.startMinutes : _task.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay(hour: current ~/ 60, minute: current % 60)
          : TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.textSecondary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final mins = picked.hour * 60 + picked.minute;
      setState(() => _task = _task.copyWith(
            startMinutes: isStart ? mins : _task.startMinutes,
            endMinutes: isStart ? _task.endMinutes : mins,
          ));
    }
  }

  void _addSubtask() {
    final title = _subtaskCtr.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks = [
        ..._subtasks,
        SubtaskModel(id: _uuid.v4(), title: title, isCompleted: false),
      ];
    });
    _subtaskCtr.clear();
  }

  void _removeSubtask(String id) {
    setState(() => _subtasks = _subtasks.where((s) => s.id != id).toList());
  }

  void _addFood() async {
    final foodCtrl = Get.find<FoodItemController>();
    // Открываем экран выбора еды в режиме выбора
    final result = await Get.toNamed(
      '/food-library',
      arguments: {'selectionMode': true},
    );
    if (result is String) {
      // вернул один id
      setState(() {
        if (!_foodItemIds.contains(result)) {
          _foodItemIds = [..._foodItemIds, result];
          _foodItemGrams = {..._foodItemGrams, result: 100.0};
        }
      });
    } else if (result is List) {
      // вернул список id
      setState(() {
        for (final id in result.cast<String>()) {
          if (!_foodItemIds.contains(id)) {
            _foodItemIds = [..._foodItemIds, id];
            _foodItemGrams = {..._foodItemGrams, id: 100.0};
          }
        }
      });
    } else {
      // Fallback: показываем bottom sheet со списком еды
      final food = await _showFoodPickerSheet(foodCtrl);
      if (food != null && !_foodItemIds.contains(food)) {
        setState(() {
          _foodItemIds = [..._foodItemIds, food];
          _foodItemGrams = {..._foodItemGrams, food: 100.0};
        });
      }
    }
  }

  Future<String?> _showFoodPickerSheet(FoodItemController foodCtrl) async {
    final searchCtrl = TextEditingController();
    String query = '';
    return await Get.bottomSheet<String>(
      StatefulBuilder(builder: (ctx, setBS) {
        final items = foodCtrl.allItems
            .where((f) =>
                !f.isHidden &&
                (query.isEmpty ||
                    f.name.toLowerCase().contains(query.toLowerCase())))
            .toList();
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Поиск продукта...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                  ),
                  onChanged: (v) => setBS(() => query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final f = items[i];
                    return ListTile(
                      dense: true,
                      title: Text(f.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                      subtitle: Text(
                          '${f.calories.toStringAsFixed(0)} ккал / 100г',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                      onTap: () => Get.back(result: f.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  void _removeFood(String id) {
    setState(() {
      _foodItemIds = _foodItemIds.where((i) => i != id).toList();
      final updated = Map<String, double>.from(_foodItemGrams);
      updated.remove(id);
      _foodItemGrams = updated;
    });
  }

  void _updateGrams(String id, String val) {
    final grams = double.tryParse(val.replaceAll(',', '.')) ?? 100.0;
    setState(() => _foodItemGrams = {..._foodItemGrams, id: grams});
  }

  @override
  Widget build(BuildContext context) {
    final foodCtrl = Get.find<FoodItemController>();
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.weekdayFullNames[_task.weekday],
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Название
            TextField(
              controller: _nameCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Название задачи'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Описание
            TextField(
              controller: _descCtr,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'Описание (необязательно)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Время
            Row(
              children: [
                Expanded(
                    child: _timeTile(
                        'Начало',
                        _task.startMinutes,
                        () => _setTime(true),
                        () => setState(() {
                              _task = ScenarioTask(
                                id: _task.id,
                                name: _task.name,
                                description: _task.description,
                                weekday: _task.weekday,
                                tagIds: _task.tagIds,
                                priority: _task.priority,
                                useAiPriority: _task.useAiPriority,
                                endMinutes: _task.endMinutes,
                                foodItemIds: _task.foodItemIds,
                                foodItemGrams: _task.foodItemGrams,
                                subtasks: _task.subtasks,
                              );
                            }))),
                const SizedBox(width: 8),
                Expanded(
                    child: _timeTile(
                        'Конец',
                        _task.endMinutes,
                        () => _setTime(false),
                        () => setState(() {
                              _task = ScenarioTask(
                                id: _task.id,
                                name: _task.name,
                                description: _task.description,
                                weekday: _task.weekday,
                                tagIds: _task.tagIds,
                                priority: _task.priority,
                                useAiPriority: _task.useAiPriority,
                                startMinutes: _task.startMinutes,
                                foodItemIds: _task.foodItemIds,
                                foodItemGrams: _task.foodItemGrams,
                                subtasks: _task.subtasks,
                              );
                            }))),
              ],
            ),
            const SizedBox(height: 12),
            // Приоритет
            Row(
              children: [
                const Text('Приоритет:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                ...List.generate(
                    6,
                    (i) => GestureDetector(
                          onTap: () => setState(
                              () => _task = _task.copyWith(priority: i)),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _task.priority == i
                                  ? AppColors.priorityColor(i)
                                  : AppColors.surfaceVariant,
                              border: Border.all(
                                  color: AppColors.priorityColor(i),
                                  width: 1.5),
                            ),
                            child: Center(
                              child: Text('$i',
                                  style: TextStyle(
                                      color: _task.priority == i
                                          ? Colors.white
                                          : AppColors.textHint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )),
              ],
            ),
            const SizedBox(height: 12),
            // Теги
            const Text('Теги:',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TagPickerWidget(
              selectedIds: RxList<String>.from(_task.tagIds),
              onToggle: (id) {
                final ids = List<String>.from(_task.tagIds);
                ids.contains(id) ? ids.remove(id) : ids.add(id);
                setState(() => _task = _task.copyWith(tagIds: ids));
              },
            ),
            // ─── Еда (если тег «еда») ──────────────────────────────────────
            if (_hasFoodTag) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Продукты питания:',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addFood,
                    child: const Icon(Icons.add,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_foodItemIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Нет продуктов. Нажмите +',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                )
              else
                ..._foodItemIds.map((id) {
                  final food = foodCtrl.getById(id);
                  final grams = _foodItemGrams[id] ?? 100.0;
                  final gramsCtrl =
                      TextEditingController(text: grams.toStringAsFixed(0));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            food?.name ?? id,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: gramsCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              suffixText: 'г',
                              suffixStyle: TextStyle(
                                  color: AppColors.textHint, fontSize: 11),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                            ),
                            onChanged: (v) => _updateGrams(id, v),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeFood(id),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }),
            ],
            // ─── Подзадачи ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            const Text('Подзадачи:',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._subtasks.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13)),
                      ),
                      GestureDetector(
                        onTap: () => _removeSubtask(s.id),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.textHint),
                      ),
                    ],
                  ),
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskCtr,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Новая подзадача...',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: _addSubtask,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = _nameCtr.text.trim();
                    if (name.isEmpty) return;
                    Get.back(
                        result: _task.copyWith(
                      name: name,
                      description: _descCtr.text.trim(),
                      foodItemIds: _foodItemIds,
                      foodItemGrams: _foodItemGrams,
                      subtasks: _subtasks,
                    ));
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(
      String label, int? minutes, VoidCallback onTap, VoidCallback onClear) {
    String text;
    if (minutes == null) {
      text = label;
    } else {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      text =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: minutes != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: 13)),
            ),
            if (minutes != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 13, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}
