import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/episode.dart';
import 'package:kylos_iptv_player/features/series/domain/entities/series.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_json_helpers.dart';

part 'series_info.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class Season with _$Season {
  const factory Season({
    required int seasonNumber,
    required String name,
    String? plot,
    String? releaseDate,
    String? coverUrl,
    @Default([]) List<Episode> episodes,
  }) = _Season;
}

@Freezed(toJson: false, fromJson: false)
class SeriesInfo with _$SeriesInfo {
  const factory SeriesInfo({
    required Series info,
    required List<Season> seasons,
  }) = _SeriesInfo;

  factory SeriesInfo.fromJson(Map<String, dynamic> json) {
    final infoData = json['info'];
    final info = infoData is Map<String, dynamic>
        ? Series.fromJson(infoData)
        : const Series(id: '', name: 'Unknown Series');

    final episodesData = json['episodes'] as Map<String, dynamic>? ?? {};

    // If no seasons data, try to build seasons from episodes keys
    List<dynamic> seasonsData = json['seasons'] as List<dynamic>? ?? [];

    // Build seasons from episodes data if seasons list is incomplete
    final episodeSeasonNumbers = episodesData.keys
        .map((k) => int.tryParse(k) ?? 0)
        .where((n) => n > 0) // Filter out season 0 (Specials)
        .toSet();

    final seasons = <Season>[];

    // First, process seasons from seasonsData
    for (final s in seasonsData) {
      final seasonJson = s as Map<String, dynamic>;
      final seasonNum = seasonJson.integer('season_number');

      // Skip Season 0 (Specials)
      if (seasonNum <= 0) continue;

      final episodeList = episodesData[seasonNum.toString()] as List<dynamic>? ?? [];

      seasons.add(Season(
        seasonNumber: seasonNum,
        name: 'Season $seasonNum', // Always use English
        plot: seasonJson.strOrNull('overview'),
        releaseDate: seasonJson.strOrNull('air_date'),
        coverUrl: seasonJson.strOrNull('cover'),
        episodes: episodeList
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));

      episodeSeasonNumbers.remove(seasonNum);
    }

    // Add any seasons that exist in episodes but not in seasons list
    for (final seasonNum in episodeSeasonNumbers) {
      final episodeList = episodesData[seasonNum.toString()] as List<dynamic>? ?? [];
      if (episodeList.isNotEmpty) {
        seasons.add(Season(
          seasonNumber: seasonNum,
          name: 'Season $seasonNum',
          episodes: episodeList
              .map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
      }
    }

    // Sort by season number
    seasons.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    return SeriesInfo(info: info, seasons: seasons);
  }
}
