import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../repositories/ai_report_repository.dart';
import '../repositories/task_repository.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  AiReportRepository get _reportRepo => Get.find<AiReportRepository>();

  // ─── Генерация ежедневного отчёта ─────────────────────────────────────────

  Future<String?> generateDailyReport({DateTime? date}) async {
    log.info('ReportService', 'Генерация ежедневного отчёта...');
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);
    if (apiKey.isEmpty) {
      log.warning('ReportService', 'API ключ не задан — отчёт пропущен');
      return null;
    }

    final targetDate = date ?? DateTime.now();
    final taskRepo = Get.find<TaskRepository>();
    final tasks = taskRepo.getByDate(targetDate);

    final completed = tasks.where((t) => t.isCompleted).toList();
    final pending = tasks.where((t) => !t.isCompleted).toList();

    final service = AiService(
      provider: provider,
      apiKey: apiKey,
      model: settings.getModel(provider),
    );

    final day = targetDate;
    final months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final dateLabel = '${day.day} ${months[day.month]} ${day.year}';

    final completedList = completed.isEmpty
        ? 'нет выполненных задач'
        : completed.map((t) => '• ${t.name} (приоритет: ${t.priority})').join('\n');
    final pendingList = pending.isEmpty
        ? 'все задачи выполнены'
        : pending.map((t) => '• ${t.name}').join('\n');

    final prompt = '''
Ты — персональный ассистент по продуктивности. Дай краткий итог дня ($dateLabel).

Выполненные задачи:
$completedList

Невыполненные задачи:
$pendingList

Напиши 2-3 предложения: оцени день, похвали или мягко подбодри. Заверши одним коротким советом на завтра.
Ответ на русском языке, дружелюбно. Не более 150 слов.
''';

    try {
      final content = await service.sendRaw(prompt, maxTokens: 250);
      if (content == null || content.isEmpty) return null;

      // Сохраняем
      await _reportRepo.saveDailyReport(date: targetDate, content: content);

      // Уведомление
      final short = content.length > 100 ? '${content.substring(0, 100)}...' : content;
      await NotificationService().showDailyReportNotification(short, targetDate);
      log.success('ReportService', 'Ежедневный отчёт сгенерирован и отправлен');
      return content;
    } on Exception catch (e, st) {
      log.error('ReportService', 'Ошибка ежедневного отчёта: $e\n$st');
      return null;
    }
  }

  // ─── Генерация еженедельного отчёта ──────────────────────────────────────

  Future<String?> generateWeeklyReport({DateTime? weekStart}) async {
    log.info('ReportService', 'Генерация еженедельного отчёта...');
    final settings = Get.find<SettingsService>();
    final provider = settings.aiProvider;
    final apiKey = settings.getApiKey(provider);
    if (apiKey.isEmpty) {
      log.warning('ReportService', 'API ключ не задан — недельный отчёт пропущен');
      return null;
    }

    final taskRepo = Get.find<TaskRepository>();
    final now = weekStart ?? _lastWeekStart();
    final tasks = taskRepo.getByWeek(now);
    final completed = tasks.where((t) => t.isCompleted).toList();

    final service = AiService(
      provider: provider,
      apiKey: apiKey,
      model: settings.getModel(provider),
    );

    final tasksList = completed.isEmpty
        ? 'задач не выполнено'
        : completed.map((t) => '• ${t.name} (приоритет: ${t.priority})').join('\n');

    final prompt = '''
Ты — персональный коуч по продуктивности. На основе выполненных задач за прошлую неделю дай оценку продуктивности и совет.

Выполненные задачи:
$tasksList

Напиши 3-5 предложений: оцени неделю, выдели сильные стороны, дай один конкретный совет на следующую неделю.
Ответ на русском языке, дружелюбно и конструктивно. Не более 200 слов.
''';

    try {
      final content = await service.sendRaw(prompt, maxTokens: 350);
      if (content == null || content.isEmpty) return null;

      await _reportRepo.saveWeeklyReport(weekStart: now, content: content);

      final short = content.length > 100 ? '${content.substring(0, 100)}...' : content;
      await NotificationService().showWeeklyReportNotification(short);
      log.success('ReportService', 'Еженедельный отчёт сгенерирован и отправлен');
      return content;
    } on Exception catch (e, st) {
      log.error('ReportService', 'Ошибка еженедельного отчёта: $e\n$st');
      return null;
    }
  }

  // ─── Планировщик уведомлений ──────────────────────────────────────────────

  /// Планирует ежедневный отчёт в конце дня (22:00)
  Future<void> scheduleDailyReport() async {
    await NotificationService().scheduleDailyReport();
  }

  /// Отменяет ежедневный отчёт
  Future<void> cancelDailyReport() async {
    await NotificationService().cancelDailyReport();
  }

  // ─── Доступ к репозиторию ─────────────────────────────────────────────────

  AiReportRepository get repository => _reportRepo;

  // ─── helpers ──────────────────────────────────────────────────────────────

  DateTime _lastWeekStart() {
    final now = DateTime.now();
    // Сначала находим текущий понедельник, затем откатываемся на 7 дней назад
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    return DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
  }
}
