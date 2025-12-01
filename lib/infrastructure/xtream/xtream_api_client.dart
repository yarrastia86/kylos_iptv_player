// Kylos IPTV Player - Xtream API Client
// Client for interacting with Xtream Codes API.

import 'package:dio/dio.dart';
import 'package:kylos_iptv_player/features/playlists/domain/value_objects/xtream_credentials.dart';

/// Response from Xtream API authentication.
class XtreamAuthInfo {
  const XtreamAuthInfo({
    required this.username,
    required this.password,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.activeCons,
    required this.maxConnections,
    required this.createdAt,
  });

  final String username;
  final String password;
  final String status;
  final DateTime? expDate;
  final bool isTrial;
  final int activeCons;
  final int maxConnections;
  final DateTime? createdAt;

  factory XtreamAuthInfo.fromJson(Map<String, dynamic> json) {
    final userInfo = json['user_info'] as Map<String, dynamic>?;
    if (userInfo == null) {
      throw Exception('Invalid auth response: missing user_info');
    }

    return XtreamAuthInfo(
      username: userInfo['username']?.toString() ?? '',
      password: userInfo['password']?.toString() ?? '',
      status: userInfo['status']?.toString() ?? '',
      expDate: userInfo['exp_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (int.tryParse(userInfo['exp_date'].toString()) ?? 0) * 1000,
            )
          : null,
      isTrial: userInfo['is_trial'] == '1' || userInfo['is_trial'] == true,
      activeCons: int.tryParse(userInfo['active_cons']?.toString() ?? '0') ?? 0,
      maxConnections:
          int.tryParse(userInfo['max_connections']?.toString() ?? '1') ?? 1,
      createdAt: userInfo['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (int.tryParse(userInfo['created_at'].toString()) ?? 0) * 1000,
            )
          : null,
    );
  }

  bool get isActive => status == 'Active';
  bool get isExpired =>
      expDate != null && DateTime.now().isAfter(expDate!);
}

/// Live stream category from Xtream API.
class XtreamCategory {
  const XtreamCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  final String categoryId;
  final String categoryName;
  final String? parentId;

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
    );
  }
}

/// Live stream from Xtream API.
class XtreamStream {
  const XtreamStream({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.epgChannelId,
    required this.categoryId,
    this.streamType,
    this.num,
  });

  final int streamId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final String categoryId;
  final String? streamType;
  final int? num;

  factory XtreamStream.fromJson(Map<String, dynamic> json) {
    return XtreamStream(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      streamType: json['stream_type']?.toString(),
      num: int.tryParse(json['num']?.toString() ?? ''),
    );
  }
}

/// VOD stream from Xtream API.
class XtreamVodStream {
  const XtreamVodStream({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.categoryId,
    this.rating,
    this.releaseDate,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.duration,
    this.containerExtension,
  });

  final int streamId;
  final String name;
  final String? streamIcon;
  final String categoryId;
  final String? rating;
  final String? releaseDate;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? duration;
  final String? containerExtension;

  factory XtreamVodStream.fromJson(Map<String, dynamic> json) {
    return XtreamVodStream(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      rating: json['rating']?.toString(),
      releaseDate: json['release_date']?.toString(),
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      duration: json['duration']?.toString(),
      containerExtension: json['container_extension']?.toString(),
    );
  }
}

/// Series from Xtream API.
class XtreamSeries {
  const XtreamSeries({
    required this.seriesId,
    required this.name,
    required this.cover,
    required this.categoryId,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.rating,
    this.lastModified,
  });

  final int seriesId;
  final String name;
  final String? cover;
  final String categoryId;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final String? rating;
  final String? lastModified;

  factory XtreamSeries.fromJson(Map<String, dynamic> json) {
    return XtreamSeries(
      seriesId: int.tryParse(json['series_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      cover: json['cover']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      rating: json['rating']?.toString(),
      lastModified: json['last_modified']?.toString(),
    );
  }
}

/// Client for Xtream Codes API.
class XtreamApiClient {
  XtreamApiClient({
    required this.credentials,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final XtreamCredentials credentials;
  final Dio _dio;

  String get _baseUrl => credentials.serverUrl.value;
  String get _username => credentials.username;
  String get _password => credentials.password;

  /// Builds the API URL for a given action.
  String _buildApiUrl(String action) {
    return '$_baseUrl/player_api.php?username=$_username&password=$_password&action=$action';
  }

  /// Builds the stream URL for live streams.
  String buildLiveStreamUrl(int streamId, {String extension = 'ts'}) {
    return '$_baseUrl/live/$_username/$_password/$streamId.$extension';
  }

  /// Builds the stream URL for VOD.
  String buildVodStreamUrl(int streamId, String containerExtension) {
    return '$_baseUrl/movie/$_username/$_password/$streamId.$containerExtension';
  }

  /// Builds the stream URL for series episodes.
  String buildSeriesStreamUrl(int streamId, String containerExtension) {
    return '$_baseUrl/series/$_username/$_password/$streamId.$containerExtension';
  }

  /// Authenticates with the Xtream server.
  Future<XtreamAuthInfo> authenticate() async {
    final url = _buildApiUrl('');
    final response = await _dio.get<Map<String, dynamic>>(url);
    return XtreamAuthInfo.fromJson(response.data!);
  }

  /// Gets live stream categories.
  Future<List<XtreamCategory>> getLiveCategories() async {
    final url = _buildApiUrl('get_live_categories');
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets all live streams.
  Future<List<XtreamStream>> getLiveStreams({String? categoryId}) async {
    var url = _buildApiUrl('get_live_streams');
    if (categoryId != null) {
      url += '&category_id=$categoryId';
    }
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamStream.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets VOD categories.
  Future<List<XtreamCategory>> getVodCategories() async {
    final url = _buildApiUrl('get_vod_categories');
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets all VOD streams.
  Future<List<XtreamVodStream>> getVodStreams({String? categoryId}) async {
    var url = _buildApiUrl('get_vod_streams');
    if (categoryId != null) {
      url += '&category_id=$categoryId';
    }
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamVodStream.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets series categories.
  Future<List<XtreamCategory>> getSeriesCategories() async {
    final url = _buildApiUrl('get_series_categories');
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets all series.
  Future<List<XtreamSeries>> getSeries({String? categoryId}) async {
    var url = _buildApiUrl('get_series');
    if (categoryId != null) {
      url += '&category_id=$categoryId';
    }
    final response = await _dio.get<List<dynamic>>(url);
    return (response.data ?? [])
        .map((item) => XtreamSeries.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Gets series info with seasons and episodes.
  Future<Map<String, dynamic>> getSeriesInfo(int seriesId) async {
    final url = '${_buildApiUrl('get_series_info')}&series_id=$seriesId';
    final response = await _dio.get<Map<String, dynamic>>(url);
    return response.data ?? {};
  }

  /// Gets VOD info.
  Future<Map<String, dynamic>> getVodInfo(int vodId) async {
    final url = '${_buildApiUrl('get_vod_info')}&vod_id=$vodId';
    final response = await _dio.get<Map<String, dynamic>>(url);
    return response.data ?? {};
  }

  /// Gets short EPG for a stream.
  Future<Map<String, dynamic>> getShortEpg(int streamId, {int limit = 4}) async {
    final url =
        '${_buildApiUrl('get_short_epg')}&stream_id=$streamId&limit=$limit';
    final response = await _dio.get<Map<String, dynamic>>(url);
    return response.data ?? {};
  }

  /// Disposes the HTTP client.
  void dispose() {
    _dio.close();
  }
}
