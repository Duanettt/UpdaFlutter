import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'topic_dao.dart';
import 'article_dao.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  TopicDao? _topicDao;
  ArticleDao? _articleDao;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('upda.db');
    return _database!;
  }

  TopicDao get topicDao {
    _topicDao ??= TopicDao(_database!);
    return _topicDao!;
  }

  ArticleDao get articleDao {
    _articleDao ??= ArticleDao(_database!);
    return _articleDao!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE articles (
        url TEXT PRIMARY KEY,
        topicId INTEGER NOT NULL,
        title TEXT NOT NULL,
        source TEXT NOT NULL,
        publishedAt TEXT NOT NULL,
        imageUrl TEXT
      )
    ''');
  }
}