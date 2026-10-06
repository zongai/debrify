import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Empty state widget when no IPTV playlist is selected or no channels found
class IptvEmptyState extends StatelessWidget {
  final bool hasPlaylists;
  final VoidCallback? onAddPlaylist;

  IptvEmptyState({
    super.key,
    this.hasPlaylists = false,
    this.onAddPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPlaylists ? Icons.live_tv : Icons.playlist_add,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 24),
            Text(
              hasPlaylists
                  ? 'Select a Playlist'
                  : 'No IPTV Playlists',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              hasPlaylists
                  ? 'Choose a playlist from the dropdown above to browse channels'
                  : 'Add M3U playlists in Settings to start watching',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasPlaylists && onAddPlaylist != null) ...[
              SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddPlaylist,
                icon: Icon(Icons.add),
                label: Text(AppLocalizations.of(context).t('Add Playlist')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
