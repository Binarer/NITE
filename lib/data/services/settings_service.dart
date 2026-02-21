import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

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

  String get timezone =>
      _box.get(AppConstants.settingsTimezone, defaultValue: AppConstants.defaultTimezone) as String;

  Future<void> setTimezone(String tz) async {
    await _box.put(AppConstants.settingsTimezone, tz);
  }

  bool get notificationsEnabled =>
      _box.get('notifications_enabled', defaultValue: true) as bool;

  Future<void> setNotificationsEnabled(bool value) async {
    await _box.put('notifications_enabled', value);
  }

  /// Включены ли напоминания о конкретных задачах (независимо от общих уведомлений)
  bool get taskRemindersEnabled =>
      _box.get('task_reminders_enabled', defaultValue: true) as bool;

  Future<void> setTaskRemindersEnabled(bool value) async {
    await _box.put('task_reminders_enabled', value);
  }

  /// За сколько минут до задачи присылать уведомление (5, 10, 15, 30)
  int get taskReminderMinutes =>
      _box.get('task_reminder_minutes', defaultValue: 15) as int;

  Future<void> setTaskReminderMinutes(int minutes) async {
    await _box.put('task_reminder_minutes', minutes);
  }

  /// Сторона меню: 'left' или 'right'
  String get menuSide =>
      _box.get(AppConstants.settingsMenuSide, defaultValue: 'left') as String;

  Future<void> setMenuSide(String side) async {
    await _box.put(AppConstants.settingsMenuSide, side);
  }

  /// Выбранный AI-провайдер
  AiProvider get aiProvider =>
      aiProviderFromString(_box.get('ai_provider', defaultValue: 'mistral') as String);

  Future<void> setAiProvider(AiProvider provider) async {
    await _box.put('ai_provider', provider.name);
    await _box.put('ai_provider_selected', true);
  }

  /// API-ключ для выбранного провайдера
  String getApiKey(AiProvider provider) =>
      _box.get('api_key_${provider.name}', defaultValue: '') as String;

  Future<void> setApiKey(AiProvider provider, String key) async {
    await _box.put('api_key_${provider.name}', key.trim());
  }

  /// Модель для выбранного провайдера
  String getModel(AiProvider provider) {
    final saved = _box.get('ai_model_${provider.name}', defaultValue: '') as String;
    if (saved.isNotEmpty) return saved;
    final templates = provider.modelTemplates;
    return templates.isNotEmpty ? templates.first : '';
  }

  Future<void> setModel(AiProvider provider, String model) async {
    await _box.put('ai_model_${provider.name}', model.trim());
  }

  /// Возвращает true если провайдер был явно выбран пользователем
  bool hasAiProviderBeenSet() =>
      _box.get('ai_provider_selected', defaultValue: false) as bool;

  // ─── Учёт веса ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> getWeightEntries() {
    final raw = _box.get('weight_entries', defaultValue: []);
    if (raw == null) return [];
    return (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> setWeightEntries(List<Map<String, dynamic>> entries) async {
    await _box.put('weight_entries', entries);
  }

  // ─── Профиль тела ─────────────────────────────────────────────────────────

  /// Рост в см
  double get heightCm =>
      (_box.get('body_height_cm', defaultValue: 175.0) as num).toDouble();
  Future<void> setHeightCm(double v) async =>
      await _box.put('body_height_cm', v);

  /// Возраст в годах
  int get age => (_box.get('body_age', defaultValue: 25) as num).toInt();
  Future<void> setAge(int v) async => await _box.put('body_age', v);

  /// Пол: 'male' или 'female'
  String get gender =>
      _box.get('body_gender', defaultValue: 'male') as String;
  Future<void> setGender(String v) async => await _box.put('body_gender', v);

  // ─── Время ежедневного отчёта ─────────────────────────────────────────────

  /// Час дня когда генерируется ежедневный отчёт (0-23), по умолчанию 20
  int get dailyReportHour =>
      (_box.get('daily_report_hour', defaultValue: 20) as num).toInt();
  Future<void> setDailyReportHour(int hour) async =>
      _box.put('daily_report_hour', hour);

  // ─── Pending report notifications ─────────────────────────────────────────

  bool get pendingDailyReport =>
      _box.get('pending_daily_report', defaultValue: false) as bool;
  Future<void> setPendingDailyReport(bool v) async =>
      _box.put('pending_daily_report', v);

  bool get pendingWeeklyReport =>
      _box.get('pending_weekly_report', defaultValue: false) as bool;
  Future<void> setPendingWeeklyReport(bool v) async =>
      _box.put('pending_weekly_report', v);

  // ─── Должник ──────────────────────────────────────────────────────────────

  /// Включён ли экран "Должник" при запуске
  bool get debtorEnabled =>
      _box.get('debtor_enabled', defaultValue: true) as bool;
  Future<void> setDebtorEnabled(bool v) async =>
      await _box.put('debtor_enabled', v);

  /// Включены ли AI-подсказки в "Должнике"
  bool get debtorAiHints =>
      _box.get('debtor_ai_hints', defaultValue: true) as bool;
  Future<void> setDebtorAiHints(bool v) async =>
      await _box.put('debtor_ai_hints', v);

  // ─── Нормы питания КБЖУ ───────────────────────────────────────────────────

  /// Дневная норма калорий (ккал)
  double get dailyCalories =>
      (_box.get('nutrition_calories', defaultValue: 2000.0) as num).toDouble();
  Future<void> setDailyCalories(double v) async =>
      await _box.put('nutrition_calories', v);

  /// Дневная норма белков (г)
  double get dailyProtein =>
      (_box.get('nutrition_protein', defaultValue: 100.0) as num).toDouble();
  Future<void> setDailyProtein(double v) async =>
      await _box.put('nutrition_protein', v);

  /// Дневная норма жиров (г)
  double get dailyFat =>
      (_box.get('nutrition_fat', defaultValue: 70.0) as num).toDouble();
  Future<void> setDailyFat(double v) async =>
      await _box.put('nutrition_fat', v);

  /// Дневная норма углеводов (г)
  double get dailyCarbs =>
      (_box.get('nutrition_carbs', defaultValue: 250.0) as num).toDouble();
  Future<void> setDailyCarbs(double v) async =>
      await _box.put('nutrition_carbs', v);
}
