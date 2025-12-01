import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_json_helpers.dart';

part 'episode.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String title,
    required String containerExtension,
    int? season,
    int? episodeNum,
    String? releaseDate,
    String? plot,
    String? duration,
    String? coverUrl,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json.str('id'),
        title: json.str('title', 'Episode'),
        containerExtension: json.str('container_extension', 'ts'),
        season: json.intOrNull('season'),
        episodeNum: json.intOrNull('episode_num'),
        releaseDate: json.strOrNull('releasedate') ?? json.strOrNull('release_date'),
        plot: json.strOrNull('plot'),
        duration: json.strOrNull('duration'),
        coverUrl: json.strOrNull('movie_image') ?? json.strOrNull('cover'),
      );
}
