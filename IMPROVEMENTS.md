# NiTe — Анализ проблем и план улучшений

> Дата: 2026-02-22  
> Статус: Черновик для обсуждения

---

## 1. Профиль пользователя (UserProfile) — вынести в настройки

### Проблема
Поля `heightCm`, `age`, `gender`, `newWeightKg` живут прямо в `StatisticsController` и сохраняются
через `SettingsService` вручную. При этом:
- Экран статистики **дублирует** UI для ввода этих данных рядом с диаграммами, хотя это явно настроечная информация.
- В `MealPlanModel` хранятся свои `dailyCalorieTarget / dailyProteinTarget / dailyFatTarget / dailyCarbTarget`,
  а в `SettingsService` — отдельные поля «Nutrition goals». Одни и те же цели хранятся **в двух местах**.
- В `_DayProgressBar` экрана плана питания цели берутся из `SettingsService`, а не из `MealPlanModel`.
  Несоответствие порождает ситуацию, когда пользователь меняет цель в плане, но прогресс-бар не меняется (и наоборот).

### Решение
1. **Создать модель `UserProfileModel`** (Hive) с полями:
   ```dart
   String gender;           // 'male' | 'female'
   double heightCm;
   int age;
   double activityFactor;   // 1.2 / 1.375 / 1.55 / 1.725 / 1.9
   ```
2. Вынести ввод профиля в **Настройки → «Профиль тела»** (отдельная карточка).
3. **Удалить** соответствующие поля из `StatisticsController`; контроллер просто читает `UserProfileModel`.
4. **Единый источник КБЖУ-целей**: вычислять рекомендованные нормы из `UserProfileModel` (BMR × activity),
   хранить их в одном месте — `SettingsService` (или отдельной модели `NutritionGoalsModel`).
   `MealPlanModel` должен **ссылаться** на эти цели, а не дублировать их.

---

## 2. Цель по весу и план набора/похудения

### Проблема
В экране статистики показывается:
- TDEE (расход калорий)
- `targetCaloriesForGain = TDEE + 300` (жёстко захардкожено)

Но нигде нет:
- Какова **цель** пользователя (набор / снижение / поддержание)?
- Сколько **килограмм** нужно набрать/сбросить?
- За **какой срок**?
- Не существует расчёта дефицита калорий для похудения.

### Решение
Добавить в `UserProfileModel` (или отдельную `WeightGoalModel`):
```dart
enum WeightGoalType { gain, loss, maintain }

WeightGoalType goalType;
double targetWeightKg;        // целевой вес
DateTime goalDeadline;        // срок достижения
```
- Автоматически рассчитывать суточный профицит/дефицит:
  `dailyDelta = (targetWeightKg - currentWeightKg) * 7700 / daysLeft`
  (ограничить диапазоном −500..+500 ккал/сут для безопасности)
- Показывать в статистике: «До цели X кг, осталось Y дней, нужно ±Z ккал/день»
- Кнопку «Создать план питания» AI запускать с учётом этой цели.

---

## 3. Потребление еды из задач не учитывается в статистике корректно

### Проблема
`TaskModel` содержит `foodItemIds` и `foodGrams`, а `StatisticsController._calcNutrition()`
уже суммирует КБЖУ из выполненных задач с тегом «Еда». **Но:**
- Считаются задачи с **одним** `foodItemId` (устаревшее поле), а новое поле `foodItemIds`
  может не обрабатываться одинаково.
- `foodGrams` — одно значение на всю задачу. Если к задаче привязано несколько продуктов,
  граммаж разделить между ними невозможно (у каждого должно быть своё значение).
- В `TaskDetailScreen` КБЖУ **показывается**, но только в контексте детали задачи.
  В суммарной дневной статистике пользователь не видит, что именно там посчитано.
- Нет разделения: «что уже съедено» (выполненные задачи) vs «что запланировано» (невыполненные).

### Решение
1. **Исправить модель**: вместо единого `foodGrams: double` хранить `Map<String, double> foodItemGrams`
   (ключ = `foodItemId`, значение = граммы). Уже частично реализовано в `TaskFormController.foodItemGrams`,
   но **не сохраняется** в `TaskModel`.
   ```dart
   @HiveField(16)
   Map<String, double> foodItemGrams;   // <foodItemId, grams>
   ```
