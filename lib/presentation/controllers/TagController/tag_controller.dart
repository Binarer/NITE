import 'package:get/get.dart';

import '../../../data/models/TagModel/tag_model.dart';
import '../../../data/repositories/TagRepository/tag_repository.dart';

class TagController extends GetxController {
  final TagRepository _repo = Get.find<TagRepository>();

  final RxList<TagModel> tags = <TagModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTags();
  }

  void loadTags() {
    tags.value = _repo.getAll();
  }

  TagModel? getById(String id) => _repo.getById(id);

  List<TagModel> getByIds(List<String> ids) {
    return ids.map((id) => _repo.getById(id)).whereType<TagModel>().toList();
  }

  Future<void> saveTag(TagModel tag) async {
    await _repo.save(tag);
    loadTags();
  }

  Future<void> deleteTag(String id) async {
    await _repo.delete(id);
    loadTags();
  }
}
