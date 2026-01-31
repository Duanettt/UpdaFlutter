import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upda3/data/models/topic.dart';
import 'package:upda3/providers/database_provider.dart';

part 'topics_provider.g.dart';

@riverpod
class Topics extends _$Topics {
  @override
  Future<List<Topic>> build() async {
    final db = ref.read(databaseProvider);
    await db.database;
    return await db.topicDao.getAllTopics();
  }

  Future<void> addTopic(String name) async {
    final db = ref.read(databaseProvider);
    await db.topicDao.insertTopic(Topic(
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    ref.invalidateSelf();
  }

  Future<void> deleteTopic(int id) async {
    final db = ref.read(databaseProvider);
    await db.topicDao.deleteTopic(id);
    ref.invalidateSelf();
  }
}