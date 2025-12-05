// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watch_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WatchProgress _$WatchProgressFromJson(Map<String, dynamic> json) {
  return _WatchProgress.fromJson(json);
}

/// @nodoc
mixin _$WatchProgress {
  /// Unique ID of the content (movie ID or episode ID).
  String get contentId => throw _privateConstructorUsedError;

  /// Type of content.
  WatchContentType get contentType => throw _privateConstructorUsedError;

  /// Title of the content for display.
  String get title => throw _privateConstructorUsedError;

  /// Current playback position in seconds.
  int get positionSeconds => throw _privateConstructorUsedError;

  /// Total duration in seconds.
  int get durationSeconds => throw _privateConstructorUsedError;

  /// Poster or thumbnail URL.
  String? get posterUrl => throw _privateConstructorUsedError;

  /// Series ID (for episodes only).
  String? get seriesId => throw _privateConstructorUsedError;

  /// Series name (for episodes only).
  String? get seriesName => throw _privateConstructorUsedError;

  /// Season number (for episodes only).
  int? get seasonNumber => throw _privateConstructorUsedError;

  /// Episode number (for episodes only).
  int? get episodeNumber => throw _privateConstructorUsedError;

  /// Stream URL for quick resume.
  String? get streamUrl => throw _privateConstructorUsedError;

  /// Container extension for building stream URL.
  String? get containerExtension => throw _privateConstructorUsedError;

  /// When this progress was last updated.
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this WatchProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WatchProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WatchProgressCopyWith<WatchProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WatchProgressCopyWith<$Res> {
  factory $WatchProgressCopyWith(
          WatchProgress value, $Res Function(WatchProgress) then) =
      _$WatchProgressCopyWithImpl<$Res, WatchProgress>;
  @useResult
  $Res call(
      {String contentId,
      WatchContentType contentType,
      String title,
      int positionSeconds,
      int durationSeconds,
      String? posterUrl,
      String? seriesId,
      String? seriesName,
      int? seasonNumber,
      int? episodeNumber,
      String? streamUrl,
      String? containerExtension,
      DateTime updatedAt});
}

/// @nodoc
class _$WatchProgressCopyWithImpl<$Res, $Val extends WatchProgress>
    implements $WatchProgressCopyWith<$Res> {
  _$WatchProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WatchProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? contentType = null,
    Object? title = null,
    Object? positionSeconds = null,
    Object? durationSeconds = null,
    Object? posterUrl = freezed,
    Object? seriesId = freezed,
    Object? seriesName = freezed,
    Object? seasonNumber = freezed,
    Object? episodeNumber = freezed,
    Object? streamUrl = freezed,
    Object? containerExtension = freezed,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as WatchContentType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      positionSeconds: null == positionSeconds
          ? _value.positionSeconds
          : positionSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      seriesId: freezed == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String?,
      seriesName: freezed == seriesName
          ? _value.seriesName
          : seriesName // ignore: cast_nullable_to_non_nullable
              as String?,
      seasonNumber: freezed == seasonNumber
          ? _value.seasonNumber
          : seasonNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      episodeNumber: freezed == episodeNumber
          ? _value.episodeNumber
          : episodeNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      streamUrl: freezed == streamUrl
          ? _value.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      containerExtension: freezed == containerExtension
          ? _value.containerExtension
          : containerExtension // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WatchProgressImplCopyWith<$Res>
    implements $WatchProgressCopyWith<$Res> {
  factory _$$WatchProgressImplCopyWith(
          _$WatchProgressImpl value, $Res Function(_$WatchProgressImpl) then) =
      __$$WatchProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String contentId,
      WatchContentType contentType,
      String title,
      int positionSeconds,
      int durationSeconds,
      String? posterUrl,
      String? seriesId,
      String? seriesName,
      int? seasonNumber,
      int? episodeNumber,
      String? streamUrl,
      String? containerExtension,
      DateTime updatedAt});
}

