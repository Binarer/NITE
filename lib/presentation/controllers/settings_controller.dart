import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/settings_service.dart';

class SettingsController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();
  final NotificationService _notifications = NotificationService();

  final RxString mistralApiKey = ''.obs;
  final RxString timezone = ''.obs;
  final RxBool notificationsEnabled = false.obs;
  final RxInt taskReminderMinutes = 15.obs;
  final RxBool isSavingKey = false.obs;
  final RxBool isTestingKey = false.obs;
  // null = не проверялось, true = ок, false = ошибка
  final Rxn<bool> keyTestResult = Rxn<bool>();
  final RxString keyTestMessage = ''.obs;

  /// Сторона меню: 'left' или 'right'
  final RxString menuSide = 'left'.obs;

  /// Выбранный AI-провайдер
  final Rx<AiProvider> aiProvider = AiProvider.mistral.obs;

  /// Текущий API-ключ (для выбранного провайдера)
  final RxString currentApiKey = ''.obs;

  /// Текущая модель (для выбранного провайдера)
  final RxString currentModel = ''.obs;

  /// Флаг: пользователь уже выбирал провайдера (скрываем hint "Выбрать провайдера")
  final RxBool hasProviderBeenSelected = false.obs;

  @override
  void onInit() {
    super.onInit();
    mistralApiKey.value = _settings.legacyMistralKey();
    timezone.value = _settings.timezone;
    notificationsEnabled.value = _settings.notificationsEnabled;
    taskReminderMinutes.value = _settings.taskReminderMinutes;
    menuSide.value = _settings.menuSide;
    aiProvider.value = _settings.aiProvider;
    _loadProviderSettings(aiProvider.value);
    // Если провайдер уже был сохранён — считаем что он уже был выбран
    hasProviderBeenSelected.value = _settings.hasAiProviderBeenSet();
  }

  void _loadProviderSettings(AiProvider provider) {
    currentApiKey.value = _settings.getApiKey(provider);
    currentModel.value = _settings.getModel(provider);
  }

  Future<void> selectAiProvider(AiProvider provider) async {
    aiProvider.value = provider;
    hasProviderBeenSelected.value = true;
    await _settings.setAiProvider(provider);
    _loadProviderSettings(provider);
    // Сбрасываем результат теста
    keyTestResult.value = null;
    keyTestMessage.value = '';
  }

  Future<void> saveApiKey(String key) async {
    isSavingKey.value = true;
    final provider = aiProvider.value;
    await _settings.setApiKey(provider, key.trim());
    currentApiKey.value = key.trim();
    // legacy для Mistral
    if (provider == AiProvider.mistral) {
      mistralApiKey.value = key.trim();
    }
    keyTestResult.value = null;
    keyTestMessage.value = '';
    isSavingKey.value = false;
    Get.snackbar(
      'Сохранено',
      'API ключ ${provider.displayName} обновлён',
      backgroundColor: const Color(0xFF2A2A2A),
      colorText: const Color(0xFFFFFFFF),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> saveModel(String model) async {
    final provider = aiProvider.value;
    await _settings.setModel(provider, model.trim());
    currentModel.value = model.trim();
  }

  Future<void> testApiKey(String key) async {
    if (key.trim().isEmpty) {
      keyTestResult.value = false;
      keyTestMessage.value = 'Введите API ключ';
      return;
    }
    isTestingKey.value = true;
    keyTestResult.value = null;
    keyTestMessage.value = '';
    final service = AiService(
      provider: aiProvider.value,
      apiKey: key.trim(),
      model: currentModel.value,
    );
    final error = await service.testConnection();
    isTestingKey.value = false;
    if (error == null) {
      keyTestResult.value = true;
      keyTestMessage.value = 'Ключ рабочий ✓';
    } else {
      keyTestResult.value = false;
      keyTestMessage.value = error;
    }
  }

  Future<void> setMenuSide(String side) async {
    menuSide.value = side;
    await _settings.setMenuSide(side);
  }

  // Legacy: для совместимости с существующим кодом
  Future<void> saveMistralApiKey(String key) async => saveApiKey(key);
  Future<void> testMistralApiKey(String key) async => testApiKey(key);
  Future<void> setMenuSideLegacy(String side) async => setMenuSide(side);

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    await _settings.setNotificationsEnabled(value);
    if (value) {
      await _notifications.init();
      await _notifications.scheduleWeeklyRetrospective();
    } else {
      await _notifications.cancelAll();
    }
  }

  Future<void> setTaskReminderMinutes(int minutes) async {
    taskReminderMinutes.value = minutes;
    await _settings.setTaskReminderMinutes(minutes);
  }

  Future<void> setTimezone(String tz) async {
    timezone.value = tz;
    await _settings.setTimezone(tz);
    // Обновляем timezone в сервисе уведомлений и перепланируем если включены
    await _notifications.setTimezone(tz);
    if (notificationsEnabled.value) {
      await _notifications.scheduleWeeklyRetrospective();
    }
  }
}
