// Kylos IPTV Player - Search Screen
// Screen for searching content across the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/series/presentation/providers/series_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    final seriesResults = ref.watch(seriesSearchProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: TextStyle(color: KylosColors.textPrimary)),
        backgroundColor: KylosColors.backgroundEnd,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KylosColors.backgroundStart,
              KylosColors.backgroundEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {}); // Re-trigger the provider watch
                },
                decoration: InputDecoration(
                  hintText: 'Search for series...',
                  hintStyle: const TextStyle(color: KylosColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: KylosColors.textMuted),
                  filled: true,
                  fillColor: KylosColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: KylosColors.textPrimary),
              ),
            ),
            Expanded(
              child: seriesResults.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (series) {
                  if (query.isEmpty) {
                    return const Center(
                      child: Text(
                        'Enter a query to search for series.',
                        style: TextStyle(color: KylosColors.textMuted),
                      ),
                    );
                  }
                  if (series.isEmpty) {
                    return const Center(
                      child: Text(
                        'No results found.',
                        style: TextStyle(color: KylosColors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: series.length,
                    itemBuilder: (context, index) {
                      final item = series[index];
                      return ListTile(
                        leading: item.coverUrl != null
                            ? Image.network(item.coverUrl!, width: 40)
                            : const Icon(Icons.tv, color: KylosColors.textMuted),
                        title: Text(item.name, style: const TextStyle(color: KylosColors.textPrimary)),
                        onTap: () {
                          context.go(Routes.seriesDetailPath(item.id));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
