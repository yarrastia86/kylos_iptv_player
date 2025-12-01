// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Season {
  int get seasonNumber => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get plot => throw _privateConstructorUsedError;
  String? get releaseDate => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  List<Episode> get episodes => throw _privateConstructorUsedError;

  /// Create a copy of Season
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonCopyWith<Season> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonCopyWith<$Res> {
  factory $SeasonCopyWith(Season value, $Res Function(Season) then) =
      _$SeasonCopyWithImpl<$Res, Season>;
  @useResult
  $Res call(
      {int seasonNumber,
      String name,
      String? plot,
      String? releaseDate,
      String? coverUrl,
      List<Episode> episodes});
}

/// @nodoc
class _$SeasonCopyWithImpl<$Res, $Val extends Season>
    implements $SeasonCopyWith<$Res> {
  _$SeasonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Season
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonNumber = null,
    Object? name = null,
    Object? plot = freezed,
    Object? releaseDate = freezed,
    Object? coverUrl = freezed,
    Object? episodes = null,
  }) {
    return _then(_value.copyWith(
      seasonNumber: null == seasonNumber
          ? _value.seasonNumber
          : seasonNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      plot: freezed == plot
          ? _value.plot
          : plot // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      episodes: null == episodes
          ? _value.episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<Episode>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SeasonImplCopyWith<$Res> implements $SeasonCopyWith<$Res> {
  factory _$$SeasonImplCopyWith(
          _$SeasonImpl value, $Res Function(_$SeasonImpl) then) =
      __$$SeasonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int seasonNumber,
      String name,
      String? plot,
      String? releaseDate,
      String? coverUrl,
      List<Episode> episodes});
}

/// @nodoc
class __$$SeasonImplCopyWithImpl<$Res>
    extends _$SeasonCopyWithImpl<$Res, _$SeasonImpl>
    implements _$$SeasonImplCopyWith<$Res> {
  __$$SeasonImplCopyWithImpl(
      _$SeasonImpl _value, $Res Function(_$SeasonImpl) _then)
      : super(_value, _then);

  /// Create a copy of Season
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonNumber = null,
    Object? name = null,
    Object? plot = freezed,
    Object? releaseDate = freezed,
    Object? coverUrl = freezed,
    Object? episodes = null,
  }) {
    return _then(_$SeasonImpl(
      seasonNumber: null == seasonNumber
          ? _value.seasonNumber
          : seasonNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      plot: freezed == plot
          ? _value.plot
          : plot // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      episodes: null == episodes
          ? _value._episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<Episode>,
    ));
  }
}

/// @nodoc

class _$SeasonImpl implements _Season {
  const _$SeasonImpl(
      {required this.seasonNumber,
      required this.name,
      this.plot,
      this.releaseDate,
      this.coverUrl,
      final List<Episode> episodes = const []})
      : _episodes = episodes;

  @override
  final int seasonNumber;
  @override
  final String name;
  @override
  final String? plot;
  @override
  final String? releaseDate;
  @override
  final String? coverUrl;
  final List<Episode> _episodes;
  @override
  @JsonKey()
  List<Episode> get episodes {
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_episodes);
  }

  @override
  String toString() {
    return 'Season(seasonNumber: $seasonNumber, name: $name, plot: $plot, releaseDate: $releaseDate, coverUrl: $coverUrl, episodes: $episodes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonImpl &&
            (identical(other.seasonNumber, seasonNumber) ||
                other.seasonNumber == seasonNumber) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.plot, plot) || other.plot == plot) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, seasonNumber, name, plot,
      releaseDate, coverUrl, const DeepCollectionEquality().hash(_episodes));

  /// Create a copy of Season
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonImplCopyWith<_$SeasonImpl> get copyWith =>
      __$$SeasonImplCopyWithImpl<_$SeasonImpl>(this, _$identity);
}

abstract class _Season implements Season {
  const factory _Season(
      {required final int seasonNumber,
      required final String name,
      final String? plot,
      final String? releaseDate,
      final String? coverUrl,
      final List<Episode> episodes}) = _$SeasonImpl;

  @override
  int get seasonNumber;
  @override
  String get name;
  @override
  String? get plot;
  @override
  String? get releaseDate;
  @override
  String? get coverUrl;
  @override
  List<Episode> get episodes;

  /// Create a copy of Season
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonImplCopyWith<_$SeasonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SeriesInfo {
  Series get info => throw _privateConstructorUsedError;
  List<Season> get seasons => throw _privateConstructorUsedError;

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeriesInfoCopyWith<SeriesInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeriesInfoCopyWith<$Res> {
  factory $SeriesInfoCopyWith(
          SeriesInfo value, $Res Function(SeriesInfo) then) =
      _$SeriesInfoCopyWithImpl<$Res, SeriesInfo>;
  @useResult
  $Res call({Series info, List<Season> seasons});

  $SeriesCopyWith<$Res> get info;
}

/// @nodoc
class _$SeriesInfoCopyWithImpl<$Res, $Val extends SeriesInfo>
    implements $SeriesInfoCopyWith<$Res> {
  _$SeriesInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? seasons = null,
  }) {
    return _then(_value.copyWith(
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Series,
      seasons: null == seasons
          ? _value.seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as List<Season>,
    ) as $Val);
  }

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SeriesCopyWith<$Res> get info {
    return $SeriesCopyWith<$Res>(_value.info, (value) {
      return _then(_value.copyWith(info: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SeriesInfoImplCopyWith<$Res>
    implements $SeriesInfoCopyWith<$Res> {
  factory _$$SeriesInfoImplCopyWith(
          _$SeriesInfoImpl value, $Res Function(_$SeriesInfoImpl) then) =
      __$$SeriesInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Series info, List<Season> seasons});

  @override
  $SeriesCopyWith<$Res> get info;
}

/// @nodoc
class __$$SeriesInfoImplCopyWithImpl<$Res>
    extends _$SeriesInfoCopyWithImpl<$Res, _$SeriesInfoImpl>
    implements _$$SeriesInfoImplCopyWith<$Res> {
  __$$SeriesInfoImplCopyWithImpl(
      _$SeriesInfoImpl _value, $Res Function(_$SeriesInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? seasons = null,
  }) {
    return _then(_$SeriesInfoImpl(
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as Series,
      seasons: null == seasons
          ? _value._seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as List<Season>,
    ));
  }
}

/// @nodoc

class _$SeriesInfoImpl implements _SeriesInfo {
  const _$SeriesInfoImpl(
      {required this.info, required final List<Season> seasons})
      : _seasons = seasons;

  @override
  final Series info;
  final List<Season> _seasons;
  @override
  List<Season> get seasons {
    if (_seasons is EqualUnmodifiableListView) return _seasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seasons);
  }

  @override
  String toString() {
    return 'SeriesInfo(info: $info, seasons: $seasons)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeriesInfoImpl &&
            (identical(other.info, info) || other.info == info) &&
            const DeepCollectionEquality().equals(other._seasons, _seasons));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, info, const DeepCollectionEquality().hash(_seasons));

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeriesInfoImplCopyWith<_$SeriesInfoImpl> get copyWith =>
      __$$SeriesInfoImplCopyWithImpl<_$SeriesInfoImpl>(this, _$identity);
}

abstract class _SeriesInfo implements SeriesInfo {
  const factory _SeriesInfo(
      {required final Series info,
      required final List<Season> seasons}) = _$SeriesInfoImpl;

  @override
  Series get info;
  @override
  List<Season> get seasons;

  /// Create a copy of SeriesInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeriesInfoImplCopyWith<_$SeriesInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
