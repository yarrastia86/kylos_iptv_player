// Kylos IPTV Player - EPG Entry Entity
// Domain entity representing an EPG (Electronic Program Guide) entry.

/// Represents a single program in the Electronic Program Guide.
///
/// Contains scheduling and metadata information for a TV program
/// airing on a specific channel.
class EpgEntry {
  const EpgEntry({
    required this.id,
    required this.channelId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.category,
    this.posterUrl,
    this.rating,
    this.episodeInfo,
    this.isNew = false,
    this.isLive = false,
  });

  /// Unique identifier for this EPG entry.
  final String id;

  /// Channel ID this program airs on.
  final String channelId;

  /// Title of the program.
  final String title;

  /// Start time of the program.
  final DateTime startTime;

  /// End time of the program.
  final DateTime endTime;

  /// Description or synopsis of the program.
  final String? description;

  /// Category/genre of the program.
  final String? category;

  /// URL for program poster/thumbnail.
  final String? posterUrl;

  /// Content rating (e.g., "TV-14", "PG").
  final String? rating;

  /// Episode information for series.
  final EpisodeInfo? episodeInfo;

  /// Whether this is a new/premiere episode.
  final bool isNew;

  /// Whether this program is currently live.
  final bool isLive;

  /// Duration of the program.
  Duration get duration => endTime.difference(startTime);

  /// Duration in minutes.
  int get durationMinutes => duration.inMinutes;

  /// Whether the program is currently airing.
  bool get isCurrentlyAiring {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Whether the program has already ended.
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Whether the program is upcoming.
  bool get isUpcoming => DateTime.now().isBefore(startTime);

  /// Progress percentage if currently airing (0.0 to 1.0).
  double get progress {
    if (!isCurrentlyAiring) return hasEnded ? 1.0 : 0.0;
    final elapsed = DateTime.now().difference(startTime);
    return elapsed.inSeconds / duration.inSeconds;
  }

  /// Creates a copy with the given fields replaced.
  EpgEntry copyWith({
    String? id,
    String? channelId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    String? category,
    String? posterUrl,
    String? rating,
    EpisodeInfo? episodeInfo,
    bool? isNew,
    bool? isLive,
  }) {
    return EpgEntry(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      category: category ?? this.category,
      posterUrl: posterUrl ?? this.posterUrl,
      rating: rating ?? this.rating,
      episodeInfo: episodeInfo ?? this.episodeInfo,
      isNew: isNew ?? this.isNew,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpgEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EpgEntry($id, $title, $startTime)';
}

/// Episode information for series programs.
class EpisodeInfo {
  const EpisodeInfo({
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.seriesTitle,
  });

  /// Season number.
  final int? seasonNumber;

  /// Episode number within the season.
  final int? episodeNumber;

  /// Title of the specific episode.
  final String? episodeTitle;

  /// Title of the series.
  final String? seriesTitle;

  /// Formatted string like "S01E05".
  String? get formatted {
    if (seasonNumber == null && episodeNumber == null) return null;
    final season = seasonNumber != null ? 'S${seasonNumber.toString().padLeft(2, '0')}' : '';
    final episode = episodeNumber != null ? 'E${episodeNumber.toString().padLeft(2, '0')}' : '';
    return '$season$episode'.trim();
  }

  @override
  String toString() => formatted ?? 'EpisodeInfo()';
}

/// Represents EPG data for a channel with current/next program info.
class ChannelEpg {
  const ChannelEpg({
    required this.channelId,
    this.currentProgram,
    this.nextProgram,
    this.programs = const [],
  });

  /// The channel this EPG data belongs to.
  final String channelId;

  /// Currently airing program.
  final EpgEntry? currentProgram;

  /// Next scheduled program.
  final EpgEntry? nextProgram;

  /// All programs for this channel (for full EPG view).
  final List<EpgEntry> programs;

  /// Whether EPG data is available.
  bool get hasData => currentProgram != null || programs.isNotEmpty;

  /// Creates empty EPG data for a channel.
  factory ChannelEpg.empty(String channelId) {
    return ChannelEpg(channelId: channelId);
  }

  @override
  String toString() => 'ChannelEpg($channelId, ${programs.length} programs)';
}
