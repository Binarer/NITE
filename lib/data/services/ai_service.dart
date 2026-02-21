import 'package:dio/dio.dart';
import 'settings_service.dart';

/// Универсальный AI-клиент, поддерживающий несколько провайдеров
/// через OpenAI-совместимый API (chat/completions) и Gemini REST API.
class AiService {
  final AiProvider provider;
  final String apiKey;
  final String model;

  late final Dio _dio;

  AiService({
    required this.provider,
    required this.apiKey,
    required this.model,
  }) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  /// Возвращает null если соединение успешно, иначе текст ошибки
  Future<String?> testConnection() async {
    try {
      await _sendMessage('Ответь одним словом: OK', maxTokens: 5);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) return 'Неверный API ключ ($status)';
      if (status == 429) return 'Превышен лимит запросов';
      if (status != null) return 'Ошибка сервера: $status';
      return 'Нет соединения с ${provider.displayName}';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  /// Оценивает приоритет задачи (0-5)
  Future<int?> estimatePriority({
    required String taskName,
    required String description,
    required List<String> tagNames,
    String? timeInfo,
  }) async {
    final prompt = '''
Оцени приоритет задачи по шкале от 0 до 5, где:
0 = нет приоритета, 5 = максимальный приоритет.

Задача: $taskName
${description.isNotEmpty ? 'Описание: $description' : ''}
${tagNames.isNotEmpty ? 'Категории: ${tagNames.join(', ')}' : ''}
${timeInfo != null ? 'Время: $timeInfo' : ''}

Ответь ТОЛЬКО одним числом от 0 до 5. Никаких объяснений.
''';
    try {
      final response = await _sendMessage(prompt, maxTokens: 5);
      final cleaned = response.trim().replaceAll(RegExp(r'[^0-5]'), '');
      if (cleaned.isEmpty) return null;
      final value = int.tryParse(cleaned[0]);
      return (value != null && value >= 0 && value <= 5) ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// Генерирует еженедельный ретроспективный отчёт
  Future<String> generateWeeklyRetrospective(List<dynamic> completedTasks) async {
    final tasksList = completedTasks.map((t) {
      return '• ${t.name} (приоритет: ${t.priority})';
    }).join('\n');

    final prompt = '''
Ты — помощник по продуктивности. Дай краткую оценку продуктивности за прошлую неделю и совет на следующую.

Выполненные задачи:
$tasksList

Ответ на русском языке, не более 200 слов.
''';
    return await _sendMessage(prompt, maxTokens: 300);
  }

  /// Создаёт план питания для набора мышечной массы
  Future<String> generateNutritionPlan({
    required double weightKg,
    required List<Map<String, dynamic>> foodLibrary,
    required String goal,
    double heightCm = 175,
    int age = 25,
    String gender = 'male',
  }) async {
    final foodList = foodLibrary.map((f) =>
        '• ${f['name']}: ${f['calories']} ккал/100г, Б:${f['proteins']}г Ж:${f['fats']}г У:${f['carbs']}г'
    ).join('\n');

    // Расчёт TDEE по формуле Миффлина-Сент-Жора
    final double bmr = gender == 'male'
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    final double tdee = bmr * 1.55; // умеренная активность
    final double targetCalories = goal.contains('набор') ? tdee + 300 : tdee - 300;

    final genderRu = gender == 'male' ? 'мужчина' : 'женщина';

    final prompt = '''
Составь план питания на неделю (ПН-ВС) для цели: $goal.

Данные пользователя:
- Пол: $genderRu
- Возраст: $age лет
- Рост: ${heightCm.toStringAsFixed(0)} см
- Вес: ${weightKg.toStringAsFixed(1)} кг
- Расчётный TDEE: ${tdee.toStringAsFixed(0)} ккал/день
- Целевая калорийность: ${targetCalories.toStringAsFixed(0)} ккал/день

Доступные продукты из библиотеки:
$foodList

Требования:
- Используй ТОЛЬКО продукты из списка выше.
- Суточная калорийность должна быть близка к ${targetCalories.toStringAsFixed(0)} ккал.
- В рационе каждого дня должно быть НЕ МЕНЕЕ 5 различных приёмов пищи (завтрак, перекус 1, обед, перекус 2, ужин).
- Каждый приём пищи — отдельная строка с указанием продукта и граммовки.
- Для набора массы — повышенное потребление белка (минимум 1.8г на кг веса = ${(weightKg * 1.8).toStringAsFixed(0)}г белка в день).

Для каждого дня укажи приёмы пищи в формате:
ДЕНЬ: [название дня]
ЗАВТРАК: [продукт] [граммы]г
ПЕРЕКУС 1: [продукт] [граммы]г
ОБЕД: [продукт] [граммы]г
ПЕРЕКУС 2: [продукт] [граммы]г
УЖИН: [продукт] [граммы]г
ИТОГО: [калории] ккал | Б: [белки]г | Ж: [жиры]г | У: [углеводы]г

Ответ на русском языке. Только план, без лишних объяснений.
''';
    return await _sendMessage(prompt, maxTokens: 1500);
  }

  // ─── Публичный raw метод ─────────────────────────────────────────────────

  /// Отправляет произвольный промпт, возвращает null при ошибке
  Future<String?> sendRaw(String prompt, {int maxTokens = 500}) async {
    try {
      return await _sendMessage(prompt, maxTokens: maxTokens);
    } catch (_) {
      return null;
    }
  }

  // ─── Внутренние методы ───────────────────────────────────────────────────

  Future<String> _sendMessage(String prompt, {int maxTokens = 500}) async {
    if (provider == AiProvider.gemini) {
      return await _sendGemini(prompt, maxTokens);
    }
    return await _sendOpenAiCompatible(prompt, maxTokens);
  }

  /// OpenAI-совместимый API (Mistral, OpenAI, DeepSeek, Qwen, Anthropic*, Groq)
  Future<String> _sendOpenAiCompatible(String prompt, int maxTokens) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    // Anthropic требует дополнительный заголовок
    if (provider == AiProvider.anthropic) {
      headers['anthropic-version'] = '2023-06-01';
    }

    final body = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': maxTokens,
      'temperature': 0.3,
    };

    final response = await _dio.post(
      '${provider.apiBaseUrl}/chat/completions',
      data: body,
      options: Options(headers: headers),
    );

    return response.data['choices'][0]['message']['content'] as String? ?? '';
  }

  /// Google Gemini REST API
  Future<String> _sendGemini(String prompt, int maxTokens) async {
    final effectiveModel = model.isNotEmpty ? model : 'gemini-2.0-flash';
    final url =
        '${provider.apiBaseUrl}/models/$effectiveModel:generateContent?key=$apiKey';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': 0.3,
      },
    };

    final response = await _dio.post(
      url,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return response.data['candidates'][0]['content']['parts'][0]['text']
            as String? ??
        '';
  }
}
