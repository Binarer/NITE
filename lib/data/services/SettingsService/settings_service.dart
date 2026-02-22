import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/AppConstants/app_constants.dart';

// ════════════════════════════════════════════════════════════════════════════
// Ключи настроек сгруппированы по логическим доменам.
// Все строковые константы ключей хранятся здесь — изменяйте только здесь.
// ════════════════════════════════════════════════════════════════════════════

/// Ключи группы AI (провайдер, ключ, модель)
abstract class _AiKeys {
  static const provider        = 'ai_provider';
  static const providerSelected = 'ai_provider_selected';
  static String apiKey(String p)   => 'api_key_$p';
  static String model(String p)    => 'ai_model_$p';
}

/// Ключи группы UserProfile (профиль тела)
abstract class _ProfileKeys {
  static const heightCm      = 'body_height_cm';
  static const age           = 'body_age';
  static const gender        = 'body_gender';
  static const activityLevel = 'body_activity_level';
}

/// Ключи группы WeightGoal (цель по весу)
abstract class _WeightGoalKeys {
  static const goalType   = 'weight_goal_type';
  static const targetKg   = 'weight_goal_target_kg';
  static const deadlineMs = 'weight_goal_deadline_ms';
}

/// Ключи группы Nutrition (нормы КБЖУ)
abstract class _NutritionKeys {
  static const calories = 'nutrition_calories';
  static const protein  = 'nutrition_protein';
  static const fat      = 'nutrition_fat';
  static const carbs    = 'nutrition_carbs';
}

/// Ключи группы UI (интерфейс)
abstract class _UiKeys {
  static const menuSide = 'menu_side';
}

/// Ключи группы System (система, уведомления, отчёты)
abstract class _SystemKeys {
  static const timezone              = 'timezone';
  static const notificationsEnabled  = 'notifications_enabled';
  static const taskRemindersEnabled  = 'task_reminders_enabled';
  static const taskReminderMinutes   = 'task_reminder_minutes';
  static const dailyReportHour       = 'daily_report_hour';
  static const pendingDailyReport    = 'pending_daily_report';
  static const pendingWeeklyReport   = 'pending_weekly_report';
  static const debtorEnabled         = 'debtor_enabled';
  static const debtorAiHints         = 'debtor_ai_hints';
  static const weightEntries         = 'weight_entries';
}

/// Список поддерживаемых AI-провайдеров
enum AiProvider {
  mistral,
  openai,
  gemini,
  deepseek,
  qwen,
  anthropic,
  groq,
}

extension AiProviderExt on AiProvider {
  String get displayName {
    switch (this) {
      case AiProvider.mistral:   return 'Mistral AI';
      case AiProvider.openai:    return 'OpenAI (ChatGPT)';
      case AiProvider.gemini:    return 'Google Gemini';
      case AiProvider.deepseek:  return 'DeepSeek';
      case AiProvider.qwen:      return 'Qwen (Alibaba)';
      case AiProvider.anthropic: return 'Anthropic Claude';
      case AiProvider.groq:      return 'Groq';
    }
  }

  String get apiBaseUrl {
    switch (this) {
      case AiProvider.mistral:   return 'https://api.mistral.ai/v1';
      case AiProvider.openai:    return 'https://api.openai.com/v1';
      case AiProvider.gemini:    return 'https://generativelanguage.googleapis.com/v1beta';
      case AiProvider.deepseek:  return 'https://api.deepseek.com/v1';
      case AiProvider.qwen:      return 'https://dashscope.aliyuncs.com/compatible-mode/v1';
      case AiProvider.anthropic: return 'https://api.anthropic.com/v1';
      case AiProvider.groq:      return 'https://api.groq.com/openai/v1';
    }
  }

  /// Шаблонные модели для выбора
  List<String> get modelTemplates {
    switch (this) {
      case AiProvider.mistral:
        return ['mistral-small-latest', 'mistral-medium-latest', 'mistral-large-latest', 'open-mistral-7b'];
      case AiProvider.openai:
        return ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case AiProvider.gemini:
        return ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
      case AiProvider.deepseek:
        return ['deepseek-chat', 'deepseek-reasoner'];
      case AiProvider.qwen:
        return ['qwen-turbo', 'qwen-plus', 'qwen-max'];
      case AiProvider.anthropic:
        return ['claude-3-5-haiku-latest', 'claude-3-5-sonnet-latest', 'claude-3-opus-latest'];
      case AiProvider.groq:
        return ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'mixtral-8x7b-32768'];
    }
  }

  String get name => toString().split('.').last;
}

