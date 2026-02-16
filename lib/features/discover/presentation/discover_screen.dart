import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upda3/common/style/theme.dart';
import 'package:upda3/features/discover/providers/topics_provider.dart';
import 'package:upda3/features/feed/providers/articles_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  void _showAddTopicSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.25,
        ),
        child: _AddTopicSheet(
          onTopicAdded: (String topicName) async {
            await ref.read(topicsProvider.notifier).addTopic(topicName);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _showAddTopicSheet(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Error loading topics',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No topics yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add topics to start tracking news',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTopicSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Topic'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TopicCard(topic: topic),
              );
            },
          );
        },
      ),
    );
  }
}

class _TopicCard extends ConsumerWidget {
  final dynamic topic;

  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider(topic.id!, topic.name));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.surface,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          _showDeleteDialog(context, ref);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          articlesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, stack) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Failed to load articles',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.inbox_outlined, color: AppColors.textTertiary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'No articles yet',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final latestArticle = articles.first;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, size: 8, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Latest Update',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      latestArticle.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(latestArticle.publishedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return '';
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Topic',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete "${topic.name}"? You\'ll stop receiving notifications.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(topicsProvider.notifier).deleteTopic(topic.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet for adding topics
class _AddTopicSheet extends StatefulWidget {
  final Future<void> Function(String) onTopicAdded;

  const _AddTopicSheet({required this.onTopicAdded});

  @override
  State<_AddTopicSheet> createState() => _AddTopicSheetState();
}

class _AddTopicSheetState extends State<_AddTopicSheet> {
  final _controller = TextEditingController();
  bool _isAdding = false;

  static final List<String> _suggestions = [
    'AI & Machine Learning',
    'Space Exploration',
    'Cryptocurrency',
    'Electric Vehicles',
    'Quantum Computing',
    'Formula 1',
    'NBA',
    'Premier League',
    'Stock Market',
  ];

  Future<void> _addTopic(String topicName) async {
    if (topicName.trim().isEmpty || _isAdding) return;

    setState(() => _isAdding = true);

    try {
      await widget.onTopicAdded(topicName.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding topic: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Add Topic',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Search/Input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Icon(
                          Icons.search,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: false,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search or type your own...',
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onSubmitted: _addTopic,
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      if (_isAdding)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: () => _addTopic(_controller.text),
                        ),
                    ],
                  ),
                ),
              ),

              // Suggestions label
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Text(
                  'POPULAR TOPICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

              // Suggestions grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: _isAdding ? null : () => _addTopic(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '# ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}