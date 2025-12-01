// Kylos IPTV Player - Category Chips
// Horizontal scrollable category filter chips.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';

/// Horizontal scrollable category filter chips.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  /// Available categories.
  final List<ChannelCategory> categories;

  /// Currently selected category ID (null for "All").
  final String? selectedCategoryId;

  /// Called when a category is selected.
  final void Function(String? categoryId)? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1, // +1 for "All" chip
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: const Text('All'),
                selected: selectedCategoryId == null,
                onSelected: (_) => onCategorySelected?.call(null),
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = category.id == selectedCategoryId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) => onCategorySelected?.call(category.id),
              avatar: category.channelCount > 0
                  ? CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        category.channelCount.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
