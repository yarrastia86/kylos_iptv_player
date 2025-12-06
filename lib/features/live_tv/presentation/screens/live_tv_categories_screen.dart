// Kylos IPTV Player - Live TV Categories Screen
// Screen displaying Live TV categories in a standardized grid layout.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/channel_category.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/providers/channel_providers.dart';
import 'package:kylos_iptv_player/features/playlists/presentation/providers/playlist_providers.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';

/// Screen displaying Live TV categories.
///
/// Shows categories in a 3-column grid layout with:
/// - Single purpose: Pick a category
/// - Full-width layout maximizing readability
/// - Large touch targets for 10-foot viewing
/// - Clear focus states for D-pad navigation
class LiveTvCategoriesScreen extends ConsumerStatefulWidget {
  const LiveTvCategoriesScreen({super.key});

  @override
  ConsumerState<LiveTvCategoriesScreen> createState() =>
      _LiveTvCategoriesScreenState();
}

class _LiveTvCategoriesScreenState
    extends ConsumerState<LiveTvCategoriesScreen> {
  final FocusNode _screenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelListNotifierProvider.notifier).loadChannels();
    });
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _navigateToChannelList(ChannelCategory category) {
    context.push(
      Routes.liveTvCategoryPath(category.id),
      extra: category.name,
    );
  }

  void _handleSearch() {
    context.push(Routes.search);
  }

  void _handleMore() {
    _showOptionsMenu();
  }

  void _showOptionsMenu() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: Text(
          'Options',
          style: KylosTvTextStyles.sectionHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionTile(
              icon: Icons.refresh,
              label: 'Refresh Content',
              onTap: () {
                Navigator.pop(context);
                _handleRefreshContent();
              },
            ),
            _OptionTile(
              icon: Icons.schedule,
              label: 'Refresh EPG',
              onTap: () {
                Navigator.pop(context);
                _handleRefreshEpg();
              },
            ),
            _OptionTile(
              icon: Icons.sort,
              label: 'Sort',
              onTap: () {
                Navigator.pop(context);
                _showSortDialog();
              },
            ),
            _OptionTile(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.settings);
              },
            ),
            _OptionTile(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefreshContent() async {
    await ref.read(channelListNotifierProvider.notifier).refresh();
  }

  Future<void> _handleRefreshEpg() async {
    await ref.read(channelEpgNotifierProvider.notifier).refresh();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: Text(
          'Sort Categories',
          style: KylosTvTextStyles.sectionHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionTile(
              icon: Icons.sort_by_alpha,
              label: 'Name (A-Z)',
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.sort_by_alpha,
              label: 'Name (Z-A)',
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.numbers,
              label: 'Channel Count',
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.restore,
              label: 'Default',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KylosColors.surfaceDark,
        title: Text(
          'Logout',
          style: KylosTvTextStyles.sectionHeader,
        ),
        content: Text(
          'Are you sure you want to logout? This will clear your active playlist.',
          style: KylosTvTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if ((shouldLogout ?? false) && mounted) {
      ref.read(activePlaylistNotifierProvider.notifier).clearActivePlaylist();
      context.go(Routes.onboarding);
    }
  }

  void _handleBack() {
    context.go(Routes.dashboard);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelListNotifierProvider);

    return Focus(
      focusNode: _screenFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildContent(channelState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xl,
        vertical: KylosSpacing.m,
      ),
      child: Row(
        children: [
          _FocusableIconButton(
            icon: Icons.arrow_back,
            onPressed: _handleBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: KylosSpacing.m),
          Expanded(
            child: Text(
              'LIVE TV',
              style: KylosTvTextStyles.screenTitle,
            ),
          ),
          _FocusableIconButton(
            icon: Icons.search,
            onPressed: _handleSearch,
            tooltip: 'Search',
          ),
          const SizedBox(width: KylosSpacing.s),
          _FocusableIconButton(
            icon: Icons.more_vert,
            onPressed: _handleMore,
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ChannelListState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: KylosColors.liveTvGlow,
        ),
      );
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.categories.isEmpty) {
      return _buildEmptyState();
    }

    final categories = _buildCategoriesWithSpecial(state);
    return _buildCategoryGrid(categories);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            'Failed to load categories',
            style: KylosTvTextStyles.sectionHeader.copyWith(
              color: KylosColors.textPrimary,
            ),
          ),
          const SizedBox(height: KylosSpacing.xs),
          Text(
            error,
            style: KylosTvTextStyles.body.copyWith(
              color: KylosColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KylosSpacing.xl),
          _FocusableButton(
            icon: Icons.refresh,
            label: 'Retry',
            onPressed: () {
              ref.read(channelListNotifierProvider.notifier).loadChannels();
            },
            autofocus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.live_tv_outlined,
            size: 64,
            color: KylosColors.textMuted,
          ),
          const SizedBox(height: KylosSpacing.m),
          Text(
            'No channels available',
            style: KylosTvTextStyles.sectionHeader.copyWith(
              color: KylosColors.textPrimary,
            ),
          ),
          const SizedBox(height: KylosSpacing.xs),
          Text(
            'Add a playlist with Live TV content',
            style: KylosTvTextStyles.body.copyWith(
              color: KylosColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<ChannelCategory> categories) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: KylosSpacing.xl,
        vertical: KylosSpacing.m,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: KylosSpacing.m,
        crossAxisSpacing: KylosSpacing.m,
        childAspectRatio: 2.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryTile(
          category: category,
          autofocus: index == 0,
          onSelect: () => _navigateToChannelList(category),
        );
      },
    );
  }

  List<ChannelCategory> _buildCategoriesWithSpecial(ChannelListState state) {
    final allCategory = ChannelCategory(
      id: 'all',
      name: 'ALL CHANNELS',
      channelCount: state.allChannelsCount,
      sortOrder: -2,
    );

    final favoritesCategory = ChannelCategory(
      id: 'favorites',
      name: 'FAVORITES',
      channelCount: state.favoritesCount,
      sortOrder: -1,
      isFavorite: true,
    );

    return [allCategory, favoritesCategory, ...state.categories];
  }
}

/// Category tile widget for the grid.
class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.onSelect,
    this.autofocus = false,
  });

  final ChannelCategory category;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: KylosDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onSelect();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpecial =
        widget.category.id == 'all' || widget.category.id == 'favorites';

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: _onFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: KylosDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: KylosSpacing.l,
                  vertical: KylosSpacing.m,
                ),
                decoration: BoxDecoration(
                  gradient: _isFocused
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            KylosColors.liveTvGlow.withOpacity(0.4),
                            KylosColors.liveTvGlow.withOpacity(0.15),
                          ],
                        )
                      : isSpecial
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.category.id == 'favorites'
                                  ? [
                                      Colors.red.shade900.withOpacity(0.4),
                                      Colors.red.shade900.withOpacity(0.2),
                                    ]
                                  : [
                                      KylosColors.surfaceLight,
                                      KylosColors.surfaceDark,
                                    ],
                            )
                          : null,
                  color: _isFocused || isSpecial ? null : KylosColors.surfaceDark,
                  borderRadius: BorderRadius.circular(KylosRadius.l),
                  border: _isFocused
                      ? Border.all(color: KylosColors.liveTvGlow, width: 3)
                      : Border.all(
                          color: KylosColors.buttonBorder,
                          width: 1,
                        ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: KylosColors.liveTvGlow.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(KylosSpacing.s),
                      decoration: BoxDecoration(
                        color: _isFocused
                            ? KylosColors.liveTvGlow.withOpacity(0.3)
                            : KylosColors.surfaceOverlay,
                        borderRadius: BorderRadius.circular(KylosRadius.m),
                      ),
                      child: Icon(
                        widget.category.id == 'favorites'
                            ? Icons.favorite
                            : widget.category.id == 'all'
                                ? Icons.live_tv
                                : Icons.folder_outlined,
                        color: _isFocused
                            ? KylosColors.liveTvGlow
                            : widget.category.id == 'favorites'
                                ? Colors.redAccent.shade200
                                : KylosColors.textSecondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: KylosSpacing.m),
                    // Name and count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.category.name,
                              style: KylosTvTextStyles.cardTitle.copyWith(
                                color: _isFocused
                                    ? KylosColors.liveTvGlow
                                    : KylosColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.category.channelCount > 0)
                            Text(
                              '${_formatCount(widget.category.channelCount)} channels',
                              style: KylosTvTextStyles.cardSubtitle.copyWith(
                                color: _isFocused
                                    ? KylosColors.liveTvGlow.withValues(alpha: 0.8)
                                    : KylosColors.textMuted,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(
                      Icons.chevron_right,
                      color: _isFocused
                          ? KylosColors.liveTvGlow
                          : KylosColors.textMuted,
                      size: 28,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Option tile for the options menu.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: KylosColors.textSecondary),
      title: Text(
        label,
        style: KylosTvTextStyles.body.copyWith(
          color: KylosColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// A focusable icon button for the top bar.
class _FocusableIconButton extends StatefulWidget {
  const _FocusableIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<_FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<_FocusableIconButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: AnimatedContainer(
            duration: KylosDurations.fast,
            padding: const EdgeInsets.all(KylosSpacing.s),
            decoration: BoxDecoration(
              color: _isFocused
                  ? KylosColors.liveTvGlow.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(KylosRadius.s),
              border: _isFocused
                  ? Border.all(color: KylosColors.liveTvGlow, width: 2)
                  : null,
            ),
            child: Icon(
              widget.icon,
              color:
                  _isFocused ? KylosColors.liveTvGlow : KylosColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// A focusable button for actions.
class _FocusableButton extends StatefulWidget {
  const _FocusableButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _isFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: KylosDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: KylosSpacing.l,
            vertical: KylosSpacing.m,
          ),
          decoration: BoxDecoration(
            color: _isFocused ? KylosColors.liveTvGlow : KylosColors.surfaceLight,
            borderRadius: BorderRadius.circular(KylosRadius.m),
            border: _isFocused
                ? Border.all(color: KylosColors.liveTvGlow, width: 2)
                : Border.all(color: KylosColors.buttonBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isFocused ? Colors.white : KylosColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: KylosSpacing.s),
              Text(
                widget.label,
                style: KylosTvTextStyles.button.copyWith(
                  color: _isFocused ? Colors.white : KylosColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
