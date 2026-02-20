import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import 'subtask_model.dart';

part 'task_model.g.dart';

@HiveType(typeId: AppConstants.taskTypeId)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  /// Список id тегов
  @HiveField(3)
  List<String> tagIds;

  /// Приоритет от 0 до 5
  @HiveField(4)
  int priority;

  /// Флаг: использовать ли AI для оценки приоритета
  @HiveField(5)
  bool useAiPriority;

  /// Дата выполнения (хранится как DateTime с обнулёнными часами/минутами)
  @HiveField(6)
  DateTime date;

  /// Время начала в минутах от полуночи (null = без времени)
  @HiveField(7)
  int? startMinutes;

  /// Время конца в минутах от полуночи (null = без времени)
  @HiveField(8)
  int? endMinutes;

  /// Порядок сортировки внутри дня
  @HiveField(9)
  int sortOrder;

  /// ID привязанной карточки еды (если тег "Еда") — оставлен для обратной совместимости
  @HiveField(10)
  String? foodItemId;

  /// Список ID привязанных карточек еды (поддержка нескольких продуктов)
  @HiveField(13)
  List<String> foodItemIds;

  /// ID сценария, из которого создана задача (опционально)
  @HiveField(11)
  String? scenarioId;

  /// Флаг выполнения задачи
  @HiveField(12)
  bool isCompleted;

  /// Подзадачи (чекбоксы внутри задачи)
  @HiveField(14)
  List<SubtaskModel> subtasks;

  /// Граммы потребления еды (по умолчанию 100г, для КБЖУ-расчёта)
  @HiveField(15)
  double foodGrams;

  TaskModel({
    required this.id,
    required this.name,
    this.description = '',
    this.tagIds = const [],
    this.priority = 0,
    this.useAiPriority = false,
    required this.date,
    this.startMinutes,
    this.endMinutes,
    this.sortOrder = 0,
    this.foodItemId,
    this.foodItemIds = const [],
    this.scenarioId,
    this.isCompleted = false,
    this.subtasks = const [],
    this.foodGrams = 100.0,
  });

  /// Удобный доступ к дню недели (1=ПН ... 7=ВС по dart DateTime.weekday)
  int get weekday => date.weekday;

  /// Возвращает строку времени начала в формате "ЧЧ:ММ" или null
  String? get startTimeString {
    if (startMinutes == null) return null;
    final h = startMinutes! ~/ 60;
    final m = startMinutes! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Возвращает строку времени конца в формате "ЧЧ:ММ" или null
  String? get endTimeString {
    if (endMinutes == null) return null;
    final h = endMinutes! ~/ 60;
    final m = endMinutes! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  TaskModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tagIds,
    int? priority,
    bool? useAiPriority,
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    int? sortOrder,
    String? foodItemId,
    List<String>? foodItemIds,
    String? scenarioId,
    bool? isCompleted,
    List<SubtaskModel>? subtasks,
    double? foodGrams,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tagIds: tagIds ?? this.tagIds,
      priority: priority ?? this.priority,
      useAiPriority: useAiPriority ?? this.useAiPriority,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      sortOrder: sortOrder ?? this.sortOrder,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemIds: foodItemIds ?? this.foodItemIds,
      scenarioId: scenarioId ?? this.scenarioId,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      foodGrams: foodGrams ?? this.foodGrams,
    );
  }
}
