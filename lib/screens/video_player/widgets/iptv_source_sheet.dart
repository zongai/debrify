import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import 'package:flutter/services.dart';

import '../../../models/iptv_playlist.dart';
import '../../../utils/tv_keys.dart';

/// Manual picker for alternate streams on one logical IPTV channel
/// (plexios-style source list).
class IptvSourceSheet extends StatefulWidget {
  const IptvSourceSheet({
    super.key,
    required this.channel,
    required this.currentIndex,
    required this.onSelected,
    required this.onClose,
  });

  final IptvChannel channel;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  @override
  State<IptvSourceSheet> createState() => _IptvSourceSheetState();
}

class _IptvSourceSheetState extends State<IptvSourceSheet> {
  late final List<FocusNode> _nodes;
  final FocusNode _keyboardNode = FocusNode(debugLabel: 'iptv-source-sheet');

  @override
  void initState() {
    super.initState();
    final n = widget.channel.sources.length;
    _nodes = List.generate(
      n,
      (i) => FocusNode(debugLabel: 'iptv-source-$i'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final i = widget.currentIndex.clamp(0, n - 1);
      _nodes[i].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _keyboardNode.dispose();
    super.dispose();
  }

  void _pick(int index) {
    widget.onSelected(index);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      TvOverlayBack.mark();
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sources = widget.channel.sources;
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.black54,
      child: Focus(
        focusNode: _keyboardNode,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  maxWidth: 560,
                ),
                child: Container(
                  margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                  decoration: BoxDecoration(
                    color: Color(0xFF141418),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Streams',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.channel.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: sources.length,
                          itemBuilder: (context, index) {
                            final source = sources[index];
                            final selected = index == widget.currentIndex;
                            final host = Uri.tryParse(source.url)?.host ?? '';
                            final title = source.label?.trim().isNotEmpty == true
                                ? source.label!
                                : (host.isNotEmpty
                                      ? 'Source ${index + 1} · $host'
                                      : 'Source ${index + 1}');
                            return Focus(
                              focusNode: _nodes[index],
                              onKeyEvent: (node, event) {
                                if (event is! KeyDownEvent) {
                                  return KeyEventResult.ignored;
                                }
                                if (isActivateKey(event.logicalKey)) {
                                  _pick(index);
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowDown) {
                                  final next = (index + 1) % sources.length;
                                  _nodes[next].requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowUp) {
                                  final prev =
                                      (index - 1 + sources.length) %
                                      sources.length;
                                  _nodes[prev].requestFocus();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Builder(
                                builder: (context) {
                                  final focused = Focus.of(context).hasFocus;
                                  return ListTile(
                                    selected: selected,
                                    selectedTileColor: Colors.white10,
                                    tileColor: focused
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : null,
                                    leading: Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.dns_outlined,
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : Colors.white54,
                                    ),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: host.isNotEmpty &&
                                            (source.label?.contains(host) !=
                                                true)
                                        ? Text(
                                            host,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    onTap: () => _pick(index),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
