import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/database/app_database.dart';

part 'database_provider.g.dart';

@riverpod
AppDatabase database(Ref ref) {
  return AppDatabase.instance;
}