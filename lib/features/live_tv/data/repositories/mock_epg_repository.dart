// Kylos IPTV Player - Mock EPG Repository
// Mock implementation for testing and development.

import 'package:kylos_iptv_player/features/live_tv/domain/entities/epg_entry.dart';
import 'package:kylos_iptv_player/features/live_tv/domain/repositories/epg_repository.dart';

/// Mock implementation of EpgRepository for testing and development.
///
/// This provides sample EPG data without requiring an actual EPG source.
class MockEpgRepository implements EpgRepository {
  DateTime? _lastRefresh;

  @override
  Future<ChannelEpg> getCurrentEpg(String channelId) async {
    await _simulateDelay();
    final now = DateTime.now();

    // Create mock current and next program
    final currentProgram = EpgEntry(
      id: 'epg_${channelId}_current',
      channelId: channelId,
      title: 'Current Program',
      description: 'This is the currently airing program.',
      startTime: now.subtract(const Duration(minutes: 30)),
      endTime: now.add(const Duration(minutes: 30)),
      category: 'Entertainment',
    );

    final nextProgram = EpgEntry(
      id: 'epg_${channelId}_next',
      channelId: channelId,
      title: 'Next Program',
      description: 'This program will air next.',
      startTime: now.add(const Duration(minutes: 30)),
      endTime: now.add(const Duration(minutes: 90)),
      category: 'Entertainment',
    );

    return ChannelEpg(
      channelId: channelId,
      currentProgram: currentProgram,
      nextProgram: nextProgram,
    );
  }

  @override
  Future<Map<String, ChannelEpg>> getCurrentEpgBatch(
    List<String> channelIds,
  ) async {
    await _simulateDelay();
    final result = <String, ChannelEpg>{};

    for (final channelId in channelIds) {
      result[channelId] = await getCurrentEpg(channelId);
    }

    return result;
  }

  @override
  Future<List<EpgEntry>> getChannelPrograms(
    String channelId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _simulateDelay();
    final programs = <EpgEntry>[];

    var programStart = startTime;
    var programIndex = 0;

    while (programStart.isBefore(endTime)) {
      final duration = Duration(minutes: 30 + (programIndex % 3) * 30);
      final programEnd = programStart.add(duration);

      programs.add(EpgEntry(
        id: 'epg_${channelId}_$programIndex',
        channelId: channelId,
        title: 'Program ${programIndex + 1}',
        description: 'Mock program description',
        startTime: programStart,
        endTime: programEnd,
        category: _getCategory(programIndex),
      ));

      programStart = programEnd;
      programIndex++;
    }

    return programs;
  }

  @override
  Future<Map<String, List<EpgEntry>>> getEpgGrid({
    required List<String> channelIds,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _simulateDelay();
    final result = <String, List<EpgEntry>>{};

    for (final channelId in channelIds) {
      result[channelId] = await getChannelPrograms(
        channelId,
        startTime: startTime,
        endTime: endTime,
      );
    }

    return result;
  }

  @override
  Future<EpgEntry?> getProgram(String id) async {
    await _simulateDelay();
    // Return a mock program
    final now = DateTime.now();
    return EpgEntry(
      id: id,
      channelId: 'ch1',
      title: 'Program Details',
      description: 'Detailed description of the program.',
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      category: 'Entertainment',
    );
  }

  @override
  Future<List<EpgEntry>> searchPrograms(
    String query, {
    DateTime? startTime,
    int limit = 50,
  }) async {
    await _simulateDelay();
    // Return empty list for mock
    return [];
  }

  @override
  Future<void> refresh() async {
    await _simulateDelay(milliseconds: 500);
    _lastRefresh = DateTime.now();
  }

  @override
  Future<DateTime?> getLastRefreshTime() async {
    return _lastRefresh;
  }

  @override
  Future<int> getEntryCount() async {
    return 0;
  }

  @override
  Future<void> clearCache() async {
    _lastRefresh = null;
  }

  String _getCategory(int index) {
    final categories = ['News', 'Sports', 'Entertainment', 'Movies', 'Kids'];
    return categories[index % categories.length];
  }

  Future<void> _simulateDelay({int milliseconds = 50}) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
  }
}
