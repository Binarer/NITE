import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nite/core/constants/AppConstants/app_constants.dart';
import 'package:nite/core/routes/AppRoutes/app_routes.dart';
import 'package:nite/core/theme/AppTheme/app_theme.dart';
import 'package:nite/data/models/FoodItemModel/food_item_model.dart';
import 'package:nite/data/repositories/FoodItemRepository/food_item_repository.dart';
import 'package:nite/data/services/ExportImportService/export_import_service.dart';
import 'package:nite/data/services/NotificationService/notification_service.dart';
import 'package:nite/data/services/ReportService/report_service.dart';
import 'package:nite/data/services/SettingsService/settings_service.dart';
import 'package:nite/data/services/UpdateService/update_service.dart';
import 'package:nite/presentation/controllers/FoodItemController/food_item_controller.dart';
import 'package:nite/presentation/controllers/SettingsController/settings_controller.dart';
import 'package:nite/presentation/controllers/StatisticsController/statistics_controller.dart';
import 'package:nite/presentation/widgets/common/SectionHeader/section_header.dart';
import 'package:nite/presentation/widgets/common/SettingsSwitchTile/settings_switch_tile.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyCtr;
  late TextEditingController _modelCtr;
  late SettingsController _c;
  bool _obscureKey = true;

  // Шаг настройки AI: 0=провайдер, 1=ключ, 2=модель
  final RxInt _aiStep = 0.obs;

  @override
  void initState() {
    super.initState();
    _c = Get.find<SettingsController>();
    _apiKeyCtr = TextEditingController(text: _c.currentApiKey.value);
    _modelCtr = TextEditingController(text: _c.currentModel.value);

    // Если провайдер уже выбран и ключ сохранён — сразу на шаг модели (3)
    if (_c.hasProviderBeenSelected.value) {
      if (_c.currentApiKey.value.isNotEmpty) {
        _aiStep.value = 3; // ключ есть — доверяем, сразу к модели
      } else {
        _aiStep.value = 1; // провайдер выбран, но ключа нет
      }
    }

    ever(_c.aiProvider, (_) {
      _apiKeyCtr.text = _c.currentApiKey.value;
      _modelCtr.text = _c.currentModel.value;
      // При смене провайдера сбрасываем на шаг ключа
      _aiStep.value = _c.currentApiKey.value.isNotEmpty ? 3 : 1;
    });
    ever(_c.currentApiKey, (v) {
      if (_apiKeyCtr.text != v) _apiKeyCtr.text = v;
    });
    ever(_c.currentModel, (v) {
      if (_modelCtr.text != v) _modelCtr.text = v;
    });
    // После успешной проверки ключа — переходим к выбору модели
    ever(_c.keyTestResult, (result) {
      if (result == true) _aiStep.value = 3;
    });
  }

  @override
  void dispose() {
    _apiKeyCtr.dispose();
    _modelCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- AI-провайдер ---
          SectionHeader(title: 'Искусственный интеллект', padding: const EdgeInsets.only(bottom: 8)),
          _AiSetupCard(
            c: _c,
            aiStep: _aiStep,
            apiKeyCtr: _apiKeyCtr,
            modelCtr: _modelCtr,
            obscureKey: _obscureKey,
            onToggleObscure: () => setState(() => _obscureKey = !_obscureKey),
          ),
          const SizedBox(height: 20),

          // --- Теги ---
          SectionHeader(title: 'Теги', padding: const EdgeInsets.only(bottom: 8)),
          _SettingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_outline,
                  color: AppColors.textSecondary),
              title: const Text('Управление тегами',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Добавить, изменить или удалить теги',
                  style: TextStyle(
                      color: AppColors.textHint, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textHint),
              onTap: () => Get.toNamed(AppRoutes.tagManager),
            ),
          ),
          const SizedBox(height: 20),

          // --- Уведомления ---
          SectionHeader(title: 'Уведомления', padding: const EdgeInsets.only(bottom: 8)),
          _SettingsCard(
            child: Column(
              children: [
                Obx(() => SettingsSwitchTile(
                      title: 'Еженедельная ретроспектива',
                      subtitle:
                          'Каждый понедельник в 12:00 — отчёт о продуктивности',
                      value: _c.notificationsEnabled.value,
                      onChanged: _c.setNotificationsEnabled,
                    )),
                const Divider(color: AppColors.border, height: 24),
                Obx(() => SettingsSwitchTile(
                      title: 'Напоминания о задачах',
                      subtitle:
                          'Уведомление до начала задачи (если задана время)',
                      value: _c.taskRemindersEnabled.value,
                      onChanged: _c.setTaskRemindersEnabled,
                    )),
                const Divider(color: AppColors.border, height: 24),
                // Время ежедневного отчёта
                Row(
                  children: [
                    const Icon(Icons.summarize_outlined,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ежедневный отчёт',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'В какое время генерировать отчёт о дне',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final selected = _c.dailyReportHour.value;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [18, 19, 20, 21, 22, 23].map((hour) {
                      final isSelected = selected == hour;
                      return GestureDetector(
                        onTap: () => _c.setDailyReportHour(hour),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textSecondary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '$hour:00',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
                const Divider(color: AppColors.border, height: 24),
                // Выбор времени напоминания о задачах
                Row(
                  children: [
                    const Icon(Icons.alarm_outlined,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Напоминание о задаче',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'За сколько минут до начала задачи',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final selected = _c.taskReminderMinutes.value;
                  return Row(
                    children: [5, 10, 15, 30].map((minutes) {
                      final isSelected = selected == minutes;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _c.setTaskReminderMinutes(minutes),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.textSecondary
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$minutes',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  'мин',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textSecondary
                                        : AppColors.textHint,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Часовой пояс ---
          SectionHeader(title: 'Часовой пояс', padding: const EdgeInsets.only(bottom: 8)),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      _c.timezone.value,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                    )),
                const SizedBox(height: 8),
                const Text(
                  'Используется для еженедельных уведомлений',
                  style:
                      TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppConstants.defaultTimezone,
                    'Europe/Moscow',
                    'Europe/London',
                    'America/New_York',
                  ].map((tz) => Obx(() {
                        final isSelected = _c.timezone.value == tz;
                        return GestureDetector(
                          onTap: () => _c.setTimezone(tz),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.textSecondary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              tz.split('/').last.replaceAll('_', ' '),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      })).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Меню ---
          SectionHeader(title: 'Боковое меню', padding: const EdgeInsets.only(bottom: 8)),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Расположение кнопки и направление',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final side = _c.menuSide.value;
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _c.setMenuSide('left'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: side == 'left'
                                  ? AppColors.surfaceVariant
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: side == 'left'
                                    ? AppColors.textSecondary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.first_page,
                                    size: 16,
                                    color: side == 'left'
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Слева',
                                  style: TextStyle(
                                    color: side == 'left'
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: side == 'left'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _c.setMenuSide('right'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: side == 'right'
                                  ? AppColors.surfaceVariant
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: side == 'right'
                                    ? AppColors.textSecondary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.last_page,
                                    size: 16,
                                    color: side == 'right'
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Справа',
                                  style: TextStyle(
                                    color: side == 'right'
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: side == 'right'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Профиль тела ---
          SectionHeader(title: 'Профиль тела', padding: const EdgeInsets.only(bottom: 8)),
          _BodyProfileCard(),
          const SizedBox(height: 20),

          // --- Учёт веса ---
          SectionHeader(title: 'Учёт веса', padding: const EdgeInsets.only(bottom: 8)),
          _WeightTrackingCard(),
          const SizedBox(height: 20),

          // --- Цель по весу ---
          SectionHeader(title: 'Цель по весу', padding: const EdgeInsets.only(bottom: 8)),
          _WeightGoalCard(),
          const SizedBox(height: 20),

          // --- Нормы питания ---
          SectionHeader(title: 'Нормы питания', padding: const EdgeInsets.only(bottom: 8)),
          _NutritionGoalsCard(),
          const SizedBox(height: 20),

          // --- Должник ---
          SectionHeader(title: 'Должник', padding: const EdgeInsets.only(bottom: 8)),
          _DebtorSettingsCard(),
          const SizedBox(height: 20),

          // --- Экспорт / Импорт ---
          SectionHeader(title: 'Данные', padding: const EdgeInsets.only(bottom: 8)),
          _ExportImportCard(),
          const SizedBox(height: 20),

          // --- Обновления ---
          SectionHeader(title: 'Обновления', padding: const EdgeInsets.only(bottom: 8)),
          _SettingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update_outlined, color: AppColors.textSecondary),
              title: const Text('Проверить обновления',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Текущая версия: 1.2.1',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => UpdateService().checkForUpdate(silent: false),
            ),
          ),
          const SizedBox(height: 20),

          // --- Для разработчиков ---
          SectionHeader(title: 'Для разработчиков', padding: const EdgeInsets.only(bottom: 8)),
          _DevToolsCard(),
          const SizedBox(height: 32),

          // --- О приложении ---
          Center(
            child: Column(
              children: const [
                Text('NiTe',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                SizedBox(height: 4),
                Text('v1.2.0',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ─── AI Setup Card (шаговый: провайдер → ключ → проверка → модель) ──────────

class _AiSetupCard extends StatelessWidget {
  final SettingsController c;
  final RxInt aiStep;
  final TextEditingController apiKeyCtr;
  final TextEditingController modelCtr;
  final bool obscureKey;
  final VoidCallback onToggleObscure;

  const _AiSetupCard({
    required this.c,
    required this.aiStep,
    required this.apiKeyCtr,
    required this.modelCtr,
    required this.obscureKey,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = aiStep.value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Индикатор шагов
            _StepIndicator(currentStep: step),
            const SizedBox(height: 16),

            // Шаг 0: Выбор провайдера
            _AnimatedStep(
              visible: true, // шаг 0 всегда виден (провайдер можно менять)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _stepBadge(1, step >= 0),
                      const SizedBox(width: 8),
                      const Text('Провайдер',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() => DropdownButtonFormField<AiProvider?>(
                    initialValue: c.hasProviderBeenSelected.value
                        ? c.aiProvider.value
                        : null,
                    dropdownColor: AppColors.surfaceVariant,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text(
                      'Выбрать провайдера...',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                    ),
                    items: AiProvider.values
                        .map((p) => DropdownMenuItem<AiProvider?>(
                              value: p,
                              child: Text(p.displayName),
                            ))
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        c.selectAiProvider(p);
                        aiStep.value = 1;
                      }
                    },
                  )),
                  if (step == 0 && c.hasProviderBeenSelected.value) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => aiStep.value = 1,
                        child: const Text('Далее →'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Шаг 1: Ввод API ключа
            _AnimatedStep(
              visible: step >= 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stepBadge(2, step >= 1),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('API ключ',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      // Кнопка назад
                      if (step == 1)
                        GestureDetector(
                          onTap: () => aiStep.value = 0,
                          child: const Text('← Назад',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: apiKeyCtr,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    obscureText: obscureKey,
                    decoration: InputDecoration(
                      hintText: 'sk-... / AIza... / ...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        'Получите ключ на сайте ${c.aiProvider.value.displayName}',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      )),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceVariant,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: c.isSavingKey.value
                                  ? null
                                  : () async {
                                      await c.saveApiKey(apiKeyCtr.text);
                                      aiStep.value = 2;
                                    },
                              child: c.isSavingKey.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textSecondary))
                                  : const Text('Далее →'),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Шаг 2: Проверка соединения
            _AnimatedStep(
              visible: step >= 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stepBadge(3, step >= 2),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Проверка соединения',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (step == 2)
                        GestureDetector(
                          onTap: () => aiStep.value = 1,
                          child: const Text('← Назад',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final result = c.keyTestResult.value;
                    final testing = c.isTestingKey.value;
                    final msg = c.keyTestMessage.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Статус
                        if (testing)
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textSecondary),
                              ),
                              SizedBox(width: 10),
                              Text('Проверяю подключение...',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          )
                        else if (result == true)
                          Row(
                            children: const [
                              Icon(Icons.check_circle,
                                  size: 16, color: Color(0xFF4CAF50)),
                              SizedBox(width: 8),
                              Text('Соединение успешно!',
                                  style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        else if (result == false)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.error_outline,
                                      size: 16, color: Color(0xFFEF5350)),
                                  SizedBox(width: 8),
                                  Text('Ошибка подключения',
                                      style: TextStyle(
                                          color: Color(0xFFEF5350),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (msg.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(msg,
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11)),
                              ],
                            ],
                          )
                        else
                          const Text(
                            'Нажмите «Проверить» для тестового запроса к API',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: result == true
                                      ? const Color(0xFF1A3A1A)
                                      : result == false
                                          ? const Color(0xFF3A1A1A)
                                          : AppColors.surfaceVariant,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: testing
                                    ? null
                                    : () => c.testApiKey(apiKeyCtr.text),
                                child: Text(result == true
                                    ? '✓ Проверено'
                                    : result == false
                                        ? '↺ Повторить'
                                        : 'Проверить'),
                              ),
                            ),
                            if (result == true) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surfaceVariant,
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => aiStep.value = 3,
                                  child: const Text('Далее →'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Шаг 3: Выбор модели (dropdown + ручной ввод)
            _AnimatedStep(
              visible: step >= 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stepBadge(4, step >= 3),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Модель',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (step == 3)
                        GestureDetector(
                          onTap: () => aiStep.value = 2,
                          child: const Text('← Назад',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final templates = c.aiProvider.value.modelTemplates;
                    final currentModel = c.currentModel.value;
                    final dropdownValue =
                        templates.contains(currentModel) ? currentModel : null;
                    return DropdownButtonFormField<String>(
                      initialValue: dropdownValue,
                      dropdownColor: AppColors.surfaceVariant,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: 'Выберите модель...',
                      ),
                      items: [
                        ...templates.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m,
                                  style: const TextStyle(fontSize: 13)),
                            )),
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Ввести вручную...',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 13)),
                        ),
                      ],
                      onChanged: (m) {
                        if (m != null) {
                          c.saveModel(m);
                          modelCtr.text = m;
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  Obx(() {
                    final templates = c.aiProvider.value.modelTemplates;
                    final isCustom =
                        !templates.contains(c.currentModel.value);
                    return AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: isCustom
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Column(
                        children: [
                          TextField(
                            controller: modelCtr,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Название модели...',
                            ),
                            onSubmitted: (v) => c.saveModel(v),
                            onEditingComplete: () => c.saveModel(modelCtr.text),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceVariant,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => c.saveModel(modelCtr.text),
                              child: const Text('Сохранить модель'),
                            ),
                          ),
                        ],
                      ),
                      secondChild: const SizedBox.shrink(),
                    );
                  }),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        'Текущая: ${c.currentModel.value.isNotEmpty ? c.currentModel.value : "не выбрана"}',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _stepBadge(int number, bool active) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.textSecondary : AppColors.border,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: active ? AppColors.textPrimary : AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Индикатор прогресса шагов (4 шага: провайдер, ключ, проверка, модель)
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Провайдер', 'Ключ', 'Проверка', 'Модель'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i <= currentStep;
            final isLast = i == 3;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.textSecondary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (!isLast) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (i) {
            final active = i <= currentStep;
            return Expanded(
              child: Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active
                      ? AppColors.textSecondary
                      : AppColors.textHint,
                  fontSize: 9,
                  fontWeight:
                      i == currentStep ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Анимированный показ/скрытие шага
class _AnimatedStep extends StatelessWidget {
  final bool visible;
  final Widget child;
  const _AnimatedStep({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState:
          visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: child,
      secondChild: const SizedBox.shrink(),
    );
  }
}

// ─── Нормы питания КБЖУ ──────────────────────────────────────────────────────

// ─── Профиль тела ────────────────────────────────────────────────────────────

class _BodyProfileCard extends StatefulWidget {
  const _BodyProfileCard();

  @override
  State<_BodyProfileCard> createState() => _BodyProfileCardState();
}

class _BodyProfileCardState extends State<_BodyProfileCard> {
  late TextEditingController _heightCtr;
  late TextEditingController _ageCtr;
  late SettingsService _s;

  static const _activityLevels = [
    ('sedentary',  'Сидячий',       'Мало движения, офисная работа'),
    ('light',      'Лёгкий',        'Лёгкие упражнения 1-3 дня/нед'),
    ('moderate',   'Умеренный',     'Умеренные нагрузки 3-5 дней/нед'),
    ('active',     'Активный',      'Интенсивные нагрузки 6-7 дней/нед'),
    ('veryActive', 'Очень активный','Тяжёлый труд или 2× тренировки'),
  ];

  @override
  void initState() {
    super.initState();
    _s = Get.find<SettingsService>();
    _heightCtr = TextEditingController(text: _s.heightCm.toStringAsFixed(0));
    _ageCtr    = TextEditingController(text: _s.age.toString());
  }

  @override
  void dispose() {
    _heightCtr.dispose();
    _ageCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Пол
          const Text('Пол',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StatefulBuilder(builder: (_, setInner) {
            final gender = _s.gender;
            return Row(
              children: [
                _GenderBtn(label: '👨 Мужской', selected: gender == 'male', onTap: () async {
                  await _s.setGender('male');
                  setInner(() {});
                }),
                const SizedBox(width: 10),
                _GenderBtn(label: '👩 Женский', selected: gender == 'female', onTap: () async {
                  await _s.setGender('female');
                  setInner(() {});
                }),
              ],
            );
          }),
          const SizedBox(height: 14),

          // Рост + Возраст
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Рост', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _heightCtr,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '175', suffixText: 'см',
                  suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) {
                  final val = double.tryParse(v);
                  if (val != null && val > 0) _s.setHeightCm(val);
                },
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Возраст', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _ageCtr,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '25', suffixText: 'лет',
                  suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null && val > 0) _s.setAge(val);
                },
              ),
            ])),
          ]),
          const SizedBox(height: 14),

          // Уровень активности
          const Text('Уровень активности',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StatefulBuilder(builder: (_, setInner) {
            final current = _s.activityLevel;
            return Column(
              children: _activityLevels.map((entry) {
                final (key, label, desc) = entry;
                final selected = current == key;
                return GestureDetector(
                  onTap: () async {
                    await _s.setActivityLevel(key);
                    setInner(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surfaceVariant : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.textSecondary : AppColors.border,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        )),
                        Text(desc, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      ])),
                      if (selected)
                        const Icon(Icons.check, size: 16, color: AppColors.textSecondary),
                    ]),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _GenderBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.textSecondary : AppColors.border),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ))),
      ),
    ),
  );
}

// ─── Цель по весу ─────────────────────────────────────────────────────────────

class _WeightGoalCard extends StatefulWidget {
  const _WeightGoalCard();

  @override
  State<_WeightGoalCard> createState() => _WeightGoalCardState();
}

class _WeightGoalCardState extends State<_WeightGoalCard> {
  late TextEditingController _targetKgCtr;
  late TextEditingController _muscleGainCtr;
  late SettingsService _s;

  static const _goalTypes = [
    ('loss',     '🔻 Похудеть'),
    ('maintain', '⚖️ Поддерживать'),
    ('gain',     '💪 Набрать массу'),
  ];

  @override
  void initState() {
    super.initState();
    _s = Get.find<SettingsService>();
    _targetKgCtr = TextEditingController(
      text: _s.targetWeightKg > 0 ? _s.targetWeightKg.toStringAsFixed(1) : '',
    );
    _muscleGainCtr = TextEditingController(
      text: _s.muscleGainKg > 0 ? _s.muscleGainKg.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _targetKgCtr.dispose();
    _muscleGainCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: StatefulBuilder(builder: (_, setInner) {
        final currentGoal = _s.weightGoalType;
        final deadline = _s.weightGoalDeadline;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип цели
            const Text('Тип цели', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _goalTypes.map((entry) {
                final (key, label) = entry;
                final selected = currentGoal == key;
                return Expanded(child: GestureDetector(
                  onTap: () async {
                    await _s.setWeightGoalType(key);
                    setInner(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surfaceVariant : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? AppColors.textSecondary : AppColors.border),
                    ),
                    child: Center(child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ))),
                  ),
                ));
              }).toList(),
            ),

            if (currentGoal != 'maintain') ...[
              const SizedBox(height: 14),
              // Целевой вес
              const Text('Целевой вес', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _targetKgCtr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '70.0', suffixText: 'кг',
                  suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) {
                  final val = double.tryParse(v.replaceAll(',', '.'));
                  if (val != null && val > 0) _s.setTargetWeightKg(val);
                },
              ),

              // Желаемый прирост мышечной массы — только для gain
              if (currentGoal == 'gain') ...[
                const SizedBox(height: 14),
                const Text('Желаемый прирост мышц', style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Сколько кг мышечной массы хочу набрать',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: _muscleGainCtr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '5.0', suffixText: 'кг мышц',
                    suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val != null && val >= 0) _s.setMuscleGainKg(val);
                  },
                ),
              ],

              const SizedBox(height: 14),
              // Срок
              const Text('Срок достижения', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: deadline ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.textSecondary,
                          surface: AppColors.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    await _s.setWeightGoalDeadline(picked);
                    setInner(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      deadline != null
                          ? '${deadline.day}.${deadline.month.toString().padLeft(2, '0')}.${deadline.year}'
                          : 'Выбрать дату...',
                      style: TextStyle(
                        color: deadline != null ? AppColors.textPrimary : AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                    if (deadline != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await _s.setWeightGoalDeadline(null);
                          setInner(() {});
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                      ),
                    ],
                  ]),
                ),
              ),
              if (deadline != null) ...[
                const SizedBox(height: 10),
                Builder(builder: (_) {
                  final daysLeft = deadline.difference(DateTime.now()).inDays;
                  final targetKg = _s.targetWeightKg;
                  final currentKg = Get.find<StatisticsController>()
                      .weightEntries.isNotEmpty
                      ? Get.find<StatisticsController>().weightEntries.last.kg
                      : 70.0;
                  if (daysLeft <= 0 || targetKg == 0) return const SizedBox.shrink();
                  final delta = ((targetKg - currentKg) * 7700 / daysLeft).clamp(-500.0, 500.0);
                  final sign = delta >= 0 ? '+' : '';
                  final muscleKg = _s.muscleGainKg;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1A0D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E3A1E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'До цели $daysLeft дн.  $sign${delta.toStringAsFixed(0)} ккал/день',
                          style: const TextStyle(color: Color(0xFF81C784), fontSize: 12),
                        ),
                        if (currentGoal == 'gain' && muscleKg > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Прирост мышц: ${muscleKg.toStringAsFixed(1)} кг '
                            '(~${(muscleKg / (daysLeft / 30)).toStringAsFixed(2)} кг/мес)',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.mealPlan),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textSecondary),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🥗', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Создать AI-план питания',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── _WeightTrackingCard (синхронизирован со StatisticsController) ────────────

class _WeightTrackingCard extends StatefulWidget {
  const _WeightTrackingCard();
  @override
  State<_WeightTrackingCard> createState() => _WeightTrackingCardState();
}

class _WeightTrackingCardState extends State<_WeightTrackingCard> {
  late TextEditingController _kgCtr;
  late StatisticsController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.find<StatisticsController>();
    final last = _c.weightEntries.isNotEmpty ? _c.weightEntries.last.kg : 70.0;
    _kgCtr = TextEditingController(text: last.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _kgCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Текущий вес', style: TextStyle(
              color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _kgCtr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '70.0',
                  suffixText: 'кг',
                  suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final val = double.tryParse(_kgCtr.text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  _c.addWeightEntry(val);
                  setState(() {});
                }
              },
              child: const Text('Сохранить'),
            ),
          ]),
          const SizedBox(height: 14),
          Obx(() {
            final entries = _c.weightEntries;
            if (entries.isEmpty) {
              return const Center(
                child: Text('Нет данных', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              );
            }
            return SizedBox(
              height: 80,
              child: CustomPaint(
                painter: _MiniWeightChartPainter(List.from(entries)),
                size: const Size(double.infinity, 80),
              ),
            );
          }),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          const Text('История', style: TextStyle(
              color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Obx(() {
            final entries = _c.weightEntries.reversed.take(5).toList();
            if (entries.isEmpty) {
              return const Text('Нет записей', style: TextStyle(color: AppColors.textHint, fontSize: 12));
            }
            return Column(
              children: entries.map((e) {
                final label =
                    '${e.date.day.toString().padLeft(2, '0')}.${e.date.month.toString().padLeft(2, '0')}.${e.date.year}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                    const Spacer(),
                    Text('${e.kg.toStringAsFixed(1)} кг',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _c.removeWeightEntry(e.date);
                        setState(() {});
                      },
                      child: const Icon(Icons.close, size: 14, color: AppColors.textHint),
                    ),
                  ]),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniWeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  _MiniWeightChartPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    if (entries.length == 1) {
      final paint = Paint()..color = AppColors.textSecondary..strokeWidth = 2;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, paint);
      return;
    }
    final minKg = entries.map((e) => e.kg).reduce((a, b) => a < b ? a : b);
    final maxKg = entries.map((e) => e.kg).reduce((a, b) => a > b ? a : b);
    final range = (maxKg - minKg).clamp(0.5, double.infinity);

    Offset toOffset(int i) {
      final x = size.width * i / (entries.length - 1);
      final y = size.height - (size.height * (entries[i].kg - minKg) / range);
      return Offset(x, y.clamp(4.0, size.height - 4.0));
    }

    final linePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < entries.length; i++) {
      final prev = toOffset(i - 1);
      final curr = toOffset(i);
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.textSecondary;
    for (int i = 0; i < entries.length; i++) {
      canvas.drawCircle(toOffset(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MiniWeightChartPainter old) => old.entries.length != entries.length;
}

// ─── Нормы питания ────────────────────────────────────────────────────────────

class _NutritionGoalsCard extends StatefulWidget {
  @override
  State<_NutritionGoalsCard> createState() => _NutritionGoalsCardState();
}

class _NutritionGoalsCardState extends State<_NutritionGoalsCard> {
  final _settings = Get.find<SettingsService>();
  late final TextEditingController _calCtr;
  late final TextEditingController _protCtr;
  late final TextEditingController _fatCtr;
  late final TextEditingController _carbCtr;

  @override
  void initState() {
    super.initState();
    _calCtr = TextEditingController(text: _settings.dailyCalories.toStringAsFixed(0));
    _protCtr = TextEditingController(text: _settings.dailyProtein.toStringAsFixed(0));
    _fatCtr = TextEditingController(text: _settings.dailyFat.toStringAsFixed(0));
    _carbCtr = TextEditingController(text: _settings.dailyCarbs.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _calCtr.dispose();
    _protCtr.dispose();
    _fatCtr.dispose();
    _carbCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await _settings.setDailyCalories(double.tryParse(_calCtr.text) ?? _settings.dailyCalories);
    await _settings.setDailyProtein(double.tryParse(_protCtr.text) ?? _settings.dailyProtein);
    await _settings.setDailyFat(double.tryParse(_fatCtr.text) ?? _settings.dailyFat);
    await _settings.setDailyCarbs(double.tryParse(_carbCtr.text) ?? _settings.dailyCarbs);
    Get.snackbar(
      'Сохранено',
      'Нормы питания обновлены',
      backgroundColor: const Color(0xFF1E1E1E),
      colorText: const Color(0xFFFFFFFF),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дневные нормы КБЖУ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Используются в плане питания для отображения прогресса',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _GoalField(label: '🔥 Калории', unit: 'ккал', controller: _calCtr),
              const SizedBox(width: 8),
              _GoalField(label: '🥩 Белки', unit: 'г', controller: _protCtr),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _GoalField(label: '🧈 Жиры', unit: 'г', controller: _fatCtr),
              const SizedBox(width: 8),
              _GoalField(label: '🍞 Углеводы', unit: 'г', controller: _carbCtr),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _save,
              child: const Text('Сохранить нормы'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;

  const _GoalField({
    required this.label,
    required this.unit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: const TextStyle(
                  color: AppColors.textHint, fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Настройки Должника ───────────────────────────────────────────────────────

class _DebtorSettingsCard extends StatelessWidget {
  final _settings = Get.find<SettingsService>();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Экран «Должник»',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text(
                'Показывать просроченные задачи при запуске приложения',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            value: _settings.debtorEnabled,
            onChanged: (v) => _settings.setDebtorEnabled(v),
          ),
          const Divider(color: AppColors.border, height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AI-подсказки в «Должнике»',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text(
                'Анализировать просрочки и давать советы через AI',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
            value: _settings.debtorAiHints,
            onChanged: (v) => _settings.setDebtorAiHints(v),
          ),
        ],
      ),
    );
  }
}

// ─── Экспорт / Импорт ────────────────────────────────────────────────────────

class _ExportImportCard extends StatefulWidget {
  @override
  State<_ExportImportCard> createState() => _ExportImportCardState();
}

class _ExportImportCardState extends State<_ExportImportCard> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      await ExportImportService().exportToJson();
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _doImport() async {
    setState(() => _importing = true);
    try {
      final result = await ExportImportService().importFromJson();
      if (!mounted) return;
      Get.snackbar(
        result.success ? '✅ Импорт завершён' : '❌ Ошибка импорта',
        result.message,
        backgroundColor:
            result.success ? const Color(0xFF1A3A1A) : const Color(0xFF3A1A1A),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Резервная копия данных (JSON)',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Экспортируются задачи, теги, продукты питания и сценарии',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _exporting ? null : _doExport,
                  icon: _exporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary))
                      : const Icon(Icons.upload_outlined, size: 16),
                  label: Text(_exporting ? 'Экспорт...' : 'Экспорт'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _importing ? null : _doImport,
                  icon: _importing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary))
                      : const Icon(Icons.download_outlined, size: 16),
                  label: Text(_importing ? 'Импорт...' : 'Импорт'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ При импорте уже существующие записи пропускаются',
            style: TextStyle(color: AppColors.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Dev Tools Card ──────────────────────────────────────────────────────────

class _DevToolsCard extends StatefulWidget {
  @override
  State<_DevToolsCard> createState() => _DevToolsCardState();
}

class _DevToolsCardState extends State<_DevToolsCard> {
  bool _expanded = false;
  bool _generatingReport = false;
  String _devStatus = '';

  Future<void> _sendTestReport() async {
    await NotificationService().sendTestReportNotification();
    setState(() => _devStatus = '✅ Уведомление-отчёт отправлено');
  }

  Future<void> _sendTestReminder() async {
    await NotificationService().sendTestReminderNotification();
    setState(() => _devStatus = '✅ Уведомление-напоминание отправлено');
  }

  Future<void> _createTestFoods() async {
    final foodCtrl = Get.find<FoodItemController>();
    final repo = Get.find<FoodItemRepository>();

    final testFoods = [
      FoodItemModel(
        id: 'test_food_1',
        name: 'Молоко (стакан 200мл)',
        description: 'Цельное молоко 3.2%',
        calories: 60,
        macros: MacroNutrients(proteins: 3.2, fats: 3.2, carbs: 4.7),
      ),
      FoodItemModel(
        id: 'test_food_2',
        name: 'Макароны Mac & Cheese',
        description: 'Варёные макароны с сыром',
        calories: 350,
        macros: MacroNutrients(proteins: 12.0, fats: 14.0, carbs: 45.0),
      ),
      FoodItemModel(
        id: 'test_food_3',
        name: 'Омлет из 3 яиц',
        description: 'Омлет на сливочном масле',
        calories: 220,
        macros: MacroNutrients(proteins: 18.0, fats: 16.0, carbs: 2.0),
      ),
      FoodItemModel(
        id: 'test_food_4',
        name: 'Стейк индейки 150г',
        description: 'Запечённое филе индейки',
        calories: 165,
        macros: MacroNutrients(proteins: 30.0, fats: 4.0, carbs: 0.0),
      ),
      FoodItemModel(
        id: 'test_food_5',
        name: 'Греческий йогурт 200г',
        description: 'Натуральный без добавок',
        calories: 130,
        macros: MacroNutrients(proteins: 12.0, fats: 4.0, carbs: 8.0),
      ),
      FoodItemModel(
        id: 'test_food_6',
        name: 'Гречка варёная 200г',
        description: 'Гречневая крупа отварная',
        calories: 254,
        macros: MacroNutrients(proteins: 9.4, fats: 2.2, carbs: 49.0),
      ),
      FoodItemModel(
        id: 'test_food_7',
        name: 'Куриная грудка 150г',
        description: 'Отварное филе курицы',
        calories: 165,
        macros: MacroNutrients(proteins: 31.0, fats: 3.6, carbs: 0.0),
      ),
      FoodItemModel(
        id: 'test_food_8',
        name: 'Банан',
        description: 'Средний банан ~120г',
        calories: 105,
        macros: MacroNutrients(proteins: 1.3, fats: 0.4, carbs: 27.0),
      ),
    ];

    int added = 0;
    for (final food in testFoods) {
      if (repo.getById(food.id) == null) {
        await repo.save(food);
        added++;
      }
    }
    foodCtrl.loadItems();
    setState(() => _devStatus = '✅ Добавлено $added тестовых продуктов');
  }

  Future<void> _getTestReport() async {
    setState(() {
      _generatingReport = true;
      _devStatus = '⏳ Генерирую тестовый отчёт...';
    });
    try {
      final result = await ReportService().generateDailyReport(
        date: DateTime.now(),
      );
      if (result != null) {
        setState(() => _devStatus = '✅ Отчёт получен и сохранён в раздел «Отчёты»');
        Get.dialog(
          AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF3A3A3A)),
            ),
            title: const Text('🧪 Тестовый отчёт',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            content: SingleChildScrollView(
              child: Text(result,
                  style: const TextStyle(
                      color: Color(0xFFB0B0B0), fontSize: 14, height: 1.5)),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Закрыть',
                    style: TextStyle(color: Color(0xFF888888))),
              ),
            ],
          ),
        );
      } else {
        setState(() =>
            _devStatus = '❌ Не удалось получить отчёт. Проверьте AI-настройки.');
      }
    } catch (e) {
      setState(() => _devStatus = '❌ Ошибка: $e');
    } finally {
      setState(() => _generatingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A2A00)),
      ),
      child: Column(
        children: [
          // Заголовок — кнопка раскрытия
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1500),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(11),
                  bottom: _expanded ? Radius.zero : const Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const Text('🛠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Для разработчиков',
                      style: TextStyle(
                        color: Color(0xFFFFCC00),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFFFFCC00), size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Контент
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DevButton(
                    icon: '📋',
                    label: 'Журнал логов',
                    onTap: () => Get.toNamed(AppRoutes.logs),
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    icon: '🔔',
                    label: 'Тестовое уведомление (отчёт)',
                    onTap: _sendTestReport,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    icon: '⏰',
                    label: 'Тестовое уведомление (напоминание)',
                    onTap: _sendTestReminder,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    icon: '🍽️',
                    label: 'Создать тестовые продукты',
                    onTap: _createTestFoods,
                  ),
                  const SizedBox(height: 8),
                  _DevButton(
                    icon: '🤖',
                    label: _generatingReport
                        ? 'Генерирую...'
                        : 'Получить тестовый AI-отчёт',
                    onTap: _generatingReport ? null : _getTestReport,
                  ),
                  if (_devStatus.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _devStatus,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const _DevButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onTap != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16,
                color: onTap != null
                    ? AppColors.textSecondary
                    : AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
