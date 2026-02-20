# ошибки при дебаге
---
[GETX] GOING TO ROUTE /task/edit
[GETX] Instance "TaskFormController" has been created
[GETX] Instance "TaskFormController" has been initialized
[GETX] CLOSE TO ROUTE /task/edit
[GETX] "TaskFormController" onDelete() called
[GETX] "TaskFormController" deleted from memory
[GETX] GOING TO ROUTE /task/edit
[GETX] Instance "TaskFormController" has been created
[GETX] Instance "TaskFormController" has been initialized
---
ошибка при добавлении позадачи
Exception has occurred.
_TypeError (type '_Map<String, dynamic>' is not a subtype of type 'Map<String, Object>' of 'value')
task_form_controller.dart
92 строка в task_form_controller.dart
 void addSubtask(String title) {
    if (title.trim().isEmpty) return;
    subtasks.add({
      'id': const Uuid().v4(),
      'title': title.trim(),
      'isCompleted': false,
    });
  }