import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upda3/data/models/topic.dart';
import 'package:upda3/features/articles/providers/articles_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ArticlesScreen extends ConsumerWidget {
  final Topic topic;

  const ArticlesScreen({super.key, required this.topic});

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider(topic.id!, topic.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: articlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('No articles found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(articlesProvider(topic.id!, topic.name).notifier).refresh();
            },
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, i) {
                final article = articles[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${article.source} • ${_formatDate(article.publishedAt)}',
                    ),
                    onTap: () => _openArticle(article.url),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}