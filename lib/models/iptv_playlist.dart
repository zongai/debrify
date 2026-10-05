// IPTV Playlist and Channel models for M3U support

/// User-Agent sent for IPTV playback when the playlist doesn't name one.
///
/// Without it mpv/ffmpeg (the in-app player) sends its default `Lavf/<version>`,
/// which a large share of IPTV panels and CDNs block outright to stop
/// restreaming — so every channel dies with no visible reason. Matches the
/// Android TV player's data-source UA so a channel behaves the same on both.
const String kIptvDefaultUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

/// Represents an IPTV M3U playlist
class IptvPlaylist {
  final String id;
  final String name;
  final String url;
  final String? content; // Raw M3U content for file-based playlists
  final String? serverUrl; // Xtream Codes server URL
  final String? username; // Xtream Codes username
  final String? password; // Xtream Codes password

  /// User-supplied XMLTV guide URL for M3U playlists. Overrides whatever the
  /// playlist's own `#EXTM3U url-tvg=` header declares (most declare none).
  final String? epgUrl;

  final DateTime addedAt;
  final String? connectionResourceId;
  final int? connectionResourceRevision;
  final bool connectionReadOnly;
  final bool credentialsRedacted;

  const IptvPlaylist({
    required this.id,
    required this.name,
    required this.url,
    this.content,
    this.serverUrl,
    this.username,
    this.password,
    this.epgUrl,
    required this.addedAt,
    this.connectionResourceId,
    this.connectionResourceRevision,
    this.connectionReadOnly = false,
    this.credentialsRedacted = false,
  });

  /// Returns true if this playlist was imported from a local file
  bool get isLocalFile => content != null && content!.isNotEmpty;

  /// Returns true if this is an Xtream Codes playlist
  bool get isXtreamCodes => serverUrl != null && serverUrl!.isNotEmpty;

  /// Returns true if this is a virtual playlist backed by an installed
  /// Stremio addon's live-TV catalogs (never persisted — derived from the
  /// installed addon list each session).
  bool get isStremioAddon => url.startsWith('stremio-addon://');

  /// Returns true if this is the virtual Favorites playlist (never persisted —
  /// backed by the starred-channel store instead of a fetch).
  bool get isFavorites => url.startsWith('favorites://');

  /// Returns true if this is the virtual "Continue watching" playlist (never
  /// persisted — backed by the watch-history store joined with the players'
  /// saved positions).
  bool get isContinueWatching => url.startsWith('continue://');

  /// Returns true if this is a virtual playlist backed by a user-created
  /// channel list (never persisted — the membership store is the truth).
  bool get isCustomList => url.startsWith('list://');

  /// The list id behind [isCustomList], or null for anything else.
  String? get customListId =>
      isCustomList ? url.substring('list://'.length) : null;

