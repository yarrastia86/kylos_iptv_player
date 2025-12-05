// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      videoQuality:
          $enumDecodeNullable(_$VideoQualityEnumMap, json['videoQuality']) ??
              VideoQuality.auto,
      bufferSize:
          $enumDecodeNullable(_$BufferSizeEnumMap, json['bufferSize']) ??
              BufferSize.normal,
      autoPlay: json['autoPlay'] as bool? ?? true,
      themeMode:
          $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
              AppThemeMode.dark,
      showEpg: json['showEpg'] as bool? ?? true,
      rememberLastChannel: json['rememberLastChannel'] as bool? ?? true,
      defaultPlaybackSpeed:
          (json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'videoQuality': _$VideoQualityEnumMap[instance.videoQuality]!,
      'bufferSize': _$BufferSizeEnumMap[instance.bufferSize]!,
      'autoPlay': instance.autoPlay,
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'showEpg': instance.showEpg,
      'rememberLastChannel': instance.rememberLastChannel,
      'defaultPlaybackSpeed': instance.defaultPlaybackSpeed,
    };

const _$VideoQualityEnumMap = {
  VideoQuality.auto: 'auto',
  VideoQuality.quality1080p: 'quality1080p',
  VideoQuality.quality720p: 'quality720p',
  VideoQuality.quality480p: 'quality480p',
  VideoQuality.quality360p: 'quality360p',
};

const _$BufferSizeEnumMap = {
  BufferSize.low: 'low',
  BufferSize.normal: 'normal',
  BufferSize.high: 'high',
};

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};