/// @nodoc
class __$$WatchProgressImplCopyWithImpl<$Res>
    extends _$WatchProgressCopyWithImpl<$Res, _$WatchProgressImpl>
    implements _$$WatchProgressImplCopyWith<$Res> {
  __$$WatchProgressImplCopyWithImpl(
      _$WatchProgressImpl _value, $Res Function(_$WatchProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of WatchProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? contentType = null,
    Object? title = null,
    Object? positionSeconds = null,
    Object? durationSeconds = null,
    Object? posterUrl = freezed,
    Object? seriesId = freezed,
    Object? seriesName = freezed,
    Object? seasonNumber = freezed,
    Object? episodeNumber = freezed,
    Object? streamUrl = freezed,
    Object? containerExtension = freezed,
    Object? updatedAt = null,
  }) {
    return _then(_$WatchProgressImpl(
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as WatchContentType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      positionSeconds: null == positionSeconds
          ? _value.positionSeconds
          : positionSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      seriesId: freezed == seriesId
          ? _value.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String?,
      seriesName: freezed == seriesName
          ? _value.seriesName
          : seriesName // ignore: cast_nullable_to_non_nullable
              as String?,
      seasonNumber: freezed == seasonNumber
          ? _value.seasonNumber
          : seasonNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      episodeNumber: freezed == episodeNumber
          ? _value.episodeNumber
          : episodeNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      streamUrl: freezed == streamUrl
          ? _value.streamUrl
          : streamUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      containerExtension: freezed == containerExtension
          ? _value.containerExtension
          : containerExtension // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WatchProgressImpl extends _WatchProgress {
  const _$WatchProgressImpl(
      {required this.contentId,
      required this.contentType,
      required this.title,
      required this.positionSeconds,
      required this.durationSeconds,
      this.posterUrl,
      this.seriesId,
      this.seriesName,
      this.seasonNumber,
      this.episodeNumber,
      this.streamUrl,
      this.containerExtension,
      required this.updatedAt})
      : super._();

  factory _$WatchProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$WatchProgressImplFromJson(json);

  /// Unique ID of the content (movie ID or episode ID).
  @override
  final String contentId;

  /// Type of content.
  @override
  final WatchContentType contentType;

  /// Title of the content for display.
  @override
  final String title;

  /// Current playback position in seconds.
  @override
  final int positionSeconds;

  /// Total duration in seconds.
  @override
  final int durationSeconds;

  /// Poster or thumbnail URL.
  @override
  final String? posterUrl;

  /// Series ID (for episodes only).
  @override
  final String? seriesId;

  /// Series name (for episodes only).
  @override
  final String? seriesName;

  /// Season number (for episodes only).
  @override
  final int? seasonNumber;

  /// Episode number (for episodes only).
  @override
  final int? episodeNumber;

  /// Stream URL for quick resume.
  @override
  final String? streamUrl;

  /// Container extension for building stream URL.
  @override
  final String? containerExtension;

  /// When this progress was last updated.
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'WatchProgress(contentId: $contentId, contentType: $contentType, title: $title, positionSeconds: $positionSeconds, durationSeconds: $durationSeconds, posterUrl: $posterUrl, seriesId: $seriesId, seriesName: $seriesName, seasonNumber: $seasonNumber, episodeNumber: $episodeNumber, streamUrl: $streamUrl, containerExtension: $containerExtension, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WatchProgressImpl &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.positionSeconds, positionSeconds) ||
                other.positionSeconds == positionSeconds) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.seriesName, seriesName) ||
                other.seriesName == seriesName) &&
            (identical(other.seasonNumber, seasonNumber) ||
                other.seasonNumber == seasonNumber) &&
            (identical(other.episodeNumber, episodeNumber) ||
                other.episodeNumber == episodeNumber) &&
            (identical(other.streamUrl, streamUrl) ||
                other.streamUrl == streamUrl) &&
            (identical(other.containerExtension, containerExtension) ||
                other.containerExtension == containerExtension) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      contentId,
      contentType,
      title,
      positionSeconds,
      durationSeconds,
      posterUrl,
      seriesId,
      seriesName,
      seasonNumber,
      episodeNumber,
      streamUrl,
      containerExtension,
      updatedAt);

  /// Create a copy of WatchProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WatchProgressImplCopyWith<_$WatchProgressImpl> get copyWith =>
      __$$WatchProgressImplCopyWithImpl<_$WatchProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WatchProgressImplToJson(
      this,
    );
  }
}

abstract class _WatchProgress extends WatchProgress {
  const factory _WatchProgress(
      {required final String contentId,
      required final WatchContentType contentType,
      required final String title,
      required final int positionSeconds,
      required final int durationSeconds,
      final String? posterUrl,
      final String? seriesId,
      final String? seriesName,
      final int? seasonNumber,
      final int? episodeNumber,
      final String? streamUrl,
      final String? containerExtension,
      required final DateTime updatedAt}) = _$WatchProgressImpl;
  const _WatchProgress._() : super._();

