import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/media_server.dart';
import '../models/media_server_library.dart';
import '../models/media_server_watch_state.dart';
import 'diagnostic_log.dart';

/// Plex Media Server HTTP client.
///
/// API shapes and auth flow follow the patterns used by plex-for-kodi
/// (pannal/plex-for-kodi → plexnet): X-Plex-* headers, plex.tv sign-in for a
/// user token, then the same token against a local/remote PMS.
///
/// Responses are mapped into the Jellyfin-shaped maps that
/// [MediaServerLibraryItem] / [MediaServerWatchState] already understand so
/// the rest of the media-server stack stays shared.
class PlexClient {
  PlexClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _product = 'Debrify';
  static const _version = '1.0';
  static const _plexTv = 'https://plex.tv';

  void close() => _client.close();

  // ---------------------------------------------------------------------------
  // Headers / URL helpers
  // ---------------------------------------------------------------------------

  static Map<String, String> headers({
    required String deviceId,
    String? token,
    bool json = true,
  }) {
    if (token != null &&
        !RegExp(r'^[a-zA-Z0-9._~+/-]+=*$').hasMatch(token)) {
      throw const MediaServerException(
        'The server returned an invalid session token. Reconnect this server.',
      );
    }
    return {
      if (json) 'Accept': 'application/json',
      'X-Plex-Product': _product,
      'X-Plex-Version': _version,
      'X-Plex-Client-Identifier': deviceId,
      'X-Plex-Platform': 'Debrify',
      'X-Plex-Device': 'Debrify',
      'X-Plex-Device-Name': 'Debrify',
      'X-Plex-Provides': 'player',
      if (token != null) 'X-Plex-Token': token,
    };
  }

