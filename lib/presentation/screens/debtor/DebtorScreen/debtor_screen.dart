import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/AppTheme/app_theme.dart';
import '../../../../data/models/TagModel/tag_model.dart';
import '../../../../data/models/TaskModel/task_model.dart';
import '../../../../data/repositories/TagRepository/tag_repository.dart';
import '../../../../data/repositories/TaskRepository/task_repository.dart';
import '../../../../data/services/AiService/ai_service.dart';
import '../../../../data/services/SettingsService/settings_service.dart';


class DebtorScreen extends StatefulWidget {
  const DebtorScreen({super.key});

  @override
  State<DebtorScreen> createState() => _DebtorScreenState();
}

class _DebtorScreenState extends State<DebtorScreen>
    with SingleTickerProviderStateMixin {
  late List<TaskModel> _tasks;
  late List<TagModel> _allTags;
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  String? _aiHint;
  bool _loadingAi = false;
  final _settings = Get.find<SettingsService>();

  @override
  void initState() {
    super.initState();
    _allTags = Get.find<TagRepository>().getAll();
    _tasks = _loadOverdueTasks();
    if (_settings.debtorAiHints) _loadAiHint();
  }

  List<TaskModel> _loadOverdueTasks() {
    final repo = Get.find<TaskRepository>();
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return repo
        .getAll()
        .where((t) =>
            !t.isCompleted &&
            DateTime(t.date.year, t.date.month, t.date.day)
                .isBefore(todayDay))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _loadAiHint() async {
    if (_tasks.isEmpty) return;
    setState(() => _loadingAi = true);
    try {
      final provider = _settings.aiProvider;
      final apiKey = _settings.getApiKey(provider);
      if (apiKey.isEmpty) {
        setState(() => _loadingAi = false);
        return;
      }
      final service = AiService(
        provider: provider,
        apiKey: apiKey,
        model: _settings.getModel(provider),
      );
      // Группируем задачи по тегам для AI
      final tagNames = <String>[];
      for (final t in _tasks) {
        for (final tid in t.tagIds) {
          final tag = _allTags.firstWhereOrNull((tg) => tg.id == tid);
          if (tag != null) tagNames.add(tag.name);
        }
      }
      final taskList = _tasks
          .take(10)
          .map((t) => '• ${t.name} (просрочена на ${_daysOverdue(t)} дн.)')
          .join('\n');
      final prompt = '''
Ты — личный помощник по продуктивности. Вот список просроченных задач пользователя:
$taskList

Дай 1-2 коротких совета (до 80 слов): как лучше расставить приоритеты, можно ли что-то объединить в блок? Если несколько задач похожи по теме — предложи запланировать их вместе. Отвечай дружелюбно, на русском.
''';
      final result = await service.sendRaw(prompt, maxTokens: 150);
      if (mounted) setState(() => _aiHint = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  int _daysOverdue(TaskModel t) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final taskDay = DateTime(t.date.year, t.date.month, t.date.day);
    return todayDay.difference(taskDay).inDays;
  }

  Future<void> _swipeRight(TaskModel task) async {
    // Перенести на сегодня
    final repo = Get.find<TaskRepository>();
    final today = DateTime.now();
    // Ищем свободное время сегодня
    final todayTasks = repo.getByDate(today);
    int startMin = 9 * 60; // по умолчанию 09:00
    if (todayTasks.isNotEmpty) {
      final lastEnd = todayTasks
          .where((t) => t.endMinutes != null)
          .map((t) => t.endMinutes!)
          .fold<int>(0, max);
      if (lastEnd > 0) startMin = lastEnd + 15;
    }
    final updated = task.copyWith(
      date: today,
      startMinutes: task.startMinutes != null ? startMin : null,
      endMinutes: task.endMinutes != null && task.startMinutes != null
          ? startMin + (task.endMinutes! - task.startMinutes!)
          : null,
      isCompleted: false,
    );
    await repo.save(updated);
    _next();
  }

  Future<void> _swipeLeft(TaskModel task) async {
    // Выбор даты через DatePicker
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.textSecondary,
            onPrimary: AppColors.textPrimary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final repo = Get.find<TaskRepository>();
      final updated = task.copyWith(date: picked, isCompleted: false);
      await repo.save(updated);
      _next();
    }
  }

  Future<void> _swipeUp(TaskModel task) async {
    // Архивировать — помечаем как выполненную (нет поля isArchived в модели)
    final repo = Get.find<TaskRepository>();
    final updated = task.copyWith(isCompleted: true);
    await repo.save(updated);
    _next();
  }

  void _swipeDown(TaskModel task) {
    // Оставить на исходном дне
    _next();
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      if (_currentIndex < _tasks.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = _tasks.length; // все обработаны
      }
    });
  }

  Future<void> _rescheduleAll() async {
    final repo = Get.find<TaskRepository>();
    final today = DateTime.now();
    for (final task in _tasks.skip(_currentIndex)) {
      final updated = task.copyWith(date: today, isCompleted: false);
      await repo.save(updated);
    }
    if (mounted) {
      Get.back();
      Get.snackbar(
        '✅ Готово',
        'Все задачи перенесены на сегодня',
        backgroundColor: const Color(0xFF1A3A1A),
        colorText: const Color(0xFFFFFFFF),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _tasks.length - _currentIndex;
    final isDone = remaining <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Должник'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (!isDone && remaining > 1)
            TextButton(
              onPressed: _rescheduleAll,
              child: const Text(
                'Всё сегодня',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
      body: isDone ? _buildDoneState() : _buildCardStack(remaining),
    );
  }

  Widget _buildDoneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Все просрочки разобраны!',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Обработано: ${_tasks.length} задач',
            style: const TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Get.back(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(int remaining) {
    final task = _tasks[_currentIndex];
    return Column(
      children: [
        // Прогресс и счётчик
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${_tasks.length}',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                  Text(
                    'Осталось: $remaining',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _currentIndex / _tasks.length,
                backgroundColor: AppColors.border,
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),

        // AI подсказка
        if (_loadingAi || _aiHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D2D5E)),
              ),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _loadingAi
                        ? const Text('AI анализирует...',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12))
                        : Text(
                            _aiHint!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                  ),
                ],
              ),
            ),
          ),

        // Подсказки свайпа
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _SwipeHints(),
        ),

        // Карточка с жестами
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onPanStart: (_) => setState(() => _isDragging = true),
              onPanUpdate: (d) =>
                  setState(() => _dragOffset += d.delta),
              onPanEnd: (_) => _handleSwipeEnd(task),
              child: AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                transform: Matrix4.translationValues(
                    _dragOffset.dx, _dragOffset.dy, 0)
                  ..rotateZ(_dragOffset.dx * 0.001),
                child: _DebtorCard(
                  task: task,
                  allTags: _allTags,
                  dragOffset: _dragOffset,
                  daysOverdue: _daysOverdue(task),
                ),
              ),
            ),
          ),
        ),

        // Кнопки действий
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: Icons.archive_outlined,
                label: 'Архив',
                color: const Color(0xFF888888),
                onTap: () => _swipeUp(task),
              ),
              _ActionBtn(
                icon: Icons.calendar_today_outlined,
                label: 'На дату',
                color: const Color(0xFF4A90D9),
                onTap: () => _swipeLeft(task),
              ),
              _ActionBtn(
                icon: Icons.today_outlined,
                label: 'Сегодня',
                color: const Color(0xFF4CAF50),
                onTap: () => _swipeRight(task),
              ),
              _ActionBtn(
                icon: Icons.redo_outlined,
                label: 'Оставить',
                color: const Color(0xFFF5A623),
                onTap: () => _swipeDown(task),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSwipeEnd(TaskModel task) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final threshold = 80.0;

    if (dy < -threshold && dy.abs() > dx.abs()) {
      // Свайп вверх → архив
      _swipeUp(task);
    } else if (dy > threshold && dy.abs() > dx.abs()) {
      // Свайп вниз → оставить
      _swipeDown(task);
    } else if (dx > threshold) {
      // Свайп вправо → сегодня
      _swipeRight(task);
    } else if (dx < -threshold) {
      // Свайп влево → выбор даты
      _swipeLeft(task);
    } else {
      // Сброс
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }
}

