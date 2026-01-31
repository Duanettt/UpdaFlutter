import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upda3/data/models/topic.dart';
import 'package:upda3/data/services/notification_service.dart';
import 'package:upda3/providers/database_provider.dart';

part 'topics_provider.g.dart';

@riverpod
class Topics extends _$Topics {
  final _notificationService = NotificationService();

  @override
  Future<List<Topic>> build() async {
    final db = ref.read(databaseProvider);
    await db.database;
    return await db.topicDao.getAllTopics();
  }

  Future<void> addTopic(String name) async {
    final db = ref.read(databaseProvider);
    final topicId = await db.topicDao.insertTopic(Topic(
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // Subscribe to notifications for this topic
    await _notificationService.subscribeToTopic(topicId, name);

    ref.invalidateSelf();
  }

  Future<void> deleteTopic(int id) async {
    final db = ref.read(databaseProvider);

    // Get the topic name before deleting so we can unsubscribe
    final topics = await db.topicDao.getAllTopics();
    final topic = topics.firstWhere((t) => t.id == id);

    await db.topicDao.deleteTopic(id);

    // Unsubscribe from notifications for this topic
    await _notificationService.unsubscribeFromTopic(id, topic.name);

    ref.invalidateSelf();
  }
}