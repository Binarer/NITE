# 📦 Релизы / Releases

## v1.0.0 — Nitro Edition (20.02.2026)

### О приложении

**NiTe** — это персональный помощник для управления задачами и питанием с поддержкой AI-аналитики.

### Скриншоты

> Добавьте скриншоты приложения в папку `assets/screenshots/`

### Скачать

| Платформа | Статус | Ссылка |
|-----------|--------|--------|
| Android | ✅ Готов | Скоро в Google Play |
| iOS | ✅ Готов | Скоро в App Store |
| macOS | ✅ Готов | Скоро в App Store |
| Windows | ✅ Готов | [Скачать .exe](link) |
| Linux | ✅ Готов | [Скачать AppImage](link) |
| Web | ✅ Готов | [Открыть в браузере](link) |

### Основные функции

| Функция | Описание |
|---------|----------|
| ✅ Задачи | Создавайте задачи с приоритетами, сроками и тегами |
| ✅ Теги | Цветные теги для категоризации |
| ✅ Сценарии | Шаблоны для быстрого создания наборов задач |
| ✅ Питание | Дневник питания с подсчётом КБЖУ |
| ✅ AI-отчёты | Анализ продуктивности через Mistral AI |
| ✅ Уведомления | Напоминания о задачах |
| ✅ Виджет | Home Screen Widget для Android |
| ✅ Тёмная тема | Поддержка светлой и тёмной тем |
| ✅ Офлайн | Работает без интернета |

### Технологии

- **Flutter** 3.10+
- **Dart** 3.10+
- **GetX** — управление состоянием
- **Hive** — локальная база данных
- **Mistral AI** — AI-аналитика

### Установка из исходников

```bash
# Клонирование репозитория
git clone https://github.com/Binarer/nite.git
cd nite

# Установка зависимостей
flutter pub get

# Запуск
flutter run
```

### Сборка релизов

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

### Структура проекта

```
lib/
├── core/               # Ядро приложения
│   ├── constants/      # Константы
│   ├── routes/         # Маршрутизация
│   └── theme/          # Темы оформления
├── data/               # Слой данных
│   ├── models/         # Модели данных
│   ├── repositories/   # Репозитории
│   └── services/       # Сервисы
└── presentation/       # Слой представления
    ├── controllers/    # Контроллеры (GetX)
    ├── screens/        # Экраны
    └── widgets/        # Виджеты
```

### Конфигурация

#### Android

Для уведомлений добавьте в `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

#### iOS

Для уведомлений добавьте в `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### Переменные окружения

Создайте файл `.env` в корне проекта:

```env
# Mistral AI API Key (опционально, для AI-отчётов)
MISTRAL_API_KEY=your_api_key_here
```

### Лицензия

MIT License — подробнее в файле [LICENSE](LICENSE)

### Авторы

- **Ваше Имя** — [GitHub](https://github.com/yourusername)

### Благодарности

- Команда Flutter за прекрасный фреймворк
- Сообщество GetX за отличную документацию
- Mistral AI за предоставление API

---

⭐ Если проект полезен — поставьте звезду на GitHub!
