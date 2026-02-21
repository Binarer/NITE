class AppConstants {
  // Hive box names
  static const String tasksBox = 'tasks';
  static const String tagsBox = 'tags';
  static const String foodItemsBox = 'food_items';
  static const String scenariosBox = 'scenarios';
  static const String settingsBox = 'settings';
  static const String reportsBox = 'reports';
  static const String mealPlansBox = 'meal_plans';

  // Hive type IDs
  static const int tagTypeId = 0;
  static const int taskTypeId = 1;
  static const int foodItemTypeId = 2;
  static const int scenarioTypeId = 3;
  static const int scenarioTaskTypeId = 4;
  static const int macroNutrientsTypeId = 5;
  static const int subtaskTypeId = 6;
  static const int aiReportTypeId = 7;
  static const int mealPlanTypeId = 8;
  static const int mealEntryTypeId = 9;

  // Contacts (from .env concept — set your values here)
  static const String contactTelegram = '@wasitfallen';
  static const String contactGithub = 'https://github.com/Binarer';

  // Settings keys
  static const String settingsMistralApiKey = 'mistral_api_key';
  static const String settingsTimezone = 'timezone';
  static const String settingsMenuSide = 'menu_side'; // 'left' или 'right'
  static const String settingsAiProvider = 'ai_provider';
  static const String settingsAiModel = 'ai_model';

  // Mistral API
  static const String mistralBaseUrl = 'https://api.mistral.ai/v1';
  static const String mistralModel = 'mistral-small-latest';

  // Default timezone
  static const String defaultTimezone = 'Asia/Yekaterinburg';

  // Weekdays (0 = Monday, 6 = Sunday)
  static const List<String> weekdayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  static const List<String> weekdayFullNames = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
}