AiProvider aiProviderFromString(String name) {
  return AiProvider.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AiProvider.mistral,
  );
}

class SettingsService {
  Box get _box => Hive.box(AppConstants.settingsBox);

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: System — часовой пояс, уведомления, должник, вес
  // ════════════════════════════════════════════════════════════════════════════

  String get timezone =>
      _box.get(_SystemKeys.timezone, defaultValue: AppConstants.defaultTimezone) as String;
  Future<void> setTimezone(String tz) async =>
      _box.put(_SystemKeys.timezone, tz);

  bool get notificationsEnabled =>
      _box.get(_SystemKeys.notificationsEnabled, defaultValue: true) as bool;
  Future<void> setNotificationsEnabled(bool value) async =>
      _box.put(_SystemKeys.notificationsEnabled, value);

  /// Включены ли напоминания о конкретных задачах (независимо от общих уведомлений)
  bool get taskRemindersEnabled =>
      _box.get(_SystemKeys.taskRemindersEnabled, defaultValue: true) as bool;
  Future<void> setTaskRemindersEnabled(bool value) async =>
      _box.put(_SystemKeys.taskRemindersEnabled, value);

  /// За сколько минут до задачи присылать уведомление (5, 10, 15, 30)
  int get taskReminderMinutes =>
      _box.get(_SystemKeys.taskReminderMinutes, defaultValue: 15) as int;
  Future<void> setTaskReminderMinutes(int minutes) async =>
      _box.put(_SystemKeys.taskReminderMinutes, minutes);

  /// Час дня когда генерируется ежедневный отчёт (0-23), по умолчанию 20
  int get dailyReportHour =>
      (_box.get(_SystemKeys.dailyReportHour, defaultValue: 20) as num).toInt();
  Future<void> setDailyReportHour(int hour) async =>
      _box.put(_SystemKeys.dailyReportHour, hour);

  bool get pendingDailyReport =>
      _box.get(_SystemKeys.pendingDailyReport, defaultValue: false) as bool;
  Future<void> setPendingDailyReport(bool v) async =>
      _box.put(_SystemKeys.pendingDailyReport, v);

  bool get pendingWeeklyReport =>
      _box.get(_SystemKeys.pendingWeeklyReport, defaultValue: false) as bool;
  Future<void> setPendingWeeklyReport(bool v) async =>
      _box.put(_SystemKeys.pendingWeeklyReport, v);

  /// Включён ли экран "Должник" при запуске
  bool get debtorEnabled =>
      _box.get(_SystemKeys.debtorEnabled, defaultValue: true) as bool;
  Future<void> setDebtorEnabled(bool v) async =>
      _box.put(_SystemKeys.debtorEnabled, v);

  /// Включены ли AI-подсказки в "Должнике"
  bool get debtorAiHints =>
      _box.get(_SystemKeys.debtorAiHints, defaultValue: true) as bool;
  Future<void> setDebtorAiHints(bool v) async =>
      _box.put(_SystemKeys.debtorAiHints, v);

  // ─── Учёт веса ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> getWeightEntries() {
    final raw = _box.get(_SystemKeys.weightEntries, defaultValue: []);
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<void> setWeightEntries(List<Map<String, dynamic>> entries) async =>
      _box.put(_SystemKeys.weightEntries, entries);

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: UI — боковое меню и прочие настройки интерфейса
  // ════════════════════════════════════════════════════════════════════════════

  /// Сторона меню: 'left' или 'right'
  String get menuSide =>
      _box.get(_UiKeys.menuSide, defaultValue: 'left') as String;
  Future<void> setMenuSide(String side) async =>
      _box.put(_UiKeys.menuSide, side);

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: AI — провайдер, ключ, модель
  // ════════════════════════════════════════════════════════════════════════════

  /// Выбранный AI-провайдер
  AiProvider get aiProvider =>
      aiProviderFromString(_box.get(_AiKeys.provider, defaultValue: 'mistral') as String);
  Future<void> setAiProvider(AiProvider provider) async {
    await _box.put(_AiKeys.provider, provider.name);
    await _box.put(_AiKeys.providerSelected, true);
  }

  /// API-ключ для конкретного провайдера
  String getApiKey(AiProvider provider) =>
      _box.get(_AiKeys.apiKey(provider.name), defaultValue: '') as String;
  Future<void> setApiKey(AiProvider provider, String key) async =>
      _box.put(_AiKeys.apiKey(provider.name), key.trim());