2. **Удалить устаревшее** поле `foodItemId` (HiveField 10) после миграции данных.
3. В `StatisticsController._calcNutrition()` итерировать по `foodItemIds` и брать граммаж
   из `foodItemGrams[id] ?? 100.0`.
4. В статистике добавить разбивку: отдельная строка «Из задач (фактически съедено)»
   vs «По плану питания».

---

## 4. Рассинхронизация плана питания и статистики

### Проблема
- `MealPlanModel` — шаблон на неделю (не привязан к конкретным датам).
- `StatisticsController` считает реальное потребление из **задач**, а не из плана.
- Пользователь в плане питания видит одни цифры, в статистике — другие, и связи между ними нет.
- В экране плана питания прогресс-бар показывает «план vs цель», но не «факт vs цель».

### Решение
Определить чёткую семантику двух экранов:

| Экран | Назначение |
|---|---|
| **План питания** | Шаблон рациона на неделю. Редактируется пользователем. Используется AI для генерации задач. |
| **Статистика** | Фактическое потребление из **выполненных** задач с тегом «Еда». |

- Убрать из экрана плана питания ввод «Дневных целей» — они теперь в Настройках → Профиль.
- Добавить в статистику секцию «Факт vs План»: для выбранного дня показывать план
  (из `MealPlanModel` по соответствующему weekday) рядом с фактическими данными из задач.
- Прогресс-бары в статистике использовать цели из `UserProfileModel` / `SettingsService`.

---

## 5. Сценарии — еда не сохраняется при генерации плана

### Проблема
`ScenarioTask` не содержит полей для еды (`foodItemIds`, `foodItemGrams`).
Когда AI генерирует план питания и создаёт сценарий, задачи типа «Еда» создаются
без привязки к конкретным продуктам — только с тегом «Еда» в названии.

### Решение
Добавить в `ScenarioTask`:
```dart
@HiveField(9)
List<String> foodItemIds;

@HiveField(10)
Map<String, double> foodItemGrams;
```
И при применении сценария (`ScenarioController.applyScenario()`) переносить эти поля в `TaskModel`.

---

## 6. Настройки — дублирование и отсутствие структуры

### Проблема
`SettingsService` хранит в одном боксе Hive гетерогенный набор значений:
AI-ключи, уведомления, часовой пояс, КБЖУ-цели, сторона меню, параметры тела —
всё в «плоском» key-value виде без какой-либо типизации.

### Решение
Разбить настройки на логические группы (можно оставить один Hive-бокс, но сгруппировать ключи):

```
SettingsService
├── AI          : provider, apiKey(per-provider), model(per-provider)
├── UserProfile : gender, heightCm, age, activityFactor
├── WeightGoal  : goalType, targetWeightKg, goalDeadline
├── Nutrition   : calorie/protein/fat/carb targets (единый источник)
├── UI          : menuSide
└── System      : timezone, notifications flags, reminderMinutes, reportHour
```

Рассмотреть создание отдельных Hive-моделей для групп с частыми обращениями.

---

## 7. ActivityFactor — отсутствует выбор уровня активности

### Проблема
В `StatisticsController` жёстко захардкожен коэффициент `1.55` (умеренная активность):
```dart
double get tdee => bmr * 1.55;
```
Пользователь не может указать свой уровень активности.

### Решение
Добавить в `UserProfileModel`:
```dart
enum ActivityLevel { sedentary, light, moderate, active, veryActive }
```
С коэффициентами `[1.2, 1.375, 1.55, 1.725, 1.9]`.
Показывать выбор в Настройках → Профиль тела, с кратким описанием каждого уровня.

---

## 8. Отчёт AI — отсутствует контекст питания

### Проблема
`AiReportModel` хранит только текстовый `content`. При генерации дневного/недельного отчёта
AI получает только задачи. Данные о питании (КБЖУ, вес) не передаются в промпт.

### Решение
При генерации отчёта передавать в `AiService`:
- Суммарное КБЖУ за период (из `StatisticsController._calcNutrition`)
- Текущий вес и динамику (из `weightEntries`)
- Цель по весу и норму калорий (из `UserProfileModel`)

Опционально: добавить в `AiReportModel` snapshot-поля:
```dart
@HiveField(5)
double? caloriesConsumed;
@HiveField(6)
double? weightKg;
```
чтобы исторические отчёты оставались корректными даже после изменения данных.

