import 'package:dio/dio.dart';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';

class MistralService {
  final Dio _dio;
  String _apiKey;

  MistralService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.mistralBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  void updateApiKey(String key) {
    _apiKey = key;
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Проверяет работоспособность API ключа — возвращает null если OK, иначе текст ошибки.
  Future<String?> testConnection() async {
    if (_apiKey.isEmpty) return 'API ключ не задан';
    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        data: {
          'model': AppConstants.mistralModel,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 1,
        },
      );
      if (response.statusCode == 200) return null;
      return 'Ошибка: код ${response.statusCode}';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return 'Неверный API ключ (401)';
      if (e.response?.statusCode == 429) return 'Превышен лимит запросов (429)';
      return 'Ошибка сети: ${e.message}';
    } catch (e) {
      return 'Неизвестная ошибка: $e';
    }
  }

  /// Оценивает приоритет задачи (0–5) через Mistral AI.
  Future<int> evaluateTaskPriority(TaskModel task, {List<TaskModel>? dayTasks}) async {
    final context = dayTasks != null && dayTasks.isNotEmpty
        ? '\nДругие задачи на этот день: ${dayTasks.map((t) => '"${t.name}" (приоритет ${t.priority})').join(', ')}.'
        : '';

    final prompt = '''
Ты помощник по планированию задач. Оцени приоритет следующей задачи по шкале от 0 до 5, где:
0 — нет приоритета, 1 — очень низкий, 2 — низкий, 3 — средний, 4 — высокий, 5 — максимальный.

Задача: "${task.name}"
${task.description.isNotEmpty ? 'Описание: ${task.description}' : ''}
${task.startTimeString != null ? 'Время: ${task.startTimeString}${task.endTimeString != null ? ' – ${task.endTimeString}' : ''}' : ''}$context

Ответь ТОЛЬКО одной цифрой от 0 до 5. Без пояснений.
''';

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        data: {
          'model': AppConstants.mistralModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 5,
          'temperature': 0.2,
        },
      );
      final content = response.data['choices'][0]['message']['content'] as String;
      final trimmed = content.trim();
      final value = int.tryParse(trimmed) ?? 0;
      return value.clamp(0, 5);
    } on DioException catch (e) {
      throw Exception('Ошибка Mistral API: ${e.message}');
    }
  }

  /// Формирует еженедельную ретроспективу на основе выполненных задач.
  Future<String> generateWeeklyRetrospective(List<TaskModel> completedTasks) async {
    if (completedTasks.isEmpty) {
      return 'На прошлой неделе задачи не были выполнены.';
    }

    final tasksSummary = completedTasks
        .map((t) => '- "${t.name}" (приоритет ${t.priority})')
        .join('\n');

    final prompt = '''
Ты персональный коуч по продуктивности. На основе списка выполненных задач за прошлую неделю дай краткую (3–5 предложений) оценку продуктивности и один конкретный совет на следующую неделю.

Выполненные задачи:
$tasksSummary

Отвечай на русском языке, дружелюбно и конструктивно.
''';

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        data: {
          'model': AppConstants.mistralModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        },
      );
      return response.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      throw Exception('Ошибка Mistral API: ${e.message}');
    }
  }
}
