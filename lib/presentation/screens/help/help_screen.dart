import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Памятка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpSection(
            emoji: '📅',
            title: 'Главный экран',
            items: [
              'Просматривайте задачи по неделям — свайп влево/вправо переключает недели',
              'Режимы «Неделя» и «День» — переключатель в верхней части экрана',
              'Перетаскивайте карточки задач между днями (drag & drop)',
              'Фильтруйте задачи по тегам — строка фильтров под переключателем',
              'Нажмите «+» чтобы добавить новую задачу',
            ],
          ),
          _HelpSection(
            emoji: '✅',
            title: 'Задачи',
            items: [
              'У каждой задачи есть название, описание, теги, время и приоритет (0–5)',
              'Приоритет визуализируется цветной полоской слева на карточке',
              'Включите «Оценить приоритет через AI» — AI сам предложит приоритет',
              'Задача с тегом «Еда» может быть привязана к карточке из библиотеки',
              'Добавляйте подзадачи — чекбоксы внутри задачи',
            ],
          ),
          _HelpSection(
            emoji: '🍽️',
            title: 'Библиотека питания',
            items: [
              'Храните карточки блюд с фото, КБЖУ (на 100г) и описанием',
              'При создании задачи с тегом «Еда» выберите карточку из библиотеки',
              'Укажите граммы потребления — КБЖУ пересчитается автоматически',
              'Статистика питания отображается в разделе «Статистика»',
            ],
          ),
          _HelpSection(
            emoji: '🎬',
            title: 'Сценарии',
            items: [
              'Сценарий — шаблон недели с задачами для быстрого планирования',
              'Создайте сценарий «Рабочая неделя», «Тренировочная неделя» и т.д.',
              'Задачи в сценарии привязаны к дню недели (ПН–ВС), но не к дате',
              'Нажмите «Применить» — задачи создадутся на текущую или следующую неделю',
            ],
          ),
          _HelpSection(
            emoji: '🤖',
            title: 'Искусственный интеллект',
            items: [
              'Поддерживаются: Mistral, OpenAI, Gemini, DeepSeek, Qwen, Claude, Groq',
              'Настройте провайдера и API ключ в разделе «Настройки → ИИ»',
              'AI оценивает приоритет задач по запросу пользователя',
              'Ежедневный отчёт приходит в 22:00 — итоги дня и совет на завтра',
              'Еженедельный отчёт — каждый понедельник в 12:00',
              'AI составляет план питания на неделю из блюд вашей библиотеки',
            ],
          ),
          _HelpSection(
            emoji: '📊',
            title: 'Статистика',
            items: [
              'Просматривайте КБЖУ за день или неделю',
              'Ведите учёт веса — добавляйте записи и смотрите динамику',
              'AI генерирует план питания для набора массы на основе вашей библиотеки',
            ],
          ),
          _HelpSection(
            emoji: '📋',
            title: 'Отчёты',
            items: [
              'Все AI-отчёты сохраняются в разделе «Отчёты» в боковом меню',
              'Вкладка «Ежедневные» — итоги каждого дня',
              'Вкладка «Еженедельные» — итоги каждой недели',
              'Нажмите на карточку отчёта, чтобы развернуть полный текст',
            ],
          ),
          _HelpSection(
            emoji: '⚙️',
            title: 'Настройки',
            items: [
              'Управляйте тегами: добавляйте, изменяйте цвет и эмодзи',
              'Настройте сторону бокового меню (слева или справа)',
              'Включите уведомления для ежедневных и еженедельных отчётов',
              'Настройте часовой пояс для точного времени уведомлений',
            ],
          ),
          SizedBox(height: 24),
          _DeveloperPhotoCard(),
          SizedBox(height: 16),
          _ContactsSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.emoji,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
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
                errorBuilder: (_, __, ___) => const Icon(
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
        // Fallback — открыть в WebView внутри приложения
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
    // Формируем URL для Telegram
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
            const Icon(Icons.open_in_new,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
