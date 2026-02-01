import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:upda3/common/style/theme.dart';
import 'package:upda3/data/models/article.dart';
import 'package:upda3/features/discover/providers/topics_provider.dart';
import 'package:upda3/features/feed/providers/articles_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

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

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: AppColors.textTertiary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No discover selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add discover in Discover to see news',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return _UnifiedFeed(
            topics: topics,
            onArticleTap: _openArticle,
            formatDate: _formatDate,
          );
        },
      ),
    );
  }
}

class _UnifiedFeed extends ConsumerWidget {
  final List topics;
  final Function(String) onArticleTap;
  final String Function(String) formatDate;

  const _UnifiedFeed({
    required this.topics,
    required this.onArticleTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch all feed from all discover
    final allArticlesFutures = topics.map((topic) {
      return ref.watch(articlesProvider(topic.id!, topic.name));
    }).toList();

    // Combine all feed
    final List<({Article article, String topicName})> combinedArticles = [];
    bool isLoading = false;
    Object? error;

    for (var i = 0; i < allArticlesFutures.length; i++) {
      allArticlesFutures[i].when(
        loading: () => isLoading = true,
        error: (e, stack) => error = e,
        data: (articles) {
          for (var article in articles) {
            combinedArticles.add((article: article, topicName: topics[i].name));
          }
        },
      );
    }

    if (isLoading && combinedArticles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && combinedArticles.isEmpty) {
      return Center(
        child: Text('Error loading feed', style: const TextStyle(color: AppColors.error)),
      );
    }

    if (combinedArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No feed yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date
    combinedArticles.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.article.publishedAt);
        final dateB = DateTime.parse(b.article.publishedAt);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        for (var topic in topics) {
          ref.read(articlesProvider(topic.id!, topic.name).notifier).refresh();
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: combinedArticles.length,
        separatorBuilder: (context, index) => Container(
          height: 32,
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 1,
                height: 32,
                color: AppColors.border,
                margin: const EdgeInsets.only(left: 4),
              ),
            ],
          ),
        ),
        itemBuilder: (context, i) {
          final item = combinedArticles[i];
          return _ArticleCard(
            article: item.article,
            topicName: item.topicName,
            onTap: () => onArticleTap(item.article.url),
            formattedDate: formatDate(item.article.publishedAt),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final String topicName;
  final VoidCallback onTap;
  final String formattedDate;

  const _ArticleCard({
    required this.article,
    required this.topicName,
    required this.onTap,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(top: 6),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '# ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              topicName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $formattedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}