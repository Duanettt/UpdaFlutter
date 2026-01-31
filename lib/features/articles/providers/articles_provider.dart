import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:upda3/data/api/news_api.dart';
import 'package:upda3/data/models/article.dart';
import 'package:upda3/providers/database_provider.dart';

part 'articles_provider.g.dart';

@riverpod
class Articles extends _$Articles {
  @override
  Future<List<Article>> build(int topicId, String topicName) async {
    final db = ref.read(databaseProvider);
    // Make sure the DB is actually open before we hit the DAOs
    await db.database;

    try {
      final newsApi = NewsApi();
      final newArticles = await newsApi.searchNews(topicName, topicId);
      if (newArticles.isNotEmpty) {
        await db.articleDao.insertArticles(newArticles);
      }
    } catch (e) {
      // API failed — that's fine, we'll return whatever is cached below
    }

    return await db.articleDao.getArticlesForTopic(topicId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
