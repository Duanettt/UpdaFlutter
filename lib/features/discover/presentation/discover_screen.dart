import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upda3/common/style/theme.dart';
import 'package:upda3/features/discover/providers/topics_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static final List<String> _suggestedTopics = [
    'AI & Machine Learning',
    'Climate Change',
    'Space Exploration',
    'Cryptocurrency',
    'Mental Health',
    'Remote Work',
    'Electric Vehicles',
    'Quantum Computing',
    'Biotech',
    'Web3',
  ];

  void _showAddDialog(BuildContext context, WidgetRef ref, [String? initialText]) {
    final controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Topic', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g., AI news, Climate tech',
            prefixText: '# ',
            prefixStyle: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref.read(topicsProvider.notifier).addTopic(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _showAddDialog(context, ref),
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
              Text('Error: $error', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        data: (topics) {
          final activetopicNames = topics.map((t) => t.name.toLowerCase()).toSet();
          final availableSuggestions = _suggestedTopics
              .where((s) => !activetopicNames.contains(s.toLowerCase()))
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your Topics
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'YOUR TOPICS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (topics.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${topics.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (topics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: 64,
                            color: AppColors.textTertiary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No discover yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add discover to start tracking news',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDialog(context, ref),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add Topic'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topics.map((topic) {
                        return _TopicChip(
                          topic: topic.name,
                          isActive: true,
                          onDelete: () {
                            ref.read(topicsProvider.notifier).deleteTopic(topic.id!);
                          },
                        );
                      }).toList(),
                    ),
                  ),

                // Suggested Topics
                if (availableSuggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
                    child: Text(
                      'SUGGESTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSuggestions.map((topic) {
                        return _TopicChip(
                          topic: topic,
                          isActive: false,
                          onTap: () => _showAddDialog(context, ref, topic),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String topic;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TopicChip({
    required this.topic,
    required this.isActive,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '# ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            Text(
              topic,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (isActive && onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
            ],
            if (!isActive) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.add,
                size: 16,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}