  /// Returns true if this playlist is derived rather than user-configured.
  ///
  /// Virtual playlists are rebuilt from their backing store on every load and
  /// must never reach the saved-playlists preference: they would come back
  /// twice (once stored, once injected) under the same id, and equality here
  /// is id-only — so lookups would start resolving the stale copy.
  bool get isVirtual =>
      isFavorites || isContinueWatching || isStremioAddon || isCustomList;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    if (content != null) 'content': content,
    if (serverUrl != null) 'serverUrl': serverUrl,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (epgUrl != null) 'epgUrl': epgUrl,
    'addedAt': addedAt.toIso8601String(),
    if (connectionResourceId != null)
      '_connectionResourceId': connectionResourceId,
    if (connectionResourceRevision != null)
      '_connectionResourceRevision': connectionResourceRevision,
    if (connectionReadOnly) '_connectionResourceReadOnly': true,
    if (credentialsRedacted) '_connectionResourceCredentialsRedacted': true,
  };

  Map<String, dynamic> toTransferJson() => {
    'id': id,
    'name': name,
    'url': url,
    if (content != null) 'content': content,
    if (serverUrl != null) 'serverUrl': serverUrl,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (epgUrl != null) 'epgUrl': epgUrl,
    'addedAt': addedAt.toIso8601String(),
  };

  factory IptvPlaylist.fromJson(Map<String, dynamic> json) => IptvPlaylist(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    content: json['content'] as String?,
    serverUrl: json['serverUrl'] as String?,
    username: json['username'] as String?,
    password: json['password'] as String?,
    epgUrl: json['epgUrl'] as String?,
    addedAt: DateTime.parse(json['addedAt'] as String),
    connectionResourceId: json['_connectionResourceId']?.toString(),
    connectionResourceRevision: (json['_connectionResourceRevision'] as num?)
        ?.toInt(),
    connectionReadOnly: json['_connectionResourceReadOnly'] as bool? ?? false,
    credentialsRedacted:
        json['_connectionResourceCredentialsRedacted'] as bool? ?? false,
  );

  factory IptvPlaylist.fromTransferJson(Map<String, dynamic> json) =>
      IptvPlaylist.fromJson(<String, dynamic>{
        for (final entry in json.entries)
          if (!entry.key.startsWith('_connectionResource'))
            entry.key: entry.value,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IptvPlaylist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// One playable stream for an [IptvChannel] (URL + headers + optional label).
///
/// A logical channel may expose several sources (CDN mirrors, alternate
/// codecs). Selection and failover live in the player; the list UI shows the
/// channel once with a source-count badge when [IptvChannel.sources].length > 1.
class IptvSource {
  final String url;
  final String? label;
  final Map<String, String> httpHeaders;

  const IptvSource({
    required this.url,
    this.label,
    this.httpHeaders = const {},
  });

  Map<String, String> get playbackHeaders {
    final headers = <String, String>{...httpHeaders};
    final hasUserAgent = headers.keys.any(
      (k) => k.toLowerCase() == 'user-agent',
    );
    if (!hasUserAgent) headers['User-Agent'] = kIptvDefaultUserAgent;
    return headers;
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    if (label != null) 'label': label,
    if (httpHeaders.isNotEmpty) 'httpHeaders': httpHeaders,
  };

  factory IptvSource.fromJson(Map<String, dynamic> json) => IptvSource(
    url: json['url'] as String? ?? '',
    label: json['label'] as String?,
    httpHeaders: _stringMap(json['httpHeaders']),
  );

  @override
  bool operator ==(Object other) =>
      other is IptvSource && other.url == url && other.label == label;

  @override
  int get hashCode => Object.hash(url, label);
}

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (e.key != null && e.value != null) e.key.toString(): e.value.toString(),
  };
}

/// Represents an IPTV channel from an M3U playlist.
///
/// **Channel vs source:** the channel is the user-facing identity (name, logo,
/// group, number). [sources] are the playable streams. [url] / [httpHeaders]
/// always mirror the primary (first) source so existing call sites and the
/// catalog DB stay compatible.
class IptvChannel {
  /// Stable, provider-scoped number for live television. Null for VOD,
  /// series, and sources that have not been numbered yet.
  final int? channelNumber;
  final String name;

  /// Primary stream URL — same as [sources].first.url when [sources] is set.
  final String url;
  final String? logoUrl;
  final String? group; // Category/group
  final int? duration; // Non-positive for live streams; positive for VOD
  final String? contentType; // 'live', 'vod', or null (M3U channels)
  final Map<String, String> attributes; // Additional tvg-* attributes

  /// Headers for the primary source (mirrored from [sources].first).
  final Map<String, String> httpHeaders;

  /// All playable streams for this logical channel. Never empty.
  final List<IptvSource> sources;

  IptvChannel({
    this.channelNumber,
    required this.name,
    required this.url,
    this.logoUrl,
    this.group,
    this.duration,
    this.contentType,
    this.attributes = const {},
    this.httpHeaders = const {},
    List<IptvSource>? sources,
  }) : sources = _normalizeSources(
          sources: sources,
          url: url,
          httpHeaders: httpHeaders,
        );

  static List<IptvSource> _normalizeSources({
    required List<IptvSource>? sources,
    required String url,
    required Map<String, String> httpHeaders,
  }) {
    if (sources != null && sources.isNotEmpty) {
      // Ensure primary url is first.
      final primary = sources.first.url == url
          ? sources
          : [
              IptvSource(url: url, httpHeaders: httpHeaders),
              for (final s in sources)
                if (s.url != url) s,
            ];
      // De-dupe by URL preserving order.
      final seen = <String>{};
      final out = <IptvSource>[];
      for (final s in primary) {
        if (seen.add(s.url)) out.add(s);
      }
      return List.unmodifiable(out);
    }
    return List.unmodifiable([
      IptvSource(url: url, httpHeaders: httpHeaders),
    ]);
  }

  bool get hasMultipleSources => sources.length > 1;

  IptvSource get primarySource => sources.first;

  IptvSource sourceAt(int index) {
    if (index < 0 || index >= sources.length) return primarySource;
    return sources[index];
  }

  /// Copy with a different primary source (moves [index] to front).
  IptvChannel withPrimarySource(int index) {
    if (index <= 0 || index >= sources.length) return this;
    final next = [
      sources[index],
      for (var i = 0; i < sources.length; i++)
        if (i != index) sources[i],
    ];
    final primary = next.first;
    return IptvChannel(
      channelNumber: channelNumber,
      name: name,
      url: primary.url,
      logoUrl: logoUrl,
      group: group,
      duration: duration,
      contentType: contentType,
      attributes: attributes,
      httpHeaders: primary.httpHeaders,
      sources: next,
    );
  }

