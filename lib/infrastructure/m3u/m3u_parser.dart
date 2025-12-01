// Kylos IPTV Player - M3U Parser
// Parser for M3U and M3U8 playlist files.

import 'package:dio/dio.dart';

/// Represents a parsed M3U entry.
class M3uEntry {
  const M3uEntry({
    required this.url,
    required this.title,
    this.duration = -1,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.tvgShift,
    this.radio = false,
    this.attributes = const {},
  });

  /// Stream URL.
  final String url;

  /// Display title.
  final String title;

  /// Duration in seconds (-1 for live streams).
  final int duration;

  /// EPG ID for program guide matching.
  final String? tvgId;

  /// TVG name (alternative name for EPG).
  final String? tvgName;

  /// Logo/icon URL.
  final String? tvgLogo;

  /// Category/group name.
  final String? groupTitle;

  /// Time shift in hours for EPG.
  final String? tvgShift;

  /// Whether this is a radio stream.
  final bool radio;

  /// Additional attributes from the EXTINF line.
  final Map<String, String> attributes;

  @override
  String toString() => 'M3uEntry($title, $url)';
}

/// Represents a parsed M3U playlist.
class M3uPlaylist {
  const M3uPlaylist({
    required this.entries,
    this.extM3u = true,
    this.epgUrl,
    this.attributes = const {},
  });

  /// All entries in the playlist.
  final List<M3uEntry> entries;

  /// Whether this is an extended M3U playlist.
  final bool extM3u;

  /// EPG URL if specified in the playlist header.
  final String? epgUrl;

  /// Additional playlist-level attributes.
  final Map<String, String> attributes;

  /// Gets all unique group titles.
  List<String> get groups {
    final groupSet = <String>{};
    for (final entry in entries) {
      if (entry.groupTitle != null && entry.groupTitle!.isNotEmpty) {
        groupSet.add(entry.groupTitle!);
      }
    }
    return groupSet.toList()..sort();
  }

  /// Gets entries for a specific group.
  List<M3uEntry> getEntriesByGroup(String groupTitle) {
    return entries.where((e) => e.groupTitle == groupTitle).toList();
  }

  /// Gets entries without a group.
  List<M3uEntry> get ungroupedEntries {
    return entries
        .where((e) => e.groupTitle == null || e.groupTitle!.isEmpty)
        .toList();
  }
}

/// Parser for M3U playlist files.
class M3uParser {
  M3uParser({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // Regular expressions for parsing
  static final _extM3uRegex = RegExp(r'^#EXTM3U');
  static final _extInfRegex = RegExp(r'^#EXTINF:(-?\d+)\s*,?\s*(.*)$');
  static final _attributeRegex = RegExp(r'(\w+[-\w]*)="([^"]*)"');
  static final _urlEpgRegex = RegExp(r'url-tvg="([^"]*)"');
  static final _xTvgUrlRegex = RegExp(r'x-tvg-url="([^"]*)"');

  /// Parses an M3U playlist from a URL.
  Future<M3uPlaylist> parseFromUrl(String url) async {
    final response = await _dio.get<String>(url);
    return parse(response.data ?? '');
  }

  /// Parses an M3U playlist from content string.
  M3uPlaylist parse(String content) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    final entries = <M3uEntry>[];
    var isExtM3u = false;
    String? epgUrl;
    final playlistAttributes = <String, String>{};

    String? currentExtInf;
    int currentDuration = -1;
    Map<String, String> currentAttributes = {};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isEmpty) continue;

      // Check for #EXTM3U header
      if (_extM3uRegex.hasMatch(line)) {
        isExtM3u = true;

        // Extract EPG URL from header
        final urlEpgMatch = _urlEpgRegex.firstMatch(line);
        if (urlEpgMatch != null) {
          epgUrl = urlEpgMatch.group(1);
        }
        final xTvgUrlMatch = _xTvgUrlRegex.firstMatch(line);
        if (xTvgUrlMatch != null) {
          epgUrl ??= xTvgUrlMatch.group(1);
        }

        // Extract other header attributes
        for (final match in _attributeRegex.allMatches(line)) {
          playlistAttributes[match.group(1)!] = match.group(2)!;
        }
        continue;
      }

      // Parse #EXTINF line
      if (line.startsWith('#EXTINF:')) {
        final match = _extInfRegex.firstMatch(line);
        if (match != null) {
          currentDuration = int.tryParse(match.group(1) ?? '-1') ?? -1;
          currentExtInf = match.group(2) ?? '';

          // Extract attributes from the EXTINF line
          currentAttributes = {};
          for (final attrMatch in _attributeRegex.allMatches(line)) {
            currentAttributes[attrMatch.group(1)!] = attrMatch.group(2)!;
          }
        }
        continue;
      }

      // Skip other directives
      if (line.startsWith('#')) continue;

      // This should be a URL
      if (currentExtInf != null || !isExtM3u) {
        final title = _extractTitle(currentExtInf ?? '', currentAttributes);

        entries.add(M3uEntry(
          url: line,
          title: title,
          duration: currentDuration,
          tvgId: currentAttributes['tvg-id'],
          tvgName: currentAttributes['tvg-name'],
          tvgLogo: currentAttributes['tvg-logo'],
          groupTitle: currentAttributes['group-title'],
          tvgShift: currentAttributes['tvg-shift'],
          radio: currentAttributes['radio'] == 'true',
          attributes: Map.from(currentAttributes),
        ));

        // Reset for next entry
        currentExtInf = null;
        currentDuration = -1;
        currentAttributes = {};
      }
    }

    return M3uPlaylist(
      entries: entries,
      extM3u: isExtM3u,
      epgUrl: epgUrl,
      attributes: playlistAttributes,
    );
  }

  /// Extracts the title from EXTINF line content.
  String _extractTitle(String extinf, Map<String, String> attributes) {
    // If tvg-name is available, use it
    if (attributes.containsKey('tvg-name') &&
        attributes['tvg-name']!.isNotEmpty) {
      return attributes['tvg-name']!;
    }

    // Otherwise, extract the title after the comma
    // Remove all attributes from the string
    var title = extinf;

    // Remove attribute patterns
    title = title.replaceAll(_attributeRegex, '');

    // Clean up and trim
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove leading comma if present
    if (title.startsWith(',')) {
      title = title.substring(1).trim();
    }

    return title.isNotEmpty ? title : 'Unknown';
  }

  /// Disposes the HTTP client.
  void dispose() {
    _dio.close();
  }
}
