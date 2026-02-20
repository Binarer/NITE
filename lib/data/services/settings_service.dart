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

  String get mistralApiKey =>
      _box.get(AppConstants.settingsMistralApiKey, defaultValue: '') as String;

  Future<void> setMistralApiKey(String key) async {
    await _box.put(AppConstants.settingsMistralApiKey, key);
  }

  String get timezone =>
      _box.get(AppConstants.settingsTimezone, defaultValue: AppConstants.defaultTimezone) as String;

  Future<void> setTimezone(String tz) async {
    await _box.put(AppConstants.settingsTimezone, tz);
  }

  bool get notificationsEnabled =>
      _box.get('notifications_enabled', defaultValue: false) as bool;

  Future<void> setNotificationsEnabled(bool value) async {
    await _box.put('notifications_enabled', value);
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

  // Legacy: mistral_api_key — для обратной совместимости (не дублируем getter)
  String legacyMistralKey() {
    final newKey = getApiKey(AiProvider.mistral);
    if (newKey.isNotEmpty) return newKey;
    return _box.get(AppConstants.settingsMistralApiKey, defaultValue: '') as String;
  }

  Future<void> legacySetMistralKey(String key) async {
    await setApiKey(AiProvider.mistral, key);
    await _box.put(AppConstants.settingsMistralApiKey, key.trim());
  }

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
}