---

## 9. Модель FoodItemModel — недостающие поля

### Проблема
`FoodItemModel` хранит КБЖУ на 100 г, но:
- Нет поля `servingSizeGrams` (стандартная порция). Пользователь каждый раз вводит граммаж вручную.
- Нет `barcode` для сканирования.
- Нет `category` (молочное, мясо, злаки…) для фильтрации в библиотеке.
- Нет `isFavorite` для быстрого доступа.

### Решение (минимум):
```dart
@HiveField(7)
double servingSizeGrams;    // стандартная порция (по умолчанию 100)

@HiveField(8)
bool isFavorite;

@HiveField(9)
String? category;
```

---

## 10. MealPlanModel — нет привязки к конкретным датам / история

### Проблема
`MealPlanModel` — шаблон на «абстрактную» неделю (ключи `0_breakfast`…`6_dinner`).
Нет возможности посмотреть, что было в плане **на прошлой неделе**, нет истории изменений плана.

### Решение
Рассмотреть две модели:
- **`MealPlanTemplate`** — текущая модель, шаблон на неделю (редактируется в экране плана).
- **`DailyMealLog`** — запись фактического потребления за конкретный день (дата + список `MealEntry`).
  Создаётся автоматически при выполнении задач с тегом «Еда» **или** вручную.

`StatisticsController` работает с `DailyMealLog`, а не с задачами напрямую.

---

## 11. Мелкие проблемы

| # | Файл | Проблема |
|---|---|---|
| 11.1 | `TaskModel` | Устаревшее поле `foodItemId` (HiveField 10) не удалено, конфликтует с `foodItemIds` |
| 11.2 | `TaskFormController` | `foodItemGrams` — `RxMap` в контроллере, но не сохраняется в `TaskModel.foodItemGrams` (в `saveTask` использует единый `foodGrams`) |
| 11.3 | `MealPlanRepository.getActive()` | Возвращает первый по дате создания план — нет явного флага «активный план» |
| 11.4 | `StatisticsScreen` | Кнопка «Создать план питания» создаёт `ScenarioModel`, но никак не связывает его с `MealPlanModel` |
| 11.5 | `SettingsScreen._NutritionGoalsCard` | КБЖУ-цели в настройках и КБЖУ-цели в `MealPlanModel` — два разных места, нет синхронизации |
| 11.6 | `ScenarioTask` | Нет полей для еды, хотя сценарий может содержать задачи-приёмы пищи |
| 11.7 | `StatisticsController` | Захардкоженный коэффициент активности `1.55` без возможности изменения |

---

## 12. Унификация UI — переиспользуемые компоненты

### Проблема
Анализ кода показывает многочисленные случаи копипаста одних и тех же паттернов
в разных экранах без выноса в общий виджет.

---

### 12.1 Карточка КБЖУ (`MacroNutritionCard`)

**Где дублируется:**
- `food_detail_screen.dart` → `_NutritionCard` + `_MacroItem`
- `task_form_screen.dart` → `_MacroChip` (в `_FoodItemTile`)
- `task_detail_screen.dart` → инлайн-строка КБЖУ в секции продуктов
- `meal_plan_screen.dart` → `_MealBlock` макро-строка
- `statistics_screen.dart` → `_MacroCell`

Каждый раз заново верстается строка «Белки / Жиры / Углеводы» с цветами и единицами.

**Решение:** создать `lib/presentation/widgets/macro_nutrition_row.dart`:
```dart
/// Универсальная строка/карточка КБЖУ.
/// [style] — compact (одна строка), card (с заголовком и разделителями), chips
class MacroNutritionRow extends StatelessWidget {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final MacroNutritionStyle style;
  final String? perLabel;   // "на 100г", "за день" и т.д.
  ...
}

enum MacroNutritionStyle { compact, card, chips }
```

---

### 12.2 Диалог подтверждения удаления (`AppConfirmDialog`)

**Где дублируется:**
- `food_form_screen.dart` → `AlertDialog` «Удалить продукт?»
- `food_library_screen.dart` → `AlertDialog` «Удалить X продуктов?» и «Скрыть продукты?»
- `task_form_screen.dart` → `_DeleteConfirmDialog`
- `scenario_list_screen.dart` → инлайн `AlertDialog` удаления сценария

