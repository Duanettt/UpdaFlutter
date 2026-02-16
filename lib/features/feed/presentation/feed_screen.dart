import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:upda3/common/style/theme.dart';
import 'package:upda3/data/models/article.dart';
import 'package:upda3/features/discover/providers/topics_provider.dart';
import 'package:upda3/features/feed/providers/articles_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feed',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            Text(
              DateFormat('MMMM dd').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading topics',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: AppColors.textTertiary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No topics yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add topics in Discover to see articles',
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
    final allArticlesFutures = topics.map((topic) {
      return ref.watch(articlesProvider(topic.id!, topic.name));
    }).toList();

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
      return const Center(
        child: Text(
          'Error loading articles',
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    if (combinedArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppColors.textTertiary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No articles yet',
              style: TextStyle(
                fontSize: 20,
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

    combinedArticles.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.article.publishedAt);
        final dateB = DateTime.parse(b.article.publishedAt);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    final heroArticle = combinedArticles.first;
    final restArticles = combinedArticles.skip(1).toList();

    return RefreshIndicator(
      onRefresh: () async {
        for (var topic in topics) {
          ref.read(articlesProvider(topic.id!, topic.name).notifier).refresh();
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'LATEST NEWS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.primary,
              ),
            ),
          ),

          _HeroArticle(
            article: heroArticle.article,
            topicName: heroArticle.topicName,
            onTap: () => onArticleTap(heroArticle.article.url),
            formattedDate: formatDate(heroArticle.article.publishedAt),
          ),

          const SizedBox(height: 32),

          ...restArticles.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _ArticleCard(
                article: item.article,
                topicName: item.topicName,
                onTap: () => onArticleTap(item.article.url),
                formattedDate: formatDate(item.article.publishedAt),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeroArticle extends StatelessWidget {
  final Article article;
  final String topicName;
  final VoidCallback onTap;
  final String formattedDate;

  const _HeroArticle({
    required this.article,
    required this.topicName,
    required this.onTap,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 240,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 240,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.article_outlined, size: 64),
            ),

          const SizedBox(height: 12),

          Text(
            article.source.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            article.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.source.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 24,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, size: 32),
            ),
        ],
      ),
    );
  }
}