  /// Модель для конкретного провайдера
  String getModel(AiProvider provider) {
    final saved = _box.get(_AiKeys.model(provider.name), defaultValue: '') as String;
    if (saved.isNotEmpty) return saved;
    final templates = provider.modelTemplates;
    return templates.isNotEmpty ? templates.first : '';
  }
  Future<void> setModel(AiProvider provider, String model) async =>
      _box.put(_AiKeys.model(provider.name), model.trim());

  /// Возвращает true если провайдер был явно выбран пользователем
  bool hasAiProviderBeenSet() =>
      _box.get(_AiKeys.providerSelected, defaultValue: false) as bool;

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: UserProfile — профиль тела
  // ════════════════════════════════════════════════════════════════════════════

  /// Рост в см
  double get heightCm =>
      (_box.get(_ProfileKeys.heightCm, defaultValue: 175.0) as num).toDouble();
  Future<void> setHeightCm(double v) async =>
      _box.put(_ProfileKeys.heightCm, v);

  /// Возраст в годах
  int get age =>
      (_box.get(_ProfileKeys.age, defaultValue: 25) as num).toInt();
  Future<void> setAge(int v) async =>
      _box.put(_ProfileKeys.age, v);

  /// Пол: 'male' или 'female'
  String get gender =>
      _box.get(_ProfileKeys.gender, defaultValue: 'male') as String;
  Future<void> setGender(String v) async =>
      _box.put(_ProfileKeys.gender, v);

  /// Коэффициент активности (PAL): 'sedentary'|'light'|'moderate'|'active'|'veryActive'
  String get activityLevel =>
      _box.get(_ProfileKeys.activityLevel, defaultValue: 'moderate') as String;
  Future<void> setActivityLevel(String v) async =>
      _box.put(_ProfileKeys.activityLevel, v);

  /// Возвращает нумерический PAL-коэффициент для подсчёта TDEE
  double get activityFactor {
    switch (activityLevel) {
      case 'sedentary':  return 1.2;
      case 'light':      return 1.375;
      case 'active':     return 1.725;
      case 'veryActive': return 1.9;
      case 'moderate':
      default:           return 1.55;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: WeightGoal — цель по весу
  // ════════════════════════════════════════════════════════════════════════════

  /// Тип цели: 'gain' | 'loss' | 'maintain'
  String get weightGoalType =>
      _box.get(_WeightGoalKeys.goalType, defaultValue: 'maintain') as String;
  Future<void> setWeightGoalType(String v) async =>
      _box.put(_WeightGoalKeys.goalType, v);

  /// Целевой вес (кг)
  double get targetWeightKg =>
      (_box.get(_WeightGoalKeys.targetKg, defaultValue: 0.0) as num).toDouble();
  Future<void> setTargetWeightKg(double v) async =>
      _box.put(_WeightGoalKeys.targetKg, v);

  /// Срок достижения цели (Unix timestamp в мс, 0 = не установлен)
  int get weightGoalDeadlineMs =>
      (_box.get(_WeightGoalKeys.deadlineMs, defaultValue: 0) as num).toInt();
  Future<void> setWeightGoalDeadlineMs(int ms) async =>
      _box.put(_WeightGoalKeys.deadlineMs, ms);

  DateTime? get weightGoalDeadline {
    final ms = weightGoalDeadlineMs;
    if (ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  Future<void> setWeightGoalDeadline(DateTime? date) async =>
      _box.put(_WeightGoalKeys.deadlineMs, date?.millisecondsSinceEpoch ?? 0);

  // ════════════════════════════════════════════════════════════════════════════
  // Группа: Nutrition — дневные нормы КБЖУ (единый источник)
  // ════════════════════════════════════════════════════════════════════════════

  /// Дневная норма калорий (ккал)
  double get dailyCalories =>
      (_box.get(_NutritionKeys.calories, defaultValue: 2000.0) as num).toDouble();
  Future<void> setDailyCalories(double v) async =>
      _box.put(_NutritionKeys.calories, v);

  /// Дневная норма белков (г)
  double get dailyProtein =>
      (_box.get(_NutritionKeys.protein, defaultValue: 100.0) as num).toDouble();
  Future<void> setDailyProtein(double v) async =>
      _box.put(_NutritionKeys.protein, v);

  /// Дневная норма жиров (г)
  double get dailyFat =>
      (_box.get(_NutritionKeys.fat, defaultValue: 70.0) as num).toDouble();
  Future<void> setDailyFat(double v) async =>
      _box.put(_NutritionKeys.fat, v);

  /// Дневная норма углеводов (г)
  double get dailyCarbs =>
      (_box.get(_NutritionKeys.carbs, defaultValue: 250.0) as num).toDouble();
  Future<void> setDailyCarbs(double v) async =>
      _box.put(_NutritionKeys.carbs, v);
}
