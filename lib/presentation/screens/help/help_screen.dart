import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

// ─── Разделы памятки ─────────────────────────────────────────────────────────

class _Section {
  final String emoji;
  final String title;
  final List<String> items;
  const _Section({required this.emoji, required this.title, required this.items});
}

const _sections = [
  _Section(
    emoji: '📅',
    title: 'Главный экран',
    items: [
      'Просматривайте задачи по неделям — свайп влево/вправо переключает недели',
      'Режимы «Неделя» и «День» — переключатель в боковом меню',
      'Перетаскивайте карточки задач между днями (drag & drop)',
      'Фильтруйте задачи по тегам — строка фильтров под навигатором недели',
      'Нажмите «+» чтобы добавить новую задачу',
    ],
  ),
  _Section(
    emoji: '✅',
    title: 'Задачи',
    items: [
      'У каждой задачи есть название, описание, теги, время и приоритет (0–5)',
      'Приоритет визуализируется цветной полоской слева на карточке',
      'Нажмите на задачу для предпросмотра, кнопка «Редактировать» внизу откроет форму',
      'Включите «Оценить приоритет через AI» — AI сам предложит приоритет',
      'Задача с тегом «Еда» может быть привязана к карточке из библиотеки',
      'Добавляйте подзадачи — чекбоксы внутри задачи',
    ],
  ),
  _Section(
    emoji: '🍽️',
    title: 'Библиотека питания',
    items: [
      'Храните карточки блюд с фото, КБЖУ (на 100г) и описанием',
      'При создании задачи с тегом «Еда» выберите карточку из библиотеки',
      'Укажите граммы потребления — КБЖУ пересчитается автоматически',
      'Статистика питания отображается в разделе «Статистика»',
    ],
  ),
  _Section(
    emoji: '🥗',
    title: 'План питания',
    items: [
      'Открывается через боковое меню → «План питания»',
      'Распределяйте блюда из библиотеки по приёмам пищи: завтрак, обед, ужин, перекус',
      'Прогресс-бары КБЖУ показывают сколько осталось до вашей нормы',
      'Нормы калорий и БЖУ задаются в Настройках → «Нормы питания» или через кнопку 🎯 в AppBar',
      'Нормы синхронизированы: изменения в настройках сразу отражаются в плане',
      'Кнопка «Сохранить как сценарий» создаёт шаблон недели с задачами приёмов пищи',
    ],
  ),
  _Section(
    emoji: '🎬',
    title: 'Сценарии',
    items: [
      'Сценарий — шаблон недели с задачами для быстрого планирования',
      'Создайте сценарий «Рабочая неделя», «Тренировочная неделя» и т.д.',
      'Задачи в сценарии привязаны к дню недели (ПН–ВС), но не к дате',
      'Нажмите «Применить» — задачи создадутся на текущую или следующую неделю',
    ],
  ),
  _Section(
    emoji: '🤖',
    title: 'Искусственный интеллект',
    items: [
      'Поддерживаются: Mistral, OpenAI, Gemini, DeepSeek, Qwen, Claude, Groq',
      'Настройте провайдера и API ключ в разделе «Настройки → ИИ» — 4 шага',
      'AI оценивает приоритет задач по запросу пользователя',
      'Ежедневный отчёт приходит в 22:00 — итоги дня и совет на завтра',
      'Еженедельный отчёт — каждый понедельник в 12:00',
    ],
  ),
  _Section(
    emoji: '📊',
    title: 'Статистика',
    items: [
      'Просматривайте КБЖУ за день или неделю',
      'Ведите учёт веса — добавляйте записи и смотрите динамику',
      'Профиль тела (рост, возраст, пол) помогает AI давать точные советы',
    ],
  ),
  _Section(
    emoji: '📋',
    title: 'Отчёты',
    items: [
      'Все AI-отчёты сохраняются в разделе «Отчёты» в боковом меню',
      'Вкладка «Ежедневные» — итоги каждого дня',
      'Вкладка «Еженедельные» — итоги каждой недели',
      'Нажмите на карточку отчёта, чтобы развернуть полный текст',
    ],
  ),
  _Section(
    emoji: '🃏',
    title: 'Должник',
    items: [
      'Открывается автоматически при запуске если есть просроченные задачи',
      'Доступен в боковом меню → «Должник»',
      'Свайп вправо (→) — перенести задачу на сегодня (время подбирается автоматически)',
      'Свайп влево (←) — выбрать новую дату через календарь',
      'Свайп вверх (↑) — пометить задачу как выполненную (убрать из списка)',
      'Свайп вниз (↓) — оставить задачу на исходном дне',
      'Кнопка «Всё сегодня» — перенести все просрочки на сегодня одним нажатием',
      'AI-подсказка анализирует просрочки и предлагает группировку задач',
      'Включить/выключить в Настройках → «Должник»',
    ],
  ),
  _Section(
    emoji: '💾',
    title: 'Экспорт и импорт',
    items: [
      'Доступно в Настройках → «Данные»',
      'Экспорт сохраняет все задачи, теги, продукты питания и сценарии в JSON-файл',
      'Кнопка «Экспорт» открывает системный шаринг — отправьте в Telegram, облако или почту',
      'Кнопка «Импорт» — выберите JSON-файл для восстановления данных',
      'При импорте уже существующие записи пропускаются (дубликаты не создаются)',
      'Используйте для переноса данных на новый телефон или резервного копирования',
    ],
  ),
  _Section(
    emoji: '⚙️',
    title: 'Настройки',
    items: [
      'Управляйте тегами: добавляйте, изменяйте цвет и эмодзи',
      'Настройте сторону бокового меню (слева или справа)',
      'Включите уведомления — напоминания о задачах с кнопками «Выполнить» и «+15 мин» прямо в шторке',
      'Настройте нормы КБЖУ — используются в плане питания',
      'Настройте часовой пояс для точного времени уведомлений',
      'Раздел «Должник» — включить/выключить экран просрочек и AI-подсказки',
      'Раздел «Данные» — экспорт и импорт всех данных в JSON',
    ],
  ),
];