Во всех случаях одна и та же структура: `backgroundColor: AppColors.surface`, `shape` с `AppColors.border`,
кнопки «Отмена» + действие, иногда деструктивный цвет.

**Решение:** создать `lib/presentation/widgets/app_confirm_dialog.dart`:
```dart
Future<bool> showAppConfirmDialog({
  required String title,
  String? content,
  String confirmLabel = 'Подтвердить',
  bool destructive = false,
}) async { ... }
```

---

### 12.3 Пустое состояние экрана (`AppEmptyState`)

**Где дублируется:**
- `food_library_screen.dart` → `🍽️` + «Библиотека пуста» / «Ничего не найдено»
- `scenario_list_screen.dart` → эмодзи + текст пустого списка
- `reports_screen.dart` → текст/иконка отсутствия отчётов
- `home_screen.dart` → текст пустого дня/недели

**Решение:** создать `lib/presentation/widgets/app_empty_state.dart`:
```dart
class AppEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;   // кнопка «Добавить первый...»
  ...
}
```

---

### 12.4 Секционный заголовок (`SectionHeader`)

**Где дублируется:**
- `app_sidebar.dart` → `Text('ВИД', style: TextStyle(color: AppColors.textHint, fontSize: 10, letterSpacing: 1.2))`
- `app_sidebar.dart` → то же для «ПРОФИЛЬ» и «РАЗДЕЛЫ»
- `settings_screen.dart` → аналогичные заголовки групп
- `statistics_screen.dart` → `_SectionHeader`
- `meal_plan_screen.dart` → заголовки приёмов пищи

**Решение:** создать `lib/presentation/widgets/section_header.dart`:
```dart
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;  // кнопка справа
  final EdgeInsets padding;
  ...
}
```

---

### 12.5 Поле ввода числа с лейблом (`LabeledNumberField`)

**Где дублируется:**
- `meal_plan_screen.dart` → `_TargetField` (лейбл + узкое числовое поле)
- `food_form_screen.dart` → `_macroField` (цвет + хинт + числовой ввод)
- `statistics_screen.dart` → поля роста, веса, возраста
- `settings_screen.dart` → `_NutritionGoalsCard` поля калорий/белков/жиров/углеводов

Паттерн: `Column(Text(label), SizedBox, TextField(keyboardType: number))` повторяется 10+ раз.

**Решение:** создать `lib/presentation/widgets/labeled_number_field.dart`:
```dart
class LabeledNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final Color? accentColor;
  final double? min;
  final double? max;
  final bool decimal;
  final String? suffix;   // "кг", "см", "ккал"
  ...
}
```

---

### 12.6 Кнопка действия в панели выделения (`SelectionActionBar`)

**Где дублируется:**
- `food_library_screen.dart` → `_ActionBtn` (иконка + подпись + контейнер с бордером)
- Аналогичная кнопка-действие нужна/будет нужна в любом списке с multi-select

**Решение:** вынести `_ActionBtn` в `lib/presentation/widgets/selection_action_button.dart`
и сделать его параметризованным (иконка, лейбл, цвет, onTap).

---

### 12.7 Тайл настройки с переключателем (`SettingsSwitchTile`)

**Где дублируется:**
- `settings_screen.dart` → множество `SwitchListTile` / `ListTile` + `Switch` с одинаковым стилем
  (фон `AppColors.surface`, бордер `AppColors.border`, лейбл + подзаголовок + Switch)

**Решение:** создать `lib/presentation/widgets/settings_switch_tile.dart`:
```dart
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  ...
}
```

---

### 12.8 Прогресс-бар с лейблом (`LabeledProgressBar`)

**Где дублируется:**
- `meal_plan_screen.dart` → `_DayProgressBar` (4 строки: калории + Б + Ж + У, каждая = лейбл + LinearProgressIndicator + значение)
- `statistics_screen.dart` → аналогичные прогресс-бары в `_DailyNutritionCard`

**Решение:** создать `lib/presentation/widgets/labeled_progress_bar.dart`:
```dart
class LabeledProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;      // "ккал", "г"
  final bool showValues;
  ...
}
```

---

### 12.9 Общий миксин расчёта КБЖУ (`NutritionCalculatorMixin`)

