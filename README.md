<div align="center">

# NiTe

**Умный таск-трекер с AI-аналитикой, планированием питания и еженедельным ретроспективным отчётом**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.2.1-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

</div>

---

## Возможности

### 📅 Еженедельный планировщик
- Планирование задач по дням недели с временными слотами
- Виды: **недельный** (7 колонок) и **дневной** (список задач на день)
- **Drag & Drop** для перемещения задач между днями
- Фильтрация задач по тегу (цветовая подсветка приоритетов)

### ✅ Задачи
- Название, описание, теги, время начала/конца, приоритет (0–5)
- Подзадачи с индикатором прогресса
- Привязка к карточке еды (при теге "Еда")
- AI-оценка приоритета задачи

### 🍽️ Библиотека продуктов
- Карточки блюд с фото, КБЖУ, описанием
- **Мультивыделение** — выбор нескольких продуктов (long press)
- **Скрыть / Удалить** выделенные продукты
- Скрытые продукты не отображаются в плане питания и задачах
- Поиск по названию блюда

### 🤖 Поддерживаемые AI-провайдеры

| Провайдер | Модели |
|---|---|
| Mistral AI | mistral-small, mistral-medium, mistral-large |
| OpenAI | gpt-4o-mini, gpt-4o, gpt-4-turbo |
| Google Gemini | gemini-1.5-flash, gemini-1.5-pro |
| DeepSeek | deepseek-chat, deepseek-reasoner |
| Qwen (Alibaba) | qwen-turbo, qwen-plus, qwen-max |
| Anthropic Claude | claude-3-haiku, claude-3-sonnet, claude-3-opus |
| Groq | llama3-8b, llama3-70b, mixtral-8x7b |

**AI-функции:**
- 🔢 Оценка приоритета задачи
- 📊 Ежедневный отчёт в заданное время (настраивается в настройках)
- 📈 Еженедельная ретроспектива каждый понедельник в 12:00
- 🍎 Генерация плана питания на неделю

### 🔔 Уведомления (Android)
- Точные напоминания о задачах за N минут до начала
- Кнопки прямо в уведомлении: **Открыть задачу** / **+15 мин**
- Восстановление уведомлений после перезагрузки устройства
- Кнопка "Проверить обновления" в настройках

### 🔄 Авто-обновление
- Приложение автоматически проверяет новые релизы на GitHub при каждом запуске
- При обнаружении обновления показывается диалог с changelog и кнопкой скачать APK
- Ручная проверка: **Настройки → Обновления**

---

## 🛠️ Стек технологий

| Компонент | Технология |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | GetX |
| Локальная БД | Hive (NoSQL) |
| HTTP клиент | Dio |
| Уведомления | awesome_notifications |
| Изображения | image_picker |
| Дата/время | intl, timezone |
| UUID | uuid |

---

## 🚀 Быстрый старт

### Требования
- Flutter SDK >= 3.10
- Dart SDK >= 3.0
- Android SDK (для Android сборки)

### Установка

```bash
git clone https://github.com/Binarer/NITE.git
cd NITE

flutter pub get

dart run build_runner build --delete-conflicting-outputs

flutter run
```

### Настройка AI

1. Откройте приложение и перейдите в **Настройки**
2. Выберите **AI-провайдера**, введите API ключ и выберите модель
3. Готово! AI-функции активированы

> Приложение работает **полностью офлайн**. AI-функции требуют интернета.

---

## 📂 Структура проекта

```
lib/
├── core/
│   ├── constants/      # AppConstants
│   ├── routes/         # AppRoutes
│   └── theme/          # AppColors, AppTheme
├── data/
│   ├── models/         # Hive модели (Task, Tag, Food, Scenario, AiReport)
│   ├── repositories/   # CRUD операции
│   └── services/       # AI, уведомления, отчёты, обновления
└── presentation/
    ├── controllers/    # GetX контроллеры
    ├── screens/        # Экраны приложения
    └── widgets/        # Переиспользуемые виджеты
```

---

## 📱 Экраны

| Экран | Описание |
|---|---|
| `HomeScreen` | Еженедельник с drag&drop |
| `TaskFormScreen` | Создание/редактирование задачи |
| `FoodLibraryScreen` | Библиотека еды с мультивыбором |
| `FoodDetailScreen` | Детали блюда + редактирование |
| `ScenariosScreen` | Список сценариев |
| `ScenarioFormScreen` | Конструктор сценария |
| `StatisticsScreen` | Статистика + AI-отчёты |
| `ReportsScreen` | Красивые отчёты с графиками и анимацией |
| `SettingsScreen` | Настройка AI, тегов, уведомлений, обновлений |

---

## 🔔 Уведомления

| Уведомление | Время |
|---|---|
| Напоминание о задаче | За N минут до начала (настраивается) |
| Ежедневный AI-отчёт | Настраивается (по умолчанию 20:00) |
| Еженедельный AI-отчёт | Понедельник 12:00 |

---

## 🔄 CI/CD

Релизы собираются автоматически через **GitHub Actions**:

```bash
git tag v1.2.1
git push origin main --tags
```

GitHub Actions собирает APK для arm64/arm32/x86_64 и публикует GitHub Release.

---

## 📋 Changelog

### v1.2.1
- ✅ Переход на `awesome_notifications` — надёжные уведомления на Android
- ✅ Авто-обновление из GitHub Releases
- ✅ Мультивыделение в библиотеке еды (скрыть/удалить)
- ✅ Красивые отчёты с анимацией и графиками
- ✅ Настройка времени ежедневного отчёта
- ✅ Автогенерация отчётов в фоне через WorkManager
- ✅ Исправлены уведомления (Missing type parameter bug)
- ✅ GitHub Actions workflow для авто-сборки APK

---

## 👤 Контакты

Разработчик: **Binarer**

- 💬 Telegram: [@wasitfallen](https://t.me/wasitfallen)
- 🐙 GitHub: [github.com/Binarer](https://github.com/Binarer)

---

## 📄 Лицензия

MIT License — свободное использование, изменение и распространение.

---

<div align="center">
Сделано с ❤️ на Flutter
</div>