  factory _WatchProgress.fromJson(Map<String, dynamic> json) =
      _$WatchProgressImpl.fromJson;

  /// Unique ID of the content (movie ID or episode ID).
  @override
  String get contentId;

  /// Type of content.
  @override
  WatchContentType get contentType;

  /// Title of the content for display.
  @override
  String get title;

  /// Current playback position in seconds.
  @override
  int get positionSeconds;

  /// Total duration in seconds.
  @override
  int get durationSeconds;

  /// Poster or thumbnail URL.
  @override
  String? get posterUrl;

  /// Series ID (for episodes only).
  @override
  String? get seriesId;

  /// Series name (for episodes only).
  @override
  String? get seriesName;

  /// Season number (for episodes only).
  @override
  int? get seasonNumber;

  /// Episode number (for episodes only).
  @override
  int? get episodeNumber;

  /// Stream URL for quick resume.
  @override
  String? get streamUrl;

  /// Container extension for building stream URL.
  @override
  String? get containerExtension;

  /// When this progress was last updated.
  @override
  DateTime get updatedAt;

  /// Create a copy of WatchProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WatchProgressImplCopyWith<_$WatchProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WatchHistory _$WatchHistoryFromJson(Map<String, dynamic> json) {
  return _WatchHistory.fromJson(json);
}

/// @nodoc
mixin _$WatchHistory {
  List<WatchProgress> get items => throw _privateConstructorUsedError;
  int get totalCount => throw _privateConstructorUsedError;

  /// Serializes this WatchHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WatchHistoryCopyWith<WatchHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WatchHistoryCopyWith<$Res> {
  factory $WatchHistoryCopyWith(
          WatchHistory value, $Res Function(WatchHistory) then) =
      _$WatchHistoryCopyWithImpl<$Res, WatchHistory>;
  @useResult
  $Res call({List<WatchProgress> items, int totalCount});
}

/// @nodoc
class _$WatchHistoryCopyWithImpl<$Res, $Val extends WatchHistory>
    implements $WatchHistoryCopyWith<$Res> {
  _$WatchHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<WatchProgress>,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WatchHistoryImplCopyWith<$Res>
    implements $WatchHistoryCopyWith<$Res> {
  factory _$$WatchHistoryImplCopyWith(
          _$WatchHistoryImpl value, $Res Function(_$WatchHistoryImpl) then) =
      __$$WatchHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<WatchProgress> items, int totalCount});
}

/// @nodoc
class __$$WatchHistoryImplCopyWithImpl<$Res>
    extends _$WatchHistoryCopyWithImpl<$Res, _$WatchHistoryImpl>
    implements _$$WatchHistoryImplCopyWith<$Res> {
  __$$WatchHistoryImplCopyWithImpl(
      _$WatchHistoryImpl _value, $Res Function(_$WatchHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of WatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
  }) {
    return _then(_$WatchHistoryImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<WatchProgress>,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WatchHistoryImpl extends _WatchHistory {
  const _$WatchHistoryImpl(
      {final List<WatchProgress> items = const [], this.totalCount = 0})
      : _items = items,
        super._();

  factory _$WatchHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$WatchHistoryImplFromJson(json);

  final List<WatchProgress> _items;
  @override
  @JsonKey()
  List<WatchProgress> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int totalCount;

  @override
  String toString() {
    return 'WatchHistory(items: $items, totalCount: $totalCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WatchHistoryImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), totalCount);

  /// Create a copy of WatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WatchHistoryImplCopyWith<_$WatchHistoryImpl> get copyWith =>
      __$$WatchHistoryImplCopyWithImpl<_$WatchHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WatchHistoryImplToJson(
      this,
    );
  }
}

abstract class _WatchHistory extends WatchHistory {
  const factory _WatchHistory(
      {final List<WatchProgress> items,
      final int totalCount}) = _$WatchHistoryImpl;
  const _WatchHistory._() : super._();

  factory _WatchHistory.fromJson(Map<String, dynamic> json) =
      _$WatchHistoryImpl.fromJson;

  @override
  List<WatchProgress> get items;
  @override
  int get totalCount;

  /// Create a copy of WatchHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WatchHistoryImplCopyWith<_$WatchHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
