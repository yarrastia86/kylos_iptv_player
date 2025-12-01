// Kylos IPTV Player - EPG Info Panel Widget
// Panel widget for displaying EPG (Electronic Program Guide) information.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';

/// Panel widget for displaying EPG information for a channel.
///
/// Shows current and next program information, or "No guide information"
/// if EPG data is unavailable.
class EpgInfoPanel extends StatelessWidget {
  const EpgInfoPanel({
    super.key,
    this.channelEpg,
    this.isLoading = false,
  });

  /// EPG data for the channel.
  final ChannelEpg? channelEpg;

  /// Whether EPG data is being loaded.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KylosColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? _buildLoadingState()
          : channelEpg?.hasData == true
              ? _buildEpgContent()
              : _buildNoGuideMessage(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: KylosColors.liveTvGlow,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Loading guide...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: KylosColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildNoGuideMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Icon(
          Icons.info_outline,
          color: KylosColors.textMuted,
          size: 32,
        ),
        SizedBox(height: 12),
        Text(
          'No guide information',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: KylosColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEpgContent() {
    final currentProgram = channelEpg!.currentProgram;
    final nextProgram = channelEpg!.nextProgram;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Current program
        if (currentProgram != null) ...[
          _buildProgramRow(
            label: 'NOW',
            labelColor: KylosColors.liveTvGlow,
            program: currentProgram,
            showProgress: true,
          ),
          if (nextProgram != null) ...[
            const SizedBox(height: 16),
            const Divider(color: KylosColors.surfaceLight, height: 1),
            const SizedBox(height: 16),
          ],
        ],

        // Next program
        if (nextProgram != null)
          _buildProgramRow(
            label: 'NEXT',
            labelColor: KylosColors.textMuted,
            program: nextProgram,
            showProgress: false,
          ),

        // If only one program and it's current, show placeholder for next
        if (currentProgram != null && nextProgram == null) ...[
          const SizedBox(height: 16),
          const Divider(color: KylosColors.surfaceLight, height: 1),
          const SizedBox(height: 16),
          _buildNoNextProgram(),
        ],
        ],
      ),
    );
  }

  Widget _buildProgramRow({
    required String label,
    required Color labelColor,
    required EpgEntry program,
    required bool showProgress,
  }) {
    final timeFormat = DateFormat('h:mm a');
    final startTime = timeFormat.format(program.startTime);
    final endTime = timeFormat.format(program.endTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: labelColor.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$startTime - $endTime',
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Program title
        Text(
          program.title,
          style: const TextStyle(
            color: KylosColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Description (if available)
        if (program.description != null && program.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            program.description!,
            style: const TextStyle(
              color: KylosColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Progress bar (for current program)
        if (showProgress) ...[
          const SizedBox(height: 12),
          _buildProgressBar(program),
        ],
      ],
    );
  }

  Widget _buildProgressBar(EpgEntry program) {
    final progress = program.progress;
    final remainingMinutes =
        program.endTime.difference(DateTime.now()).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: KylosColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(
              KylosColors.liveTvGlow,
            ),
            minHeight: 4,
          ),
        ),

        const SizedBox(height: 6),

        // Time remaining
        Row(
          children: [
            Text(
              '${(progress * 100).toInt()}% complete',
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              remainingMinutes > 0 ? '$remainingMinutes min left' : 'Ending',
              style: const TextStyle(
                color: KylosColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoNextProgram() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: const Text(
            'NEXT',
            style: TextStyle(
              color: KylosColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'No information',
          style: TextStyle(
            color: KylosColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}