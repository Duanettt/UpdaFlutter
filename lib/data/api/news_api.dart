import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsApi {

  static final String _apiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.newsmesh.co/v1';

  /// Searches newsmesh for feed matching [query], maps them into [Article]
  /// objects bound to [topicId]. Returns an empty list on API errors so the
  /// caller can still fall back to cached DB feed.
  Future<List<Article>> searchNews(String query, int topicId) async {
    final url = Uri.parse(
      '$_baseUrl/search?apiKey=$_apiKey&q=${Uri.encodeComponent(query)}&limit=25&sortBy=date_descending',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['data'] as List;

        return articles.map((a) {
          return Article(
            url: a['link'] ?? '',
            topicId: topicId,
            title: a['title'] ?? 'No title',
            source: a['source'] ?? 'Unknown',
            publishedAt: a['published_date'] ?? '',
            imageUrl: a['media_url'],
          );
        }).where((article) => article.url.isNotEmpty).toList();
      }

      // newsmesh returns structured errors — log the message if you want
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Request failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}