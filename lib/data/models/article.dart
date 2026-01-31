class Article {
  final String url;
  final int topicId;
  final String title;
  final String source;
  final String publishedAt;
  final String? imageUrl;

  Article({
    required this.url,
    required this.topicId,
    required this.title,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'topicId': topicId,
      'title': title,
      'source': source,
      'publishedAt': publishedAt,
      'imageUrl': imageUrl,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      url: map['url'],
      topicId: map['topicId'],
      title: map['title'],
      source: map['source'],
      publishedAt: map['publishedAt'],
      imageUrl: map['imageUrl'],
    );
  }
}