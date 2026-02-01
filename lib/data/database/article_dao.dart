import 'package:sqflite/sqflite.dart';
import '../models/article.dart';

class ArticleDao {
  final Database db;

  ArticleDao(this.db);

  Future<void> insertArticles(List<Article> articles) async {
    final batch = db.batch();
    for (var article in articles) {
      batch.insert('feed', article.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Article>> getArticlesForTopic(int topicId) async {
    final result = await db.query(
      'feed',
      where: 'topicId = ?',
      whereArgs: [topicId],
      orderBy: 'publishedAt DESC',
    );
    return result.map((json) => Article.fromMap(json)).toList();
  }
}
