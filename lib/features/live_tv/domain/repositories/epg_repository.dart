// Kylos IPTV Player - EPG Repository Interface
// Domain layer interface for EPG (Electronic Program Guide) operations.

import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';

/// Repository interface for EPG operations.
///
/// Defines the contract for accessing EPG data from any source
/// (XMLTV, Xtream API, etc.).
abstract class EpgRepository {
  /// Gets the current and next program for a channel.
  ///
  /// Returns a ChannelEpg with currentProgram and nextProgram populated.
  Future<ChannelEpg> getCurrentEpg(String channelId);

  /// Gets current/next EPG for multiple channels.
  ///
  /// Useful for efficiently loading EPG data for a list of channels.
  Future<Map<String, ChannelEpg>> getCurrentEpgBatch(List<String> channelIds);

  /// Gets all programs for a channel within a time range.
  ///
  /// [startTime] - Start of the time range.
  /// [endTime] - End of the time range.
  Future<List<EpgEntry>> getChannelPrograms(
    String channelId, {
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Gets EPG data for multiple channels within a time range.
  ///
  /// Returns a map of channelId to list of programs.
  Future<Map<String, List<EpgEntry>>> getEpgGrid({
    required List<String> channelIds,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Gets a single EPG entry by ID.
  Future<EpgEntry?> getProgram(String id);

  /// Searches programs by title.
  ///
  /// [query] - Search query string.
  /// [startTime] - Only search programs starting after this time.
  /// [limit] - Maximum number of results.
  Future<List<EpgEntry>> searchPrograms(
    String query, {
    DateTime? startTime,
    int limit = 50,
  });

  /// Refreshes EPG data from the source.
  ///
  /// This may be a long-running operation depending on the EPG size.
  Future<void> refresh();

  /// Gets the timestamp of the last EPG refresh.
  Future<DateTime?> getLastRefreshTime();

  /// Gets the total number of EPG entries loaded.
  Future<int> getEntryCount();

  /// Clears all cached EPG data.
  Future<void> clearCache();
}
