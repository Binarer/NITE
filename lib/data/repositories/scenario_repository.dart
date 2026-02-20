import 'package:hive_flutter/hive_flutter.dart';
import '../models/scenario_model.dart';
import '../../core/constants/app_constants.dart';

class ScenarioRepository {
  Box<ScenarioModel> get _box => Hive.box<ScenarioModel>(AppConstants.scenariosBox);

  List<ScenarioModel> getAll() => _box.values.toList();

  ScenarioModel? getById(String id) {
    try {
      return _box.values.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ScenarioModel scenario) async {
    await _box.put(scenario.id, scenario);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
