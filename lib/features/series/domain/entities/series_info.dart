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
    final seasonsData = json['seasons'] as List<dynamic>? ?? [];

    final seasons = seasonsData.map((s) {
      final seasonJson = s as Map<String, dynamic>;
      final seasonNum = seasonJson.integer('season_number');
      final episodeList = episodesData[seasonNum.toString()] as List<dynamic>? ?? [];

      return Season(
        seasonNumber: seasonNum,
        name: seasonJson.str('name', 'Season $seasonNum'),
        plot: seasonJson.strOrNull('overview'),
        releaseDate: seasonJson.strOrNull('air_date'),
        coverUrl: seasonJson.strOrNull('cover'),
        episodes: episodeList
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }).toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    return SeriesInfo(info: info, seasons: seasons);
  }
}