// ─── Карточка задачи ─────────────────────────────────────────────────────────

class _DebtorCard extends StatelessWidget {
  final TaskModel task;
  final List<TagModel> allTags;
  final Offset dragOffset;
  final int daysOverdue;

  const _DebtorCard({
    required this.task,
    required this.allTags,
    required this.dragOffset,
    required this.daysOverdue,
  });

  Color get _overdueColor {
    if (daysOverdue >= 3) return const Color(0xFFEF5350);
    if (daysOverdue >= 1) return const Color(0xFFF5A623);
    return const Color(0xFF4CAF50);
  }

  Color get _priorityColor {
    switch (task.priority) {
      case 5:
        return const Color(0xFFC0392B);
      case 4:
        return const Color(0xFFE8534A);
      case 3:
        return const Color(0xFFF5A623);
      case 2:
        return const Color(0xFF4A90D9);
      case 1:
        return const Color(0xFF7B8B6F);
      default:
        return const Color(0xFF555555);
    }
  }

  // Определяем направление свайпа для подсветки
  String? _swipeDirection() {
    final dx = dragOffset.dx;
    final dy = dragOffset.dy;
    final threshold = 40.0;
    if (dy < -threshold && dy.abs() > dx.abs()) return 'up';
    if (dy > threshold && dy.abs() > dx.abs()) return 'down';
    if (dx > threshold) return 'right';
    if (dx < -threshold) return 'left';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dir = _swipeDirection();
    final tags = task.tagIds
        .map((id) => allTags.firstWhereOrNull((t) => t.id == id))
        .whereType<TagModel>()
        .toList();

    // Оверлей при свайпе
    Color? overlayColor;
    String? overlayText;
    if (dir == 'right') {
      overlayColor = const Color(0x884CAF50);
      overlayText = '✅ Сегодня';
    } else if (dir == 'left') {
      overlayColor = const Color(0x884A90D9);
      overlayText = '📅 На дату';
    } else if (dir == 'up') {
      overlayColor = const Color(0x88888888);
      overlayText = '🗄 Архив';
    } else if (dir == 'down') {
      overlayColor = const Color(0x88F5A623);
      overlayText = '⏭ Оставить';
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: overlayColor?.withValues(alpha: 0.8) ?? AppColors.border,
              width: overlayColor != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Цветная полоска приоритета
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Просрочка
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _overdueColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _overdueColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: _overdueColor),
                            const SizedBox(width: 4),
                            Text(
                              'Просрочено на $daysOverdue ${_daysLabel(daysOverdue)}',
                              style: TextStyle(
                                  color: _overdueColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Название
                      Text(
                        task.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Теги
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(t.colorValue)
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Color(t.colorValue)
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '${t.emoji} ${t.name}',
                                      style: TextStyle(
                                          color: Color(t.colorValue),
                                          fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                        ),
                      const Spacer(),

                      // Исходная дата и время
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('d MMMM yyyy', 'ru')
                                .format(task.date),
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 13),
                          ),
                          if (task.startMinutes != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(task.startMinutes!),
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 13),
                            ),
                          ],
                        ],
                      ),

                      // Приоритет
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _priorityColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Приоритет: ${task.priority}/5',
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Оверлей направления свайпа
        if (overlayColor != null && overlayText != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: overlayColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                overlayText,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _daysLabel(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) {
      return 'дня';
    }
    return 'дней';
  }
}

// ─── Кнопки действий ─────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Подсказки свайпов ───────────────────────────────────────────────────────

class _SwipeHints extends StatelessWidget {
  const _SwipeHints();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _hint('↑', 'Архив', const Color(0xFF888888)),
        _hint('←', 'На дату', const Color(0xFF4A90D9)),
        _hint('→', 'Сегодня', const Color(0xFF4CAF50)),
        _hint('↓', 'Оставить', const Color(0xFFF5A623)),
      ],
    );
  }

  Widget _hint(String arrow, String label, Color color) {
    return Column(
      children: [
        Text(arrow,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
      ],
    );
  }
}
