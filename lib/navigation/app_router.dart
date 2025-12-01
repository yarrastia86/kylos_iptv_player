// Kylos IPTV Player - App Router
// go_router configuration for declarative navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/screens/kylos_dashboard_screen.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/screens/live_tv_categories_screen.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/screens/live_tv_channel_list_screen.dart';
import 'package:kylos_iptv_player/features/onboarding/presentation/screens/add_playlist_screen.dart';
import 'package:kylos_iptv_player/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:kylos_iptv_player/features/playback/presentation/screens/fullscreen_player_screen.dart';
import 'package:kylos_iptv_player/features/search/presentation/screens/search_screen.dart';
import 'package:kylos_iptv_player/features/series/presentation/screens/series_details_screen.dart';
import 'package:kylos_iptv_player/features/series/presentation/screens/series_list_screen.dart';
import 'package:kylos_iptv_player/features/series/presentation/screens/series_screen.dart';
import 'package:kylos_iptv_player/features/settings/presentation/screens/playlists_screen.dart';
import 'package:kylos_iptv_player/features/settings/presentation/screens/settings_screen.dart';
import 'package:kylos_iptv_player/features/vod/presentation/screens/vod_movie_list_screen.dart';
import 'package:kylos_iptv_player/features/vod/presentation/screens/vod_screen.dart';
import 'package:kylos_iptv_player/navigation/guards/onboarding_guard.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Provider for the app router.
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingGuard = ref.watch(onboardingGuardProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    debugLogDiagnostics: true,

    // Redirect logic for onboarding
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation.startsWith(Routes.onboarding);
      final needsOnboarding = !onboardingGuard.isComplete;

      if (needsOnboarding && !isOnboarding) {
        return Routes.onboarding;
      }

      if (!needsOnboarding && isOnboarding) {
        return Routes.dashboard;
      }

      return null;
    },

    routes: [
      // Onboarding flow
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'add-playlist',
            builder: (context, state) => const AddPlaylistScreen(),
          ),
        ],
      ),

      // Dashboard - main home screen (no bottom navigation)
      GoRoute(
        path: Routes.dashboard,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: KylosDashboardScreen(),
        ),
      ),

      // Content screens - full screen without bottom navigation
      GoRoute(
        path: Routes.liveTV,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LiveTvCategoriesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        routes: [
          // Channel list for a specific category
          GoRoute(
            path: 'category/:categoryId',
            pageBuilder: (context, state) {
              final categoryId = state.pathParameters['categoryId'] ?? '';
              final categoryName = state.extra as String?;
              return CustomTransitionPage(
                child: LiveTvChannelListScreen(
                  categoryId: categoryId,
                  categoryName: categoryName,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.vod,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const VodScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        routes: [
          // Movie list for a specific category
          GoRoute(
            path: 'category/:categoryId',
            pageBuilder: (context, state) {
              final categoryId = state.pathParameters['categoryId'] ?? '';
              final categoryName = state.extra as String?;
              return CustomTransitionPage(
                child: VodMovieListScreen(
                  categoryId: categoryId,
                  categoryName: categoryName,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.series,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SeriesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        routes: [
          // Series list for a specific category
          GoRoute(
            path: 'category/:categoryId',
            pageBuilder: (context, state) {
              final categoryId = state.pathParameters['categoryId'] ?? '';
              final categoryName = state.extra as String?;
              return CustomTransitionPage(
                child: SeriesListScreen(
                  categoryId: categoryId,
                  categoryName: categoryName,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            },
          ),
          // Series details screen
          GoRoute(
            path: ':seriesId',
            builder: (context, state) {
              final seriesId = state.pathParameters['seriesId'] ?? '';
              return SeriesDetailsScreen(seriesId: seriesId);
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Settings sub-routes (outside shell for full screen)
      GoRoute(
        path: Routes.playlists,
        builder: (context, state) => const PlaylistsScreen(),
      ),
      GoRoute(
        path: Routes.addPlaylist,
        builder: (context, state) => const AddPlaylistScreen(),
      ),

      // Fullscreen player
      GoRoute(
        path: Routes.player,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FullscreenPlayerScreen(),
        ),
      ),

      // Search screen
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF1A1F3A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                state.matchedLocation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
