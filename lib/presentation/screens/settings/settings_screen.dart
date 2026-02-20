import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/food_item_model.dart';
import '../../../data/repositories/ai_report_repository.dart';
import '../../../data/repositories/food_item_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/settings_service.dart';
import '../../controllers/food_item_controller.dart';
import '../../controllers/settings_controller.dart';

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

    // Если провайдер уже выбран и ключ сохранён — сразу на шаг 2
    if (_c.currentApiKey.value.isNotEmpty) {
      _aiStep.value = _c.keyTestResult.value == true ? 2 : 1;
    }

    ever(_c.aiProvider, (_) {
      _apiKeyCtr.text = _c.currentApiKey.value;
      _modelCtr.text = _c.currentModel.value;
      // При смене провайдера сбрасываем на шаг ключа
      _aiStep.value = _c.currentApiKey.value.isNotEmpty ? 1 : 0;
    });
    ever(_c.currentApiKey, (v) {
      if (_apiKeyCtr.text != v) _apiKeyCtr.text = v;
    });
    ever(_c.currentModel, (v) {
      if (_modelCtr.text != v) _modelCtr.text = v;
    });
    // После успешной проверки ключа — переходим к выбору модели
    ever(_c.keyTestResult, (result) {
      if (result == true) _aiStep.value = 2;
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
          _SectionHeader('Искусственный интеллект'),
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
          _SectionHeader('Теги'),
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
          _SectionHeader('Уведомления'),
          _SettingsCard(
            child: Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Еженедельная ретроспектива',
                      style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text(
                      'Каждый понедельник в 12:00 — отчёт о продуктивности',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                  value: _c.notificationsEnabled.value,
                  onChanged: _c.setNotificationsEnabled,
                )),
          ),
          const SizedBox(height: 20),

          // --- Часовой пояс ---
          _SectionHeader('Часовой пояс'),
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
          _SectionHeader('Боковое меню'),
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

          // --- Для разработчиков ---
          _SectionHeader('Для разработчиков'),
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
                Text('v1.0.0',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
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

// ─── AI Setup Card (шаговый: провайдер → ключ → модель) ─────────────────────

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
              visible: true, // всегда виден
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
                    value: c.hasProviderBeenSelected.value
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

            // Шаг 1: Ввод и проверка ключа
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
                      const Text('API ключ',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
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
                                  : () => c.saveApiKey(apiKeyCtr.text),
                              child: c.isSavingKey.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textSecondary))
                                  : const Text('Сохранить'),
                            )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    c.keyTestResult.value == true
                                        ? const Color(0xFF1A3A1A)
                                        : c.keyTestResult.value == false
                                            ? const Color(0xFF3A1A1A)
                                            : AppColors.surfaceVariant,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: c.isTestingKey.value
                                  ? null
                                  : () => c.testApiKey(apiKeyCtr.text),
                              child: c.isTestingKey.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textSecondary))
                                  : const Text('Проверить'),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Obx(() {
                    if (c.keyTestMessage.value.isEmpty) {
                      return Text(
                        'Получите ключ на сайте ${c.aiProvider.value.displayName}',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                      );
                    }
                    return Text(
                      c.keyTestMessage.value,
                      style: TextStyle(
                        color: c.keyTestResult.value == true
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                        fontSize: 11,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Шаг 2: Выбор модели (dropdown + ручной ввод)
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
                      const Text('Модель',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final templates = c.aiProvider.value.modelTemplates;
                    final currentModel = c.currentModel.value;
                    // Если текущая модель не в шаблонах — выбираем null (ручной ввод)
                    final dropdownValue =
                        templates.contains(currentModel) ? currentModel : null;
                    return DropdownButtonFormField<String>(
                      value: dropdownValue,
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
                  // Поле ручного ввода модели
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

// Индикатор прогресса шагов
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= currentStep;
        final isLast = i == 2;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: active ? AppColors.textSecondary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (!isLast) const SizedBox(width: 4),
            ],
          ),
        );
      }),
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
