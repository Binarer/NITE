# NiTe — Список исправлений и задач

## 1. Кнопка проверки API ключа Mistral в настройках
**Файл:** `lib/presentation/screens/settings/settings_screen.dart`  
**Проблема:** После сохранения ключа нет визуальной проверки — работает ли ключ вообще.  
**Решение:** Добавить кнопку "Проверить ключ", которая делает тестовый запрос к Mistral API и показывает результат (✅ Ключ рабочий / ❌ Ошибка: ...).  
**Затронутые файлы:**
- `lib/presentation/screens/settings/settings_screen.dart` — добавить кнопку и индикатор результата
- `lib/presentation/controllers/settings_controller.dart` — добавить метод `testMistralApiKey()`
- `lib/data/services/mistral_service.dart` — добавить метод `testConnection()`

---

## 2. Не работает оценка приоритета от AI в форме задачи
**Файл:** `lib/presentation/controllers/task_form_controller.dart`  
**Проблема:** `hasInternet` всегда `false` из-за DNS lookup блокируется на Android (нет разрешения INTERNET в AndroidManifest, или `InternetAddress.lookup` не работает как ожидается).  
**Решение:**
- Заменить DNS lookup на реальный HTTP ping к Mistral API (лёгкий GET-запрос с таймаутом)
- Также убедиться что в `AndroidManifest.xml` есть `<uses-permission android:name="android.permission.INTERNET"/>`
**Затронутые файлы:**
- `lib/presentation/controllers/task_form_controller.dart` — переписать `_checkConnectivity()`
- `android/app/src/main/AndroidManifest.xml` — проверить/добавить INTERNET permission

---

## 3. Нет кнопки перехода в библиотеку еды на главном экране / хедере
**Проблема:** Библиотека продуктов доступна только из формы создания задачи с тегом "Еда". Нет отдельной кнопки для прямого входа.  
**Решение:** Добавить кнопку "Еда" (иконка 🍽️) в шапку главного экрана рядом со "Сценарии" и "Настройки".  
**Затронутые файлы:**
- `lib/presentation/screens/home/home_screen.dart` — добавить `_HeaderButton` для библиотеки еды

---

## 4. Dropdown фильтр задач по тегам (только реально присутствующие теги)
**Проблема:** На главном экране нет фильтрации задач по тегам.  
**Решение:**
- Добавить dropdown/chip-фильтр на главном экране
- Фильтр показывает только теги, которые **реально есть** в задачах текущей недели (режим "неделя") или выбранного дня (режим "день")
- При выборе тега — показываются только задачи с этим тегом
- Кнопка сброса фильтра ("Все")
**Затронутые файлы:**
- `lib/presentation/controllers/home_controller.dart` — добавить `selectedFilterTagId (RxnString)`, метод `setTagFilter()`, геттер `availableTagsForCurrentView`
- `lib/presentation/screens/home/home_screen.dart` — добавить строку фильтров под навигатором недели
- `lib/presentation/widgets/week_day_column.dart` — принимать `filterTagId` и фильтровать задачи

---

## 5. Переключение между режимами "День" и "Неделя"
**Проблема:** Сейчас только режим "Неделя" (7 колонок). Нет режима просмотра одного дня.  
**Решение:**
- Добавить toggle-переключатель "День / Неделя" на главном экране
- **Режим "Неделя":** текущий вид (7 колонок, горизонтальный скролл)
- **Режим "День":** показывает одну колонку на весь экран с выбранным днём; переключение дней — свайп или стрелки
- В режиме "День" фильтр по тегам работает по задачам этого дня
**Затронутые файлы:**
- `lib/presentation/controllers/home_controller.dart` — добавить `ViewMode` enum (week/day), `selectedDay (Rx<DateTime>)`, геттер `tasksForSelectedDay`
- `lib/presentation/screens/home/home_screen.dart` — переключатель режимов, условный рендеринг дневного/недельного вида
- `lib/presentation/widgets/week_day_column.dart` — адаптация под полноэкранный дневной режим

---

## Порядок реализации
1. ✅ Исправить AndroidManifest (INTERNET permission) — ВЫПОЛНЕНО
2. ✅ Исправить проверку интернета в TaskFormController — ВЫПОЛНЕНО (HTTP ping через Dio)
3. ✅ Добавить кнопку "Еда" в хедер — ВЫПОЛНЕНО
4. ✅ Добавить проверку API ключа в настройках — ВЫПОЛНЕНО (кнопка "Проверить" с цветовым индикатором)
5. ✅ Добавить фильтр по тегам + режим "День/Неделя" — ВЫПОЛНЕНО

## Что изменено

### android/app/src/main/AndroidManifest.xml
- Добавлены: `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` permissions

### lib/presentation/controllers/task_form_controller.dart
- `_checkConnectivity()` переписан: DNS lookup → HTTP ping через Dio (если сервер отвечает любым кодом — интернет есть)
- Добавлен `Timer.periodic` каждые 5 сек для живой проверки

### lib/presentation/screens/home/home_screen.dart
- Добавлена кнопка "Еда" 🍽️ в шапку
- Добавлен переключатель "Неделя / День"
- Добавлена строка фильтров по тегам (только реально присутствующие теги)
- Добавлен дневной вид с навигатором и выбором дня недели

### lib/presentation/controllers/home_controller.dart
- Добавлен `ViewMode` enum (week/day)
- Добавлены: `selectedDay`, `selectedFilterTagId`, `viewMode`
- Методы: `setViewMode()`, `goToPreviousDay()`, `goToNextDay()`, `selectDay()`, `setTagFilter()`
- Геттеры: `availableTagsForWeek`, `availableTagsForDay`, `tasksForSelectedDay`, `selectedDayLabel`

### lib/data/services/mistral_service.dart
- Добавлен метод `testConnection()` — возвращает null если ОК, иначе текст ошибки

### lib/presentation/controllers/settings_controller.dart
- Добавлены поля: `isTestingKey`, `keyTestResult`, `keyTestMessage`
- Добавлен метод `testMistralApiKey()`

### lib/presentation/screens/settings/settings_screen.dart
- Кнопка "Сохранить ключ" разделена на две: "Сохранить" + "Проверить"
- Результат проверки отображается цветом (зелёный/красный) под кнопками
