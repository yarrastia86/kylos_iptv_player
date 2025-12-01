import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kylos_iptv_player/infrastructure/xtream/xtream_json_helpers.dart';

part 'series.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class Series with _$Series {
  const factory Series({
    required String id,
    required String name,
    String? categoryId,
    String? categoryName,
    String? coverUrl,
    String? rating,
    String? releaseDate,
    String? plot,
    String? cast,
    String? director,
    String? genre,
    String? lastModified,
    @Default(false) bool isFavorite,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => Series(
        id: json.str('series_id', json.str('id')),
        name: json.str('name', 'Unknown Series'),
        categoryId: json.strOrNull('category_id'),
        categoryName: json.strOrNull('category_name'),
        coverUrl: json.strOrNull('cover'),
        rating: json.strOrNull('rating'),
        releaseDate: json.strOrNull('releaseDate') ?? json.strOrNull('release_date'),
        plot: json.strOrNull('plot'),
        cast: json.strOrNull('cast'),
        director: json.strOrNull('director'),
        genre: json.strOrNull('genre'),
        lastModified: json.strOrNull('last_modified'),
        isFavorite: json.boolean('isFavorite'),
      );
}