**Где дублируется логика:**
- `meal_plan_controller.dart` → `_sumMacros()`, `macrosForMeal()`, `macrosForDay()`
- `statistics_controller.dart` → `_calcNutrition()` (та же формула: `calories * grams / 100`)
- `task_detail_screen.dart` → инлайн-расчёт КБЖУ по продуктам задачи
- `task_form_screen.dart` → `_FoodItemTile` считает КБЖУ инлайн

Формула одна: `nutrientValue = baseValuePer100g * grams / 100`.

**Решение:** создать `lib/core/utils/nutrition_calculator.dart`:
```dart
class NutritionCalculator {
  static NutritionTotals fromFoodItem(FoodItemModel item, double grams) { ... }
  static NutritionTotals sumEntries(List<MealEntry> entries, FoodItemRepository repo) { ... }
  static NutritionTotals sumTaskFoods(TaskModel task, FoodItemRepository repo) { ... }
}
```
Все контроллеры и виджеты используют этот класс вместо копипаста формул.

---

### 12.10 Структура папки `widgets`

Текущая структура `lib/presentation/widgets/` содержит только 6 файлов, многие переиспользуемые
компоненты живут как приватные классы внутри экранов. Предложение по реорганизации:

```
lib/presentation/widgets/
├── common/
│   ├── app_confirm_dialog.dart       # 12.2
│   ├── app_empty_state.dart          # 12.3
│   ├── section_header.dart           # 12.4
│   ├── labeled_number_field.dart     # 12.5
│   ├── labeled_progress_bar.dart     # 12.8
│   ├── selection_action_button.dart  # 12.6
│   └── settings_switch_tile.dart    # 12.7
├── nutrition/
│   └── macro_nutrition_row.dart      # 12.1
├── food/
│   ├── food_item_card.dart           # уже есть
│   └── food_item_tile.dart           # вынести из task_form_screen
├── task/
│   └── task_card.dart                # уже есть
└── app_sidebar.dart                  # уже есть
```

---

### 12.11 Дублирование `AlertDialog` стиля — вынести константу

Во всех диалогах повторяется:
```dart
AlertDialog(
  backgroundColor: AppColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: AppColors.border),
  ),
  ...
)
```

**Решение:** добавить в `AppTheme`:
```dart
static ShapeBorder get dialogShape => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  side: const BorderSide(color: AppColors.border),
);
```
И прописать `dialogTheme: DialogThemeData(backgroundColor: AppColors.surface, shape: dialogShape)`
прямо в `ThemeData`, тогда все `AlertDialog` подхватят стиль автоматически без копипаста.

---

## Приоритизированный план работ

### 🔴 Высокий приоритет (критические логические баги)
1. Исправить сохранение `foodItemGrams` в `TaskModel` — заменить `foodGrams: double` на `Map<String, double>` (п. 3, 11.2)
2. Единый источник КБЖУ-целей — убрать дублирование между `MealPlanModel` и `SettingsService` (п. 4, 11.5)
3. Вынести профиль тела из `StatisticsController` в Настройки (п. 1)

### 🟡 Средний приоритет (улучшение UX и данных)
4. Добавить цель по весу (`WeightGoalModel`) с расчётом дефицита/профицита (п. 2)
5. Добавить выбор уровня активности `ActivityLevel` (п. 7)
6. Передавать данные питания и веса в промпт AI-отчёта (п. 8)
7. Добавить поля еды в `ScenarioTask` и применять при разворачивании сценария (п. 5)

### 🟢 Низкий приоритет (расширение функционала)
8. `FoodItemModel`: порция по умолчанию, категория, избранное (п. 9)
9. История плана питания / `DailyMealLog` (п. 10)
10. Рефакторинг `SettingsService` на логические группы (п. 6)

### 🔵 Рефакторинг / технический долг (унификация UI)
11. Создать `NutritionCalculator` — убрать дублирование формул КБЖУ (п. 12.9)
12. Вынести `AlertDialog` стиль в `ThemeData.dialogTheme` (п. 12.11)
13. Создать `MacroNutritionRow` виджет (п. 12.1)
14. Создать `AppConfirmDialog` / `AppEmptyState` / `SectionHeader` (п. 12.2–12.4)
15. Создать `LabeledNumberField` и `LabeledProgressBar` (п. 12.5, 12.8)
16. Реорганизовать структуру папки `widgets/` (п. 12.10)
