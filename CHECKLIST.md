# NiTe — Чеклист улучшений

> Связанный документ: [IMPROVEMENTS.md](./IMPROVEMENTS.md)  
> Последнее обновление: 2026-02-22

---

## 🔴 Высокий приоритет — критические логические баги

- [x] **П.11.2** — Исправить сохранение `foodItemGrams` в `TaskModel`: заменить `foodGrams: double` на `Map<String, double> foodItemGrams` + обновить `TaskFormController.saveTask()` + пересчёт в `StatisticsController`
- [x] **П.11.5 / П.4** — Единый источник КБЖУ-целей: убрать `dailyCalorieTarget` и др. из `MealPlanModel`, читать из `SettingsService`; синхронизировать `_DayProgressBar` и `_NutritionGoalsCard`
- [x] **П.1** — Вынести профиль тела (`gender`, `heightCm`, `age`) из `StatisticsController` в `SettingsService` + карточка «Профиль тела» в `SettingsScreen`

---

## 🔵 Рефакторинг / технический долг — унификация UI

- [x] **П.12.11** — Вынести стиль `AlertDialog` в `ThemeData.dialogTheme` в `AppTheme`
- [x] **П.12.9** — Создать `lib/core/utils/nutrition_calculator.dart` (`NutritionCalculator`)
- [x] **П.12.2** — Создать `lib/presentation/widgets/common/app_confirm_dialog.dart`
- [x] **П.12.3** — Создать `lib/presentation/widgets/common/app_empty_state.dart`
- [x] **П.12.4** — Создать `lib/presentation/widgets/common/section_header.dart`
- [x] **П.12.1** — Создать `lib/presentation/widgets/nutrition/macro_nutrition_row.dart`
- [x] **П.12.5** — Создать `lib/presentation/widgets/common/labeled_number_field.dart`
- [x] **П.12.8** — Создать `lib/presentation/widgets/common/labeled_progress_bar.dart`
- [x] **П.12.6** — Вынести `_ActionBtn` в `lib/presentation/widgets/common/selection_action_button.dart`
- [x] **П.12.7** — Создать `lib/presentation/widgets/common/settings_switch_tile.dart`
- [x] **П.12.10** — Реорганизовать структуру папки `lib/presentation/widgets/` по подпапкам

---

## 🟡 Средний приоритет — улучшение UX и данных

- [x] **П.2** — Добавить `WeightGoalModel` (`goalType`, `targetWeightKg`, `goalDeadline`) + расчёт суточного дефицита/профицита в `StatisticsController`
- [x] **П.7** — Добавить `ActivityLevel` enum в `UserProfileModel`; показывать выбор в настройках
- [x] **П.8** — Передавать данные КБЖУ и веса в промпт AI-отчёта; добавить snapshot-поля в `AiReportModel`
- [x] **П.5** — Добавить `foodItemIds` / `foodItemGrams` в `ScenarioTask`; переносить при `applyScenario()`

---

## 🟢 Низкий приоритет — расширение функционала

- [x] **П.9** — Добавить в `FoodItemModel`: `servingSizeGrams`, `isFavorite`, `category`
- [x] **П.10** — Ввести `DailyMealLog` модель для истории фактического питания по дням
- [x] **П.6** — Рефакторинг `SettingsService`: разбить ключи на логические группы (AI / UserProfile / Nutrition / UI / System)

---

## ✅ Итог

> Последнее обновление: 2026-02-22 (сессия 2)

### Выполнено
- Исправлено сохранение `foodItemGrams` в `TaskModel` — теперь граммаж по каждому продукту сохраняется корректно
- `MealPlanController` читает цели КБЖУ из `SettingsService` — единый источник
- `StatisticsController` читает профиль тела из `SettingsService`, убран хардкод `1.55`
- `SettingsService` расширен: `ActivityLevel`, `WeightGoal`, `targetWeightKg`, `weightGoalDeadline`
- `ScenarioTask` поддерживает привязку продуктов (еда сохраняется в шаблонах)
- `FoodItemModel` получил `servingSizeGrams`, `isFavorite`, `category`
- AI-отчёт теперь включает данные КБЖУ, вес и цель по весу
- Созданы 8 переиспользуемых UI-компонентов (`MacroNutritionRow`, `AppConfirmDialog`, `AppEmptyState`, `SectionHeader`, `LabeledNumberField`, `LabeledProgressBar`, `NutritionCalculator`, `dialogTheme`)
- Hive-адаптеры перегенерированы через `build_runner`
- **[Сессия 2]** Создан `SelectionActionButton` — вынесен из `_ActionBtn` в `food_library_screen.dart`
- **[Сессия 2]** Создан `SettingsSwitchTile` — переиспользуемый тайл переключателя для настроек
- **[Сессия 2]** Реорганизована структура `lib/presentation/widgets/` по подпапкам (`common/`, `food/`, `task/`, `nutrition/`)
- **[Сессия 2]** Создана модель `DailyMealLog` + репозиторий `DailyMealLogRepository` (история питания по дням)
- **[Сессия 2]** Рефакторинг `SettingsService`: все ключи вынесены в типизированные группы (`_AiKeys`, `_ProfileKeys`, `_WeightGoalKeys`, `_NutritionKeys`, `_UiKeys`, `_SystemKeys`)

### Осталось на будущее

#### 🔴 Критические баги (логика)
- [x] **П.A** — Заменить `_calcNutrition()` в `StatisticsController` на `NutritionCalculator.fromTask()` (сейчас использует устаревший `foodGrams` вместо `foodItemGrams[id]`)
- [x] **П.B** — Исправить `ScenarioController.applyScenario()`: передавать `foodItemIds` и `foodItemGrams` из `ScenarioTask` в `TaskController.createTask()` — сейчас данные еды из шаблонов теряются

#### 🟡 Средний приоритет — UI/UX
- [x] **П.7.UI** — UI для выбора `ActivityLevel` в настройках (карточка «Профиль тела» → уровень активности)
- [x] **П.2.UI** — UI для `WeightGoal` (цель, срок) в настройках (карточка «Цель по весу»)
- [x] **П.8.snap** — Добавить snapshot-поля (`caloriesConsumed`, `weightKg`, `tdee`) в `AiReportModel` + передавать КБЖУ и вес в промпт AI-отчёта

#### 🔵 Рефакторинг — унификация UI
- [x] **П.12.2r** — Заменить копипаст диалогов в `food_library_screen` на `AppConfirmDialog`
- [x] **П.12.3r** — Заменить пустые состояния в `food_library_screen` на `AppEmptyState`
- [x] **П.12.4r** — Заменить локальные `_SectionHeader` в `statistics_screen.dart` и `settings_screen.dart` на общий `SectionHeader` из `lib/presentation/widgets/common/`

#### ✅ Выполнено ранее
- [x] Зарегистрировать `DailyMealLogAdapter` в Hive при инициализации приложения
- [x] Открыть `dailyMealLogBox` в `main.dart` и запустить `build_runner` для генерации `.g.dart`
- [x] Исправлены ошибки компиляции в `statistics_screen.dart` (убраны `.value` на getter-полях профиля тела)