  static Uri normalizeBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const MediaServerException(
        'Enter an HTTP or HTTPS server URL without credentials or query parameters.',
      );
    }
    return uri.replace(path: '${uri.path.replaceAll(RegExp(r'/+$'), '')}/');
  }

  static Uri endpoint(
    String baseUrl,
    String path, [
    Map<String, String>? query,
  ]) {
    final base = normalizeBaseUrl(baseUrl);
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    return base.resolve(cleaned).replace(queryParameters: query);
  }

  static String _segment(String value) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      throw const MediaServerException(
        'The server returned an invalid item identifier.',
      );
    }
    return value;
  }

  /// Direct-play URL for a Plex Part key (e.g. `/library/parts/123/file.mkv`).
  static Uri playbackUrl(MediaServerAccount account, String partKey) {
    final key = partKey.startsWith('/') ? partKey.substring(1) : partKey;
    return endpoint(account.baseUrl, key, {
      'X-Plex-Token': account.token,
      'X-Plex-Client-Identifier': account.deviceId,
    });
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Sign in via plex.tv, then verify the token against the given PMS.
  Future<MediaServerAccount> login({
    required String baseUrl,
    required String username,
    required String password,
    required String deviceId,
    Future<void> Function()? authorize,
  }) async {
    await authorize?.call();
    // 1) Obtain a user token from plex.tv (same flow as plex-for-kodi / MyPlex).
    final signInUri = Uri.parse('$_plexTv/users/sign_in.json');
    final signInRequest = http.Request('POST', signInUri)
      ..followRedirects = false
      ..headers.addAll({
        ...headers(deviceId: deviceId),
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      })
      ..bodyFields = {
        'user[login]': username.trim(),
        'user[password]': password,
      };

    final signInResponse = await _send(signInRequest);
    if (signInResponse.statusCode == 401 || signInResponse.statusCode == 403) {
      throw const MediaServerException(
        'Plex sign-in failed. Check your username and password.',
      );
    }
    if (signInResponse.statusCode < 200 || signInResponse.statusCode >= 300) {
      throw MediaServerException(
        'Plex sign-in failed (HTTP ${signInResponse.statusCode}).',
      );
    }
    final signInBody = jsonDecode(utf8.decode(signInResponse.bodyBytes));
    final user = signInBody is Map ? signInBody['user'] : null;
    final token = user is Map ? user['authToken'] as String? : null;
    final userId = user is Map
        ? (user['id']?.toString() ?? user['uuid']?.toString())
        : null;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw const MediaServerException(
        'Plex returned an incomplete sign-in response.',
      );
    }

    return _accountFromToken(
      baseUrl: baseUrl,
      token: token,
      deviceId: deviceId,
      userId: userId,
      authorize: authorize,
    );
  }

  /// Connect with an existing X-Plex-Token only (no plex.tv password).
  ///
  /// Token sources: Plex Web → account → authorized devices, or PMS settings,
  /// or any client that already holds a valid server/user token.
  Future<MediaServerAccount> loginWithToken({
    required String baseUrl,
    required String token,
    required String deviceId,
    Future<void> Function()? authorize,
  }) async {
    final cleaned = token.trim();
    if (cleaned.isEmpty) {
      throw const MediaServerException('Enter a Plex token.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._~+/-]+=*$').hasMatch(cleaned)) {
      throw const MediaServerException(
        'That does not look like a valid Plex token.',
      );
    }
    return _accountFromToken(
      baseUrl: baseUrl,
      token: cleaned,
      deviceId: deviceId,
      userId: null,
      authorize: authorize,
    );
  }

  /// Verify [token] against PMS identity + library access and build an account.
  Future<MediaServerAccount> _accountFromToken({
    required String baseUrl,
    required String token,
    required String deviceId,
    String? userId,
    Future<void> Function()? authorize,
  }) async {
    await authorize?.call();
    final base = normalizeBaseUrl(baseUrl).toString();

    final identity = await _getJson(
      base,
      'identity',
      deviceId: deviceId,
      token: token,
      authorize: authorize,
    );
    final serverId = identity['MediaContainer'] is Map
        ? (identity['MediaContainer'] as Map)['machineIdentifier'] as String?
        : identity['machineIdentifier'] as String?;
    if (serverId == null || serverId.isEmpty) {
      throw const MediaServerException(
        'Could not read this Plex server identity. Check the URL and that the server is reachable.',
      );
    }

    // Confirm libraries are readable with this token.
    await _getJson(
      base,
      'library/sections',
      deviceId: deviceId,
      token: token,
      authorize: authorize,
    );

    // Prefer an explicit plex.tv user id when we have one; otherwise use a
    // stable placeholder derived from the server so MediaServerAccount stays
    // well-formed (userId is required by the shared model).
    final resolvedUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : 'plex-token';

    return MediaServerAccount(
      kind: MediaServerKind.plex,
      baseUrl: base,
      userId: resolvedUserId,
      token: token,
      serverId: serverId,
      deviceId: deviceId,
    );
  }

  Future<void> testConnection(
    MediaServerAccount account, {
    Future<void> Function()? authorize,
  }) async {
    final identity = await _getJson(
      account.baseUrl,
      'identity',
      deviceId: account.deviceId,
      token: account.token,
      authorize: authorize,
    );
    final container = identity['MediaContainer'];
    final serverId = container is Map
        ? container['machineIdentifier'] as String?
        : identity['machineIdentifier'] as String?;
    if (serverId != account.serverId) {
      throw const MediaServerException(
        'The server identity changed. Reconnect this server.',
      );
    }
    await _getJson(
      account.baseUrl,
      'library/sections',
      deviceId: account.deviceId,
      token: account.token,
      authorize: authorize,
    );
  }

  // ---------------------------------------------------------------------------
  // Library browse
  // ---------------------------------------------------------------------------

  Future<MediaServerLibraryPage> library(
    MediaServerAccount account, {
    String? parentId,
    String search = '',
    int offset = 0,
    int limit = 50,
    Future<void> Function()? authorize,
  }) async {
    if (search.trim().isNotEmpty) {
      // Global hub search.
      final data = await _getJson(
        account.baseUrl,
        'hubs/search',
        deviceId: account.deviceId,
        token: account.token,
        query: {
          'query': search.trim(),
          'limit': '$limit',
        },
        authorize: authorize,
      );
      final hubs = _containerChildren(data);
      final items = <Map<String, dynamic>>[];
      for (final hub in hubs) {
        final meta = hub['Metadata'];
        if (meta is! List) continue;
        for (final row in meta) {
          if (row is Map<String, dynamic>) {
            items.add(mapMetadata(row));
          }
        }
      }
      final page = items.skip(offset).take(limit).toList();
      return MediaServerLibraryPage(
        page.map(MediaServerLibraryItem.fromJson).toList(),
        offset + page.length < items.length ? offset + page.length : null,
      );
    }

    if (parentId == null || parentId.isEmpty) {
      // Top-level library sections.
      final data = await _getJson(
        account.baseUrl,
        'library/sections',
        deviceId: account.deviceId,
        token: account.token,
        authorize: authorize,
      );
      final dirs = _containerChildren(data, key: 'Directory');
      final items = dirs.map((d) {
        final id = d['key']?.toString() ?? d['uuid']?.toString() ?? '';
        final type = d['type']?.toString() ?? 'folder';
        return mapSection(d, id: id, type: type);
      }).toList();
      return MediaServerLibraryPage(
        items.map(MediaServerLibraryItem.fromJson).toList(),
        null,
      );
    }

    // Browse a section or a metadata container (show → seasons → episodes).
    Future<MediaServerLibraryPage> load(String path) async {
      final data = await _getJson(
        account.baseUrl,
        path,
        deviceId: account.deviceId,
        token: account.token,
        query: {
          'X-Plex-Container-Start': '$offset',
          'X-Plex-Container-Size': '$limit',
          'includeGuids': '1',
        },
        authorize: authorize,
      );
      final rows = _containerChildren(data);
      final total = _containerAttr(data, 'totalSize') ??
          _containerAttr(data, 'size');
      final items = rows.map(mapMetadata).toList();
      final next = total != null && offset + items.length < total
          ? offset + items.length
          : (items.length >= limit ? offset + items.length : null);
      return MediaServerLibraryPage(
        items.map(MediaServerLibraryItem.fromJson).toList(),
        next,
      );
    }

    if (parentId.startsWith('library/')) {
      return load(parentId);
    }
    if (parentId.contains('/')) {
      final path = parentId.startsWith('/') ? parentId.substring(1) : parentId;
      return load(path);
    }

    // Section id from the libraries dropdown → /library/sections/{id}/all.
    // Trail drill-in (show/season ratingKey) → /library/metadata/{id}/children.
    // Try section first; if PMS returns nothing useful, fall back to children.
    try {
      final sectionPage = await load(
        'library/sections/${_segment(parentId)}/all',
      );
      if (sectionPage.items.isNotEmpty || offset > 0) {
        return sectionPage;
      }
    } on MediaServerException {
      // Fall through to metadata children.
    }
    return load('library/metadata/${_segment(parentId)}/children');
  }

  Future<MediaServerLibraryItem> libraryItem(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    final data = await _getJson(
      account.baseUrl,
      'library/metadata/${_segment(itemId)}',
      deviceId: account.deviceId,
      token: account.token,
      query: {'includeGuids': '1'},
      authorize: authorize,
    );
    final rows = _containerChildren(data);
    if (rows.isEmpty) {
      throw const MediaServerException('The server returned no item.');
    }
    return MediaServerLibraryItem.fromJson(mapMetadata(rows.first));
  }

  Future<Uint8List?> libraryImage(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    await authorize?.call();
    // Prefer the primary thumb from metadata, then fall back to a synthetic path.
    Map<String, dynamic>? meta;
    try {
      final data = await _getJson(
        account.baseUrl,
        'library/metadata/${_segment(itemId)}',
        deviceId: account.deviceId,
        token: account.token,
        authorize: authorize,
      );
      final rows = _containerChildren(data);
      if (rows.isNotEmpty) meta = rows.first;
    } catch (_) {}
    final thumb = meta?['thumb'] as String? ??
        meta?['composite'] as String? ??
        '/library/metadata/${_segment(itemId)}/thumb';
    final uri = endpoint(account.baseUrl, thumb.startsWith('/')
        ? thumb.substring(1)
        : thumb, {
      'X-Plex-Token': account.token,
      'width': '400',
      'height': '600',
      'minSize': '1',
    });
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(headers(deviceId: account.deviceId, token: account.token));
    final response = await _send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return response.bodyBytes;
  }

  // ---------------------------------------------------------------------------
  // Playback sources
  // ---------------------------------------------------------------------------

  /// Returns media maps shaped like Jellyfin MediaSources for the shared
  /// [MediaServerService] torrent builder.
  Future<List<Map<String, dynamic>>> mediaSources(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    final data = await _getJson(
      account.baseUrl,
      'library/metadata/${_segment(itemId)}',
      deviceId: account.deviceId,
      token: account.token,
      query: {'includeGuids': '1'},
      authorize: authorize,
    );
    final rows = _containerChildren(data);
    if (rows.isEmpty) {
      throw const MediaServerException(
        'The server returned no playback information.',
      );
    }
    final meta = rows.first;
    final mediaList = meta['Media'];
    if (mediaList is! List || mediaList.isEmpty) {
      throw const MediaServerException(
        'The server returned no playable media for this item.',
      );
    }
    final sources = <Map<String, dynamic>>[];
    for (final media in mediaList) {
      if (media is! Map) continue;
      final parts = media['Part'];
      if (parts is! List || parts.isEmpty) continue;
      for (final part in parts) {
        if (part is! Map) continue;
        final partId = part['id']?.toString() ?? '';
        final partKey = part['key']?.toString() ?? '';
        if (partId.isEmpty || partKey.isEmpty) continue;
        final streams = part['Stream'];
        final videoStream = streams is List
            ? streams.cast<dynamic>().whereType<Map>().firstWhere(
                (s) => s['streamType'] == 1 || s['StreamType'] == 1,
                orElse: () => const {},
              )
            : const <String, dynamic>{};
        final audioStreams = streams is List
            ? streams
                .cast<dynamic>()
                .whereType<Map>()
                .where((s) =>
                    s['streamType'] == 2 || s['StreamType'] == 2)
                .toList()
            : const <Map>[];
        sources.add({
          'Id': partId,
          'Path': partKey,
          'Container': media['container'] ?? part['container'],
          'Size': part['size'] ?? media['size'],
          'Bitrate': media['bitrate'] ?? part['bitrate'],
          'Width': media['width'] ?? videoStream['width'],
          'Height': media['height'] ?? videoStream['height'],
          'VideoCodec': media['videoCodec'] ?? videoStream['codec'],
          'AudioCodec': media['audioCodec'],
          'VideoRange': videoStream['colorSpace'] ??
              videoStream['colorTrc'] ??
              media['videoResolution'],
          'MediaStreams': [
            for (final a in audioStreams)
              {
                'Type': 'Audio',
                'Language': a['language'] ?? a['languageTag'] ?? a['languageCode'],
                'DisplayTitle': a['displayTitle'] ?? a['extendedDisplayTitle'],
              },
          ],
          // Plex-specific: the path needed to build a direct-play URL.
          '_plexPartKey': partKey,
        });
      }
    }
    if (sources.isEmpty) {
      throw const MediaServerException(
        'The server returned no playable media for this item.',
      );
    }
    return sources;
  }

  // ---------------------------------------------------------------------------
  // Provider-ID lookup (Sources matching)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> findItems(
    MediaServerAccount account, {
    required String provider,
    required String providerId,
    required bool isMovie,
    int? season,
    int? episode,
    Future<void> Function()? authorize,
    DateTime? deadline,
  }) async {
    final guids = _guidCandidates(provider, providerId);
    final matches = <Map<String, dynamic>>[];
    for (final guid in guids) {
      if (deadline != null && DateTime.now().isAfter(deadline)) break;
      final data = await _getJson(
        account.baseUrl,
        'library/all',
        deviceId: account.deviceId,
        token: account.token,
        query: {
          'guid': guid,
          'type': isMovie ? '1' : '2', // 1=movie, 2=show
          'includeGuids': '1',
        },
        authorize: authorize,
      );
      for (final row in _containerChildren(data)) {
        matches.add(mapMetadata(row));
      }
      if (matches.isNotEmpty) break;
    }
    if (isMovie) {
      return matches.where((m) => m['Type'] == 'Movie').toList();
    }
    // Expand shows → matching season/episode.
    final episodes = <Map<String, dynamic>>[];
    for (final series in matches) {
      if (deadline != null && DateTime.now().isAfter(deadline)) break;
      final showId = series['Id'] as String?;
      if (showId == null) continue;
      final data = await _getJson(
        account.baseUrl,
        'library/metadata/${_segment(showId)}/allLeaves',
        deviceId: account.deviceId,
        token: account.token,
        query: {
          if (season != null) 'parentIndex': '$season',
          'includeGuids': '1',
        },
        authorize: authorize,
      );
      for (final row in _containerChildren(data)) {
        final mapped = mapMetadata(row);
        if (mapped['Type'] != 'Episode') continue;
        if (season != null && mapped['ParentIndexNumber'] != season) continue;
        if (episode != null) {
          final start = mapped['IndexNumber'] as int?;
          final end = mapped['IndexNumberEnd'] as int? ?? start;
          if (start == null || episode < start || episode > (end ?? start)) {
            continue;
          }
        }
        episodes.add(mapped);
      }
    }
    return episodes;
  }

  // ---------------------------------------------------------------------------
  // Watch state / progress
  // ---------------------------------------------------------------------------

  Future<MediaServerWatchState> watchState(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    final item = await libraryItem(account, itemId, authorize: authorize);
    return MediaServerWatchState.fromItem(item.data);
  }

  Future<void> reportWatchProgress(
    MediaServerAccount account, {
    required String itemId,
    required String mediaSourceId,
    required String action, // start | progress | stop
    required int positionTicks,
    required int durationTicks,
    required bool paused,
    String? sessionId,
    Future<void> Function()? authorize,
  }) async {
    // Plex timeline: time/duration are milliseconds.
    final timeMs = (positionTicks / 10000).floor().clamp(0, 1 << 31);
    final durationMs = (durationTicks / 10000).floor().clamp(0, 1 << 31);
    final state = switch (action) {
      'start' => 'playing',
      'stop' => 'stopped',
      _ => paused ? 'paused' : 'playing',
    };
    await _getJson(
      account.baseUrl,
      ':/timeline',
      deviceId: account.deviceId,
      token: account.token,
      query: {
        'ratingKey': itemId,
        'key': '/library/metadata/$itemId',
        'state': state,
        'time': '$timeMs',
        'duration': '$durationMs',
        'X-Plex-Client-Identifier': account.deviceId,
        if (sessionId != null) 'playQueueItemID': sessionId,
      },
      authorize: authorize,
      allowEmpty: true,
    );
  }

  Future<void> markWatched(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    await _getJson(
      account.baseUrl,
      ':/scrobble',
      deviceId: account.deviceId,
      token: account.token,
      query: {
        'key': itemId,
        'identifier': 'com.plexapp.plugins.library',
      },
      authorize: authorize,
      allowEmpty: true,
    );
  }

  Future<void> markUnwatched(
    MediaServerAccount account,
    String itemId, {
    Future<void> Function()? authorize,
  }) async {
    await _getJson(
      account.baseUrl,
      ':/unscrobble',
      deviceId: account.deviceId,
      token: account.token,
      query: {
        'key': itemId,
        'identifier': 'com.plexapp.plugins.library',
      },
      authorize: authorize,
      allowEmpty: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers (Plex → Jellyfin-shaped maps)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> mapSection(
    Map row, {
    required String id,
    required String type,
  }) {
    final title = row['title']?.toString() ?? 'Library';
    final plexType = type.toLowerCase();
    final jfType = switch (plexType) {
      'movie' => 'CollectionFolder',
      'show' => 'CollectionFolder',
      'artist' => 'CollectionFolder',
      'photo' => 'CollectionFolder',
      _ => 'Folder',
    };
    return {
      'Id': id,
      'Name': title,
      'Type': jfType,
      'IsFolder': true,
      'ImageTags': {
        if (row['thumb'] != null) 'Primary': '1',
      },
      '_plexKey': row['key']?.toString(),
      '_plexType': plexType,
    };
  }

  static Map<String, dynamic> mapMetadata(Map row) {
    final type = (row['type']?.toString() ?? '').toLowerCase();
    final jfType = switch (type) {
      'movie' => 'Movie',
      'show' => 'Series',
      'season' => 'Season',
      'episode' => 'Episode',
      'folder' => 'Folder',
      'collection' => 'BoxSet',
      _ => type.isEmpty ? 'Folder' : type[0].toUpperCase() + type.substring(1),
    };
    final ratingKey = row['ratingKey']?.toString() ??
        row['key']?.toString()?.split('/').last ??
        '';
    final durationMs = (row['duration'] as num?)?.toInt() ?? 0;
    final viewOffset = (row['viewOffset'] as num?)?.toInt() ?? 0;
    final viewCount = (row['viewCount'] as num?)?.toInt() ?? 0;
    final lastViewed = row['lastViewedAt'];
    DateTime? lastPlayed;
    if (lastViewed is num) {
      lastPlayed = DateTime.fromMillisecondsSinceEpoch(
        lastViewed.toInt() * 1000,
        isUtc: true,
      );
    }
    final guids = <String, String>{};
    final guidList = row['Guid'];
    if (guidList is List) {
      for (final g in guidList) {
        if (g is Map && g['id'] is String) {
          final raw = g['id'] as String;
          final parts = raw.split('://');
          if (parts.length == 2) {
            guids[parts[0]] = parts[1];
          }
        }
      }
    }
    // Legacy single guid field (imdb://tt…, tmdb://…).
    final singleGuid = row['guid']?.toString();
    if (singleGuid != null && singleGuid.contains('://')) {
      final parts = singleGuid.split('://');
      if (parts.length == 2 && !guids.containsKey(parts[0])) {
        // Strip agent prefixes like `com.plexapp.agents.imdb://tt123?lang=en`
        var id = parts[1];
        final q = id.indexOf('?');
        if (q >= 0) id = id.substring(0, q);
        final agent = parts[0];
        if (agent.contains('imdb')) {
          guids['imdb'] = id;
        } else if (agent.contains('tmdb')) {
          guids['tmdb'] = id;
        } else if (agent.contains('tvdb')) {
          guids['tvdb'] = id;
        } else {
          guids[agent] = id;
        }
      }
    }

    final isFolder = const {
      'show',
      'season',
      'folder',
      'collection',
    }.contains(type);

    return {
      'Id': ratingKey,
      'Name': row['title']?.toString() ?? row['titleSort']?.toString() ?? '',
      'Type': jfType,
      'IsFolder': isFolder,
      'IsMissing': false,
      'IsPlaceHolder': false,
      'ProductionYear': (row['year'] as num?)?.toInt(),
      'ParentIndexNumber': (row['parentIndex'] as num?)?.toInt(),
      'IndexNumber': (row['index'] as num?)?.toInt(),
      'SeriesId': row['grandparentRatingKey']?.toString() ??
          (type == 'season' ? row['parentRatingKey']?.toString() : null),
      'SeriesName': row['grandparentTitle']?.toString() ??
          row['parentTitle']?.toString(),
      'RunTimeTicks': durationMs * 10000,
      'UserData': {
        'Played': viewCount > 0 && viewOffset <= 0,
        'PlaybackPositionTicks': viewOffset * 10000,
        if (lastPlayed != null)
          'LastPlayedDate': lastPlayed.toIso8601String(),
      },
      'ImageTags': {
        if (row['thumb'] != null || row['composite'] != null) 'Primary': '1',
      },
      'ProviderIds': guids,
      'Media': row['Media'],
      '_plexKey': row['key']?.toString(),
      '_plexType': type,
      '_plexThumb': row['thumb']?.toString(),
    };
  }

  static List<String> _guidCandidates(String provider, String providerId) {
    final p = provider.toLowerCase();
    final id = providerId.trim();
    final out = <String>[];
    if (p == 'imdb') {
      out.addAll([
        'imdb://$id',
        'com.plexapp.agents.imdb://$id?lang=en',
        'com.plexapp.agents.imdb://$id',
      ]);
    } else if (p == 'tmdb') {
      out.addAll([
        'tmdb://$id',
        'com.plexapp.agents.themoviedb://$id?lang=en',
        'com.plexapp.agents.themoviedb://$id',
      ]);
    } else if (p == 'tvdb') {
      out.addAll([
        'tvdb://$id',
        'com.plexapp.agents.thetvdb://$id?lang=en',
        'com.plexapp.agents.thetvdb://$id',
      ]);
    } else {
      out.add('$p://$id');
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // HTTP
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _containerChildren(
    Map<String, dynamic> data, {
    String key = 'Metadata',
  }) {
    final container = data['MediaContainer'];
    if (container is! Map) return const [];
    final rows = container[key] ?? container['Directory'] ?? container['Metadata'];
    if (rows is! List) return const [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int? _containerAttr(Map<String, dynamic> data, String name) {
    final container = data['MediaContainer'];
    if (container is! Map) return null;
    final v = container[name];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<Map<String, dynamic>> _getJson(
    String baseUrl,
    String path, {
    required String deviceId,
    String? token,
    Map<String, String>? query,
    Future<void> Function()? authorize,
    bool allowEmpty = false,
  }) async {
    await authorize?.call();
    final uri = endpoint(baseUrl, path, query);
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(headers(deviceId: deviceId, token: token));
    final response = await _send(request);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const MediaServerException(
        'Plex rejected this session. Reconnect the server.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MediaServerException(
        'Plex request failed (HTTP ${response.statusCode}).',
      );
    }
    if (response.bodyBytes.isEmpty) {
      if (allowEmpty) return const {};
      throw const MediaServerException('Plex returned an empty response.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const MediaServerException(
        'Plex returned an invalid JSON response.',
      );
    }
    return decoded;
  }

  Future<http.Response> _send(http.Request request) async {
    final timer = Stopwatch()..start();
    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed).timeout(timeout);
      DiagnosticLog.event(
        'plex_http',
        {
          'method': request.method,
          'path': request.url.path,
          'status': response.statusCode,
          'elapsed_ms': timer.elapsedMilliseconds,
        },
      );
      return response;
    } on TimeoutException {
      throw const MediaServerException(
        'Timed out contacting the Plex server.',
      );
    } on http.ClientException catch (e) {
      throw MediaServerException('Could not reach the Plex server: $e');
    }
  }
}
