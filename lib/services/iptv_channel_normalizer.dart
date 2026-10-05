import '../models/iptv_playlist.dart';

/// Merges M3U rows that represent the same logical channel into one
/// [IptvChannel] with multiple [IptvSource]s — same idea as plexios
/// `ChannelNormalizer`.
///
/// Merge key (within one playlist pass):
/// 1. Trusted unique `tvg-id` when present and consistent
/// 2. Else normalized `name` + `group` (case-insensitive)
///
/// Duplicate URLs inside a group are dropped. Order of first appearance is
/// preserved for the primary source and channel list order.
class IptvChannelNormalizer {
  IptvChannelNormalizer._();

  /// Merge [input] into logical channels. Returns [input] unchanged when
  /// every row is already unique under the merge key.
  static List<IptvChannel> merge(List<IptvChannel> input) {
    if (input.length <= 1) return input;

    final order = <String>[];
    final groups = <String, _Acc>{};

    for (final channel in input) {
      final key = _mergeKey(channel);
      final existing = groups[key];
      if (existing == null) {
        order.add(key);
        groups[key] = _Acc(channel);
      } else {
        existing.add(channel);
      }
    }

    if (groups.length == input.length) return input;

    return [
      for (final key in order) groups[key]!.build(),
    ];
  }

  static String _mergeKey(IptvChannel channel) {
    // Prefer normalized name so alternate mirrors with different tvg-id /
    // group still become one channel with multiple sources (Chinese IPTV
    // lists often give each line a unique tvg-id).
    final nameKey = normalizeName(channel.name);
    if (nameKey.isNotEmpty) {
      return 'n:$nameKey';
    }
    final tvgId = channel.attributes['tvg-id']?.trim();
    if (tvgId != null && tvgId.isNotEmpty) {
      return 'id:${tvgId.toLowerCase()}';
    }
    return 'n:';
  }

  /// Lowercase, collapse spaces, drop common quality / mirror suffixes.
  static String normalizeName(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // (HD), [FHD], 【高清】, -HD, _FHD, etc.
    s = s.replaceAll(
      RegExp(
        r'[\[\(【]\s*(hd|fhd|uhd|sd|4k|hevc|h265|h264|高清|超清|蓝光|备用|线路\s*\d+|源\s*\d+|source\s*\d+)\s*[\]\)】]',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(
      RegExp(
        r'[\s_\-]*(hd|fhd|uhd|4k|hevc|备用|线路\d+|源\d+|source\s*\d+)\s*$',
        caseSensitive: false,
      ),
      '',
    );
    return s.trim();
  }
}

class _Acc {
  _Acc(IptvChannel first)
      : name = first.name,
        logoUrl = first.logoUrl,
        group = first.group,
        duration = first.duration,
        contentType = first.contentType,
        attributes = Map<String, String>.from(first.attributes),
        channelNumber = first.channelNumber,
        sources = [
          for (final s in first.sources) s,
        ],
        _seenUrls = {for (final s in first.sources) s.url};

  String name;
  String? logoUrl;
  String? group;
  int? duration;
  String? contentType;
  Map<String, String> attributes;
  int? channelNumber;
  final List<IptvSource> sources;
  final Set<String> _seenUrls;

  void add(IptvChannel channel) {
    logoUrl ??= channel.logoUrl;
    channelNumber ??= channel.channelNumber;
    if (contentType == null && channel.contentType != null) {
      contentType = channel.contentType;
    }
    // Prefer a filled tvg-id when the first row lacked one.
    final id = channel.attributes['tvg-id'];
    if ((attributes['tvg-id'] == null || attributes['tvg-id']!.isEmpty) &&
        id != null &&
        id.isNotEmpty) {
      attributes = {...attributes, 'tvg-id': id};
    }
    for (final s in channel.sources) {
      if (_seenUrls.add(s.url)) {
        final host = Uri.tryParse(s.url)?.host;
        sources.add(
          IptvSource(
            url: s.url,
            label: s.label ??
                (host != null && host.isNotEmpty
                    ? 'Source ${sources.length + 1} · $host'
                    : 'Source ${sources.length + 1}'),
            httpHeaders: s.httpHeaders,
          ),
        );
      }
    }
  }

  IptvChannel build() {
    // Label multi-source entries when the first had no label.
    final labeled = <IptvSource>[];
    for (var i = 0; i < sources.length; i++) {
      final s = sources[i];
      if (sources.length > 1 && (s.label == null || s.label!.isEmpty)) {
        final host = Uri.tryParse(s.url)?.host;
        labeled.add(
          IptvSource(
            url: s.url,
            label: host != null && host.isNotEmpty
                ? 'Source ${i + 1} · $host'
                : 'Source ${i + 1}',
            httpHeaders: s.httpHeaders,
          ),
        );
      } else {
        labeled.add(s);
      }
    }
    final primary = labeled.first;
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
      sources: labeled,
    );
  }
}
