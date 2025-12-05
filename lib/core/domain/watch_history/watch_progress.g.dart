// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WatchProgressImpl _$$WatchProgressImplFromJson(Map<String, dynamic> json) =>
    _$WatchProgressImpl(
      contentId: json['contentId'] as String,
      contentType: $enumDecode(_$WatchContentTypeEnumMap, json['contentType']),
      title: json['title'] as String,
      positionSeconds: (json['positionSeconds'] as num).toInt(),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      posterUrl: json['posterUrl'] as String?,
      seriesId: json['seriesId'] as String?,
      seriesName: json['seriesName'] as String?,
      seasonNumber: (json['seasonNumber'] as num?)?.toInt(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt(),
      streamUrl: json['streamUrl'] as String?,
      containerExtension: json['containerExtension'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WatchProgressImplToJson(_$WatchProgressImpl instance) =>
    <String, dynamic>{
      'contentId': instance.contentId,
      'contentType': _$WatchContentTypeEnumMap[instance.contentType]!,
      'title': instance.title,
      'positionSeconds': instance.positionSeconds,
      'durationSeconds': instance.durationSeconds,
      'posterUrl': instance.posterUrl,
      'seriesId': instance.seriesId,
      'seriesName': instance.seriesName,
      'seasonNumber': instance.seasonNumber,
      'episodeNumber': instance.episodeNumber,
      'streamUrl': instance.streamUrl,
      'containerExtension': instance.containerExtension,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$WatchContentTypeEnumMap = {
  WatchContentType.movie: 'movie',
  WatchContentType.episode: 'episode',
};

_$WatchHistoryImpl _$$WatchHistoryImplFromJson(Map<String, dynamic> json) =>
    _$WatchHistoryImpl(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => WatchProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$WatchHistoryImplToJson(_$WatchHistoryImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'totalCount': instance.totalCount,
    };
