import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsApi {

  static final String _apiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://gnews.io/api/v4';

  /// Searches GNews for articles matching [query], maps them into [Article]
  /// objects bound to [topicId]. Returns an empty list on API errors so the
  /// caller can still fall back to cached DB feed.
  Future<List<Article>> searchNews(String query, int topicId) async {
    // Clean query: remove special characters that break GNews search
    final cleanQuery = query.replaceAll('&', 'AND').replaceAll(RegExp(r'[^\w\s]'), ' ').trim();

    final url = Uri.parse(
      '$_baseUrl/search?q=${Uri.encodeComponent(cleanQuery)}&lang=en&max=25&sortby=publishedAt&apikey=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        return articles.map((a) {
          return Article(
            url: a['url'] ?? '',
            topicId: topicId,
            title: a['title'] ?? 'No title',
            source: a['source']?['name'] ?? 'Unknown',
            publishedAt: a['publishedAt'] ?? '',
            imageUrl: a['image'],
          );
        }).where((article) => article.url.isNotEmpty).toList();
      }

      // GNews returns structured errors
      final errorData = json.decode(response.body);
      final errors = errorData['errors'];
      String errorMsg = 'Request failed: ${response.statusCode}';

      if (errors is Map) {
        errorMsg = errors.values.first.toString();
      } else if (errors is List && errors.isNotEmpty) {
        errorMsg = errors.first.toString();
      }

      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}