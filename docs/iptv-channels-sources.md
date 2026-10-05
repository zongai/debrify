# IPTV channels and sources

Debrify follows the plexios model:

- **Channel** — logical identity (name, logo, group, number, EPG).
- **Source** — one playable stream (URL + headers + optional label).

## Merge

On M3U parse / catalog ingest, rows that share a trusted `tvg-id` or the same
normalized name+group collapse into one channel with multiple sources
(`IptvChannelNormalizer`).

## UI

Channel rows show `N sources` in the subtitle when N > 1.

## Playback

The player keeps `_iptvSourceIndex`. Live recovery rotates sources before
reopening the same URL again.
