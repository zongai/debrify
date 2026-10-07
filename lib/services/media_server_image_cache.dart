
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'debrify_image_cache.dart';

/// Memory + disk cache for media-server library posters.
///
/// Browse grids rebuild cells while scrolling; without this every recycle
/// re-authorizes and re-downloads the same thumb from Plex/Jellyfin/Emby.
class MediaServerImageCache {
  MediaServerImageCache._();

  static const int _maxMemoryEntries = 400;
  static final LinkedHashMap<String, Uint8List> _memory =
      LinkedHashMap<String, Uint8List>();
  static final Map<String, Future<Uint8List?>> _inflight = {};

  static String keyFor({required String resourceId, required String imageId}) =>
      'ms|$resourceId|$imageId';

  static Uint8List? peek(String key) {
    final hit = _memory.remove(key);
    if (hit == null) return null;
    // LRU: re-insert at end.
    _memory[key] = hit;
    return hit;
  }

  static void _putMemory(String key, Uint8List bytes) {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  /// Returns cached bytes or runs [load] once (coalesced per key).
  static Future<Uint8List?> getOrLoad({
    required String resourceId,
    required String imageId,
    required Future<Uint8List?> Function() load,
  }) {
    final key = keyFor(resourceId: resourceId, imageId: imageId);
    final mem = peek(key);
    if (mem != null) return Future.value(mem);

    final pending = _inflight[key];
    if (pending != null) return pending;

    final future = _load(key, load);
    _inflight[key] = future;
    return future.whenComplete(() => _inflight.remove(key));
  }

  static Future<Uint8List?> _load(
    String key,
    Future<Uint8List?> Function() load,
  ) async {
    try {
      final fileInfo =
          await DebrifyImageCache.mediaServer.getFileFromCache(key);
      if (fileInfo != null && await fileInfo.file.exists()) {
        final bytes = await fileInfo.file.readAsBytes();
        if (bytes.isNotEmpty) {
          _putMemory(key, bytes);
          return bytes;
        }
      }
    } catch (_) {
      // Fall through to network.
    }

    final bytes = await load();
    if (bytes == null || bytes.isEmpty) return bytes;

    _putMemory(key, bytes);
    try {
      await DebrifyImageCache.mediaServer.putFile(
        key,
        bytes,
        key: key,
        maxAge: const Duration(days: 14),
        fileExtension: 'jpg',
      );
    } catch (_) {
      // Memory hit is enough for this session.
    }
    return bytes;
  }

  /// Drop one server (or everything) when the connection is removed.
  static Future<void> evict({String? resourceId}) async {
    if (resourceId == null) {
      _memory.clear();
      try {
        await DebrifyImageCache.mediaServer.emptyCache();
      } catch (_) {}
      return;
    }
    final prefix = 'ms|$resourceId|';
    _memory.removeWhere((k, _) => k.startsWith(prefix));
    // Disk: flutter_cache_manager has no prefix delete; leave files to LRU.
  }
}
