// Kylos IPTV Player - Dashboard Screen
// Main home dashboard for navigating IPTV features.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:kylos_iptv_player/features/home/presentation/widgets/kylos_primary_tile.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Main dashboard screen for the Kylos IPTV Player.
///
/// Displays the main navigation hub with tiles for Live TV, Movies, and Series.
class KylosDashboardScreen extends ConsumerStatefulWidget {
  const KylosDashboardScreen({super.key});

  @override
  ConsumerState<KylosDashboardScreen> createState() =>
      _KylosDashboardScreenState();
}

class _KylosDashboardScreenState extends ConsumerState<KylosDashboardScreen> {
  // Focus nodes for keyboard/remote navigation
  late final List<FocusNode> _tileFocusNodes;

  @override
  void initState() {
    super.initState();
    _tileFocusNodes = List.generate(
      3,
      (i) => FocusNode(debugLabel: 'Dashboard Tile $i'),
    );
    // Load auth info (including expiration date) when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xtreamAuthNotifierProvider.notifier).loadAuthInfo();
    });
  }

  @override
  void dispose() {
    for (final node in _tileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _navigateToLiveTV() {
    context.go(Routes.liveTV);
  }

  void _navigateToMovies() {
    context.go(Routes.vod);
  }

  void _navigateToSeries() {
    context.go(Routes.series);
  }

  void _navigateToSettings() {
    context.push(Routes.settings);
  }

  void _handleExit() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: const Text(
          'Exit App',
          style: TextStyle(color: KylosColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(color: KylosColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePlaylist = ref.watch(activePlaylistProvider);
    final expirationDate = ref.watch(xtreamExpirationDateProvider);

    // Get expiration date from Xtream auth info
    String? expirationText;
    if (expirationDate != null) {
      final dateFormat = DateFormat('MMMM d, yyyy');
      expirationText = 'Expiration: ${dateFormat.format(expirationDate)}';
    } else if (activePlaylist?.xtreamCredentials != null) {
      // Show loading indicator while fetching
      expirationText = 'Expiration: Loading...';
    }

    return Scaffold(
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
        child: Stack(
          children: [
            // Subtle background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPatternPainter(),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar with logo, time, and actions
                  Padding(
                    padding: const EdgeInsets.only(top: KylosSpacing.s),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 600;
                        return DashboardTopBar(
                          compact: isCompact,
                          onSettingsTap: _navigateToSettings,
                          onPowerTap: _handleExit,
                        );
                      },
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: _buildMainContent(),
                  ),

                  // Footer with expiration
                  if (expirationText != null)
                    _buildFooter(expirationText)
                  else
                    SizedBox(height: KylosSpacing.l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final isShortHeight = constraints.maxHeight < 380;
        final isVeryShort = constraints.maxHeight < 300;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? KylosSpacing.m : KylosSpacing.xxl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isShortHeight ? KylosSpacing.s : KylosSpacing.xl),

                  // Main tiles
                  _buildMainTiles(
                    isCompact: isCompact,
                    isShortHeight: isShortHeight || isVeryShort,
                  ),

                  SizedBox(height: isShortHeight ? KylosSpacing.s : KylosSpacing.l),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainTiles({
    required bool isCompact,
    required bool isShortHeight,
  }) {
    final tiles = [
      KylosPrimaryTile(
        title: 'LIVE TV',
        icon: Icons.live_tv,
        gradient: KylosColors.liveTvGradient,
        glowColor: KylosColors.liveTvGlow,
        onTap: _navigateToLiveTV,
        focusNode: _tileFocusNodes[0],
        autofocus: true,
        compact: isShortHeight,
      ),
      KylosPrimaryTile(
        title: 'MOVIES',
        icon: Icons.movie,
        gradient: KylosColors.moviesGradient,
        glowColor: KylosColors.moviesGlow,
        onTap: _navigateToMovies,
        focusNode: _tileFocusNodes[1],
        compact: isShortHeight,
      ),
      KylosPrimaryTile(
        title: 'SERIES',
        icon: Icons.video_library,
        gradient: KylosColors.seriesGradient,
        glowColor: KylosColors.seriesGlow,
        onTap: _navigateToSeries,
        focusNode: _tileFocusNodes[2],
        compact: isShortHeight,
      ),
    ];

    if (isCompact && !isShortHeight) {
      // Vertical layout for smaller width screens (not in landscape)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tiles[0],
          SizedBox(height: KylosSpacing.m),
          tiles[1],
          SizedBox(height: KylosSpacing.m),
          tiles[2],
        ],
      );
    }

    // Horizontal layout for larger screens or short height (landscape)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        tiles[0],
        SizedBox(width: isShortHeight ? KylosSpacing.m : KylosSpacing.l),
        tiles[1],
        SizedBox(width: isShortHeight ? KylosSpacing.m : KylosSpacing.l),
        tiles[2],
      ],
    );
  }

  Widget _buildFooter(String expirationText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KylosSpacing.l),
      child: Text(
        expirationText,
        style: KylosTextStyles.caption,
      ),
    );
  }
}

/// Custom painter for subtle background pattern.
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw very subtle radial gradient overlay
    final center = Offset(size.width * 0.3, size.height * 0.3);
    final gradient = RadialGradient(
      center: Alignment(-0.4, -0.4),
      radius: 1.2,
      colors: [
        Colors.white.withOpacity(0.03),
        Colors.white.withOpacity(0),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw subtle grid dots
    paint.shader = null;
    paint.color = Colors.white.withOpacity(0.015);
    const dotSpacing = 60.0;
    const dotRadius = 1.0;

    for (var x = 0.0; x < size.width; x += dotSpacing) {
      for (var y = 0.0; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
