// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return _AppSettings.fromJson(json);
}

/// @nodoc
mixin _$AppSettings {
  VideoQuality get videoQuality => throw _privateConstructorUsedError;
  BufferSize get bufferSize => throw _privateConstructorUsedError;
  bool get autoPlay => throw _privateConstructorUsedError;
  AppThemeMode get themeMode => throw _privateConstructorUsedError;
  bool get showEpg => throw _privateConstructorUsedError;
  bool get rememberLastChannel => throw _privateConstructorUsedError;
  double get defaultPlaybackSpeed => throw _privateConstructorUsedError;

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
          AppSettings value, $Res Function(AppSettings) then) =
      _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call(
      {VideoQuality videoQuality,
      BufferSize bufferSize,
      bool autoPlay,
      AppThemeMode themeMode,
      bool showEpg,
      bool rememberLastChannel,
      double defaultPlaybackSpeed});
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoQuality = null,
    Object? bufferSize = null,
    Object? autoPlay = null,
    Object? themeMode = null,
    Object? showEpg = null,
    Object? rememberLastChannel = null,
    Object? defaultPlaybackSpeed = null,
  }) {
    return _then(_value.copyWith(
      videoQuality: null == videoQuality
          ? _value.videoQuality
          : videoQuality // ignore: cast_nullable_to_non_nullable
              as VideoQuality,
      bufferSize: null == bufferSize
          ? _value.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as BufferSize,
      autoPlay: null == autoPlay
          ? _value.autoPlay
          : autoPlay // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as AppThemeMode,
      showEpg: null == showEpg
          ? _value.showEpg
          : showEpg // ignore: cast_nullable_to_non_nullable
              as bool,
      rememberLastChannel: null == rememberLastChannel
          ? _value.rememberLastChannel
          : rememberLastChannel // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultPlaybackSpeed: null == defaultPlaybackSpeed
          ? _value.defaultPlaybackSpeed
          : defaultPlaybackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
          _$AppSettingsImpl value, $Res Function(_$AppSettingsImpl) then) =
      __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {VideoQuality videoQuality,
      BufferSize bufferSize,
      bool autoPlay,
      AppThemeMode themeMode,
      bool showEpg,
      bool rememberLastChannel,
      double defaultPlaybackSpeed});
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
      _$AppSettingsImpl _value, $Res Function(_$AppSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoQuality = null,
    Object? bufferSize = null,
    Object? autoPlay = null,
    Object? themeMode = null,
    Object? showEpg = null,
    Object? rememberLastChannel = null,
    Object? defaultPlaybackSpeed = null,
  }) {
    return _then(_$AppSettingsImpl(
      videoQuality: null == videoQuality
          ? _value.videoQuality
          : videoQuality // ignore: cast_nullable_to_non_nullable
              as VideoQuality,
      bufferSize: null == bufferSize
          ? _value.bufferSize
          : bufferSize // ignore: cast_nullable_to_non_nullable
              as BufferSize,
      autoPlay: null == autoPlay
          ? _value.autoPlay
          : autoPlay // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as AppThemeMode,
      showEpg: null == showEpg
          ? _value.showEpg
          : showEpg // ignore: cast_nullable_to_non_nullable
              as bool,
      rememberLastChannel: null == rememberLastChannel
          ? _value.rememberLastChannel
          : rememberLastChannel // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultPlaybackSpeed: null == defaultPlaybackSpeed
          ? _value.defaultPlaybackSpeed
          : defaultPlaybackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsImpl implements _AppSettings {
  const _$AppSettingsImpl(
      {this.videoQuality = VideoQuality.auto,
      this.bufferSize = BufferSize.normal,
      this.autoPlay = true,
      this.themeMode = AppThemeMode.dark,
      this.showEpg = true,
      this.rememberLastChannel = true,
      this.defaultPlaybackSpeed = 1.0});

  factory _$AppSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsImplFromJson(json);

  @override
  @JsonKey()
  final VideoQuality videoQuality;
  @override
  @JsonKey()
  final BufferSize bufferSize;
  @override
  @JsonKey()
  final bool autoPlay;
  @override
  @JsonKey()
  final AppThemeMode themeMode;
  @override
  @JsonKey()
  final bool showEpg;
  @override
  @JsonKey()
  final bool rememberLastChannel;
  @override
  @JsonKey()
  final double defaultPlaybackSpeed;

  @override
  String toString() {
    return 'AppSettings(videoQuality: $videoQuality, bufferSize: $bufferSize, autoPlay: $autoPlay, themeMode: $themeMode, showEpg: $showEpg, rememberLastChannel: $rememberLastChannel, defaultPlaybackSpeed: $defaultPlaybackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsImpl &&
            (identical(other.videoQuality, videoQuality) ||
                other.videoQuality == videoQuality) &&
            (identical(other.bufferSize, bufferSize) ||
                other.bufferSize == bufferSize) &&
            (identical(other.autoPlay, autoPlay) ||
                other.autoPlay == autoPlay) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.showEpg, showEpg) || other.showEpg == showEpg) &&
            (identical(other.rememberLastChannel, rememberLastChannel) ||
                other.rememberLastChannel == rememberLastChannel) &&
            (identical(other.defaultPlaybackSpeed, defaultPlaybackSpeed) ||
                other.defaultPlaybackSpeed == defaultPlaybackSpeed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, videoQuality, bufferSize,
      autoPlay, themeMode, showEpg, rememberLastChannel, defaultPlaybackSpeed);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsImplToJson(
      this,
    );
  }
}

abstract class _AppSettings implements AppSettings {
  const factory _AppSettings(
      {final VideoQuality videoQuality,
      final BufferSize bufferSize,
      final bool autoPlay,
      final AppThemeMode themeMode,
      final bool showEpg,
      final bool rememberLastChannel,
      final double defaultPlaybackSpeed}) = _$AppSettingsImpl;

  factory _AppSettings.fromJson(Map<String, dynamic> json) =
      _$AppSettingsImpl.fromJson;

  @override
  VideoQuality get videoQuality;
  @override
  BufferSize get bufferSize;
  @override
  bool get autoPlay;
  @override
  AppThemeMode get themeMode;
  @override
  bool get showEpg;
  @override
  bool get rememberLastChannel;
  @override
  double get defaultPlaybackSpeed;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