// ─── Экран памятки ────────────────────────────────────────────────────────────

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;
  final _scrollController = ScrollController();
  final List<GlobalKey> _keys = List.generate(_sections.length, (i) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

void _scrollToSection(int index) {
  setState(() => _expandedIndex = index);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    final renderObj = ctx.findRenderObject() as RenderBox?;
    if (renderObj == null || !renderObj.attached) return;
    final scrollBox = _scrollController.position.context.storageContext
        .findRenderObject() as RenderBox?;
    if (scrollBox == null) return;
    final localPos = renderObj.localToGlobal(
      Offset.zero,
      ancestor: scrollBox,
    );
    final target = (_scrollController.offset + localPos.dy - 120).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Памятка')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Быстрая навигация по разделам
          _QuickNav(
            sections: _sections,
            onTap: _scrollToSection,
            expandedIndex: _expandedIndex,
          ),
          const SizedBox(height: 16),

          // Разделы
          ...List.generate(_sections.length, (i) {
            final s = _sections[i];
            final isExpanded = _expandedIndex == i;
            return Padding(
              key: _keys[i],
              padding: const EdgeInsets.only(bottom: 10),
              child: _HelpSectionCard(
                emoji: s.emoji,
                title: s.title,
                items: s.items,
                isExpanded: isExpanded,
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? null : i;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 24),
          const _DeveloperPhotoCard(),
          const SizedBox(height: 16),
          const _ContactsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Быстрая навигация ────────────────────────────────────────────────────────

class _QuickNav extends StatelessWidget {
  final List<_Section> sections;
  final void Function(int) onTap;
  final int? expandedIndex;

  const _QuickNav({
    required this.sections,
    required this.onTap,
    required this.expandedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'РАЗДЕЛЫ',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sections.length, (i) {
              final s = sections[i];
              final isActive = expandedIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.surfaceVariant
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.textSecondary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.emoji,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        s.title,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Карточка раздела (сворачиваемая) ────────────────────────────────────────

class _HelpSectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> items;
  final bool isExpanded;
  final VoidCallback onTap;

  const _HelpSectionCard({
    required this.emoji,
    required this.title,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? AppColors.textSecondary : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Фото разработчика ───────────────────────────────────────────────────────

class _DeveloperPhotoCard extends StatelessWidget {
  const _DeveloperPhotoCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              color: AppColors.surface,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/DeveloperPhoto.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Разработчик',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Контакты ─────────────────────────────────────────────────────────────────

class _ContactsSection extends StatelessWidget {
  const _ContactsSection();

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (_) {
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть ссылку: $url',
        backgroundColor: const Color(0xFF2A2A2A),
        colorText: const Color(0xFFFFFFFF),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tgHandle = AppConstants.contactTelegram.replaceFirst('@', '');
    final tgUrl = 'https://t.me/$tgHandle';
    final ghUrl = AppConstants.contactGithub;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📬', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                'Связаться с разработчиком',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: '✈️',
            label: 'Telegram',
            value: AppConstants.contactTelegram,
            onTap: () => _launchUrl(tgUrl),
          ),
          const SizedBox(height: 8),
          _ContactRow(
            icon: '💻',
            label: 'GitHub',
            value: AppConstants.contactGithub,
            onTap: () => _launchUrl(ghUrl),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
