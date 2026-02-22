import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/constants/AppConstants/app_constants.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/ScenarioModel/scenario_model.dart';
import 'package:nite/presentation/controllers/ScenarioController/scenario_controller.dart';
import 'package:nite/presentation/widgets/common/TagPickerWidget/tag_picker_widget.dart';


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

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _nameCtr = TextEditingController(text: _task.name);
    _descCtr = TextEditingController(text: _task.description);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
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

  @override
  Widget build(BuildContext context) {
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
              decoration: const InputDecoration(hintText: 'Описание (необязательно)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Время
            Row(
              children: [
                Expanded(child: _timeTile('Начало', _task.startMinutes,
                    () => _setTime(true),
                    () => setState(() => _task = ScenarioTask(
                          id: _task.id, name: _task.name,
                          description: _task.description,
                          weekday: _task.weekday, tagIds: _task.tagIds,
                          priority: _task.priority,
                          useAiPriority: _task.useAiPriority,
                          endMinutes: _task.endMinutes,
                        )))),
                const SizedBox(width: 8),
                Expanded(child: _timeTile('Конец', _task.endMinutes,
                    () => _setTime(false),
                    () => setState(() => _task = ScenarioTask(
                          id: _task.id, name: _task.name,
                          description: _task.description,
                          weekday: _task.weekday, tagIds: _task.tagIds,
                          priority: _task.priority,
                          useAiPriority: _task.useAiPriority,
                          startMinutes: _task.startMinutes,
                        )))),
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
                ...List.generate(6, (i) => GestureDetector(
                      onTap: () =>
                          setState(() => _task = _task.copyWith(priority: i)),
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
                              color: AppColors.priorityColor(i), width: 1.5),
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
                    Get.back(result: _task.copyWith(
                      name: name,
                      description: _descCtr.text.trim(),
                    ));
                  },
                  child: const Text('Добавить'),
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