  /// The headers to send when playing the primary source.
  Map<String, String> get playbackHeaders => primarySource.playbackHeaders;

  /// Lowercased "name\ngroup" haystack for search, built once per channel on
  /// first use. Searching used to call toLowerCase() on every channel's name
  /// AND group per keystroke — tens of thousands of string allocations per
  /// keypress against a 10k-channel playlist on weak TV CPUs.
  late final String searchKey =
      '${name.toLowerCase()}\n${group?.toLowerCase() ?? ''}';

  /// Check if this is a live stream. Xtream Codes channels carry an explicit
  /// content type; M3U channels fall back to the duration heuristic.
  bool get isLive {
    if (contentType != null) return contentType == 'live';
    // The M3U convention is -1 for an indefinite/live item, but several
    // playlist editors (including EPGenius) emit EXTINF:0 for live channels.
    // A positive duration is the only reliable VOD signal here. Treating 0
    // as VOD prevents those channels from entering the XMLTV matching scan,
    // even when their tvg-ids line up with the guide exactly.
    return duration == null || duration! <= 0;
  }

  /// Get tvg-id attribute if present
  String? get tvgId => attributes['tvg-id'];

  /// Get tvg-name attribute if present
  String? get tvgName => attributes['tvg-name'];

  /// UI label that keeps the provider's name intact for matching/search while
  /// consistently exposing the assigned number anywhere a channel is named.
  String get numberedName =>
      channelNumber == null ? name : 'CH $channelNumber  $name';

  Map<String, dynamic> toJson() => {
    if (channelNumber != null) 'channelNumber': channelNumber,
    'name': name,
    'url': url,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (group != null) 'group': group,
    if (duration != null) 'duration': duration,
    if (contentType != null) 'contentType': contentType,
    if (httpHeaders.isNotEmpty) 'httpHeaders': httpHeaders,
    if (sources.length > 1)
      'sources': [for (final s in sources) s.toJson()],
  };

  factory IptvChannel.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final headers = _stringMap(json['httpHeaders']);
    List<IptvSource>? sources;
    final rawSources = json['sources'];
    if (rawSources is List && rawSources.isNotEmpty) {
      sources = [
        for (final row in rawSources)
          if (row is Map)
            IptvSource.fromJson(Map<String, dynamic>.from(row)),
      ];
    }
    return IptvChannel(
      channelNumber: (json['channelNumber'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      url: url,
      logoUrl: json['logoUrl'] as String?,
      group: json['group'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      contentType: json['contentType'] as String?,
      attributes: _stringMap(json['attributes']),
      httpHeaders: headers,
      sources: sources,
    );
  }

  @override
  String toString() =>
      'IptvChannel(name: $name, group: $group, sources: ${sources.length}, url: $url)';
}

/// Result of parsing an M3U playlist
class IptvParseResult {
  final List<IptvChannel> channels;
  final List<String> categories;
  final String? error;

  /// Non-fatal problem worth surfacing to the user (e.g. categories
  /// unavailable, so channels are shown ungrouped).
  final String? warning;

  /// XMLTV guide URL the playlist's own `#EXTM3U url-tvg=` / `x-tvg-url=`
  /// header declared, if any. A user-configured [IptvPlaylist.epgUrl] wins
  /// over this.
  final String? epgUrl;

  /// Set when the parse worker wrote this catalog straight into the catalog
  /// DB instead of returning the channel list — [channels] is then empty by
  /// design and consumers read via `IptvCatalogDb.snapshot(ingest.catalogKey)`.
  final CatalogIngestReceipt? ingest;

  const IptvParseResult({
    required this.channels,
    required this.categories,
    this.error,
    this.warning,
    this.epgUrl,
    this.ingest,
  });

  bool get hasError => error != null;

  /// "Nothing came back" — an ingested catalog with rows in the DB is not
  /// empty even though [channels] is.
  bool get isEmpty =>
      channels.isEmpty && (ingest == null || ingest!.channelCount == 0);
}

/// Proof that a parse worker ingested a catalog into `iptv_catalog.db`:
/// where it lives, how many rows, and the content digest (used by the
/// revalidate path to decide "Up to date" vs a real refresh).
class CatalogIngestReceipt {
  final String catalogKey;
  final int channelCount;
  final String contentDigest;

  const CatalogIngestReceipt({
    required this.catalogKey,
    required this.channelCount,
    required this.contentDigest,
  });
}
