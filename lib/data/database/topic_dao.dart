import 'package:sqflite/sqflite.dart';
import '../models/topic.dart';

class TopicDao {
  final Database db;

  TopicDao(this.db);

  Future<int> insertTopic(Topic topic) async {
    return await db.insert('discover', topic.toMap());
  }

  Future<List<Topic>> getAllTopics() async {
    final result = await db.query('discover', orderBy: 'createdAt DESC');
    return result.map((json) => Topic.fromMap(json)).toList();
  }

  Future<int> deleteTopic(int id) async {
    return await db.delete('discover', where: 'id = ?', whereArgs: [id]);
  }
}