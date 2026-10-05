import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

import '../../models/media_server.dart';
import '../../models/profiles/connection_resource.dart';
import '../../models/profiles/profile_policy.dart';
import '../../services/media_server_service.dart';
import '../../services/plex_client.dart';
import '../../services/media_server_watch_sync.dart';
import '../../services/profiles/profile_collection_resource_facade.dart';
import '../../services/profiles/profile_runtime.dart';
import '../../widgets/tv_text_field.dart';
import 'widgets/settings_widgets.dart';

class MediaServerSettingsPage extends StatefulWidget {
  const MediaServerSettingsPage({super.key});
  @override
  State<MediaServerSettingsPage> createState() =>
      _MediaServerSettingsPageState();
}

class _MediaServerSettingsPageState extends State<MediaServerSettingsPage> {
  List<ConnectionResource> _connections = [];
  bool _loading = true;
  bool _busy = false;
  bool _watchSync = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = ProfileRuntime.scope.value;
    try {
      final connections = await MediaServerService.connections();
      final watchSync = await MediaServerWatchSync.enabled();
      if (!mounted || ProfileRuntime.scope.value != scope) return;
      setState(() {
        _connections = connections;
        _watchSync = watchSync;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).couldNotLoadMediaServers;
        });
      }
    }
  }

  Future<void> _setWatchSync(bool value) async {
    if (_busy) return;
    final scope = ProfileRuntime.scope.value;
    setState(() => _busy = true);
    try {
      await MediaServerWatchSync.setEnabled(value);
      if (mounted && ProfileRuntime.scope.value == scope) {
        setState(() => _watchSync = value);
      }
    } catch (_) {
      if (mounted && ProfileRuntime.scope.value == scope) {
        setState(() => _error = 'Could not change watch sync. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([ConnectionResource? resource]) async {
    await pushSettingsPage(
      context,
      _MediaServerConnectPage(resource: resource),
    );
    if (mounted) await _load();
  }

  Future<void> _test(ConnectionResource resource) async {
    setState(() => _busy = true);
    try {
      await MediaServerService.test(resource);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).connectionSuccessful)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is MediaServerException
                  ? error.message
                  : AppLocalizations.of(context).connectionUnavailable,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(ConnectionResource resource) async {
    final scope = ProfileRuntime.scope.value;
    var borrowers = 0;
    try {
      if (resource.ownerProfileId == scope?.profileId) {
        borrowers = await ProfileCollectionResourceFacade.ownedBorrowerCount(
          resourceId: resource.id,
          feature: ProfileFeature.manageConnections,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check connection sharing. Please retry.'),
          ),
        );
      }
      return;
    }
    if (!mounted || ProfileRuntime.scope.value != scope) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).disconnectServerConfirm(resource.label)),
        content: Text(
          borrowers > 0
              ? 'This will remove access for you and $borrowers other profile(s). Your server files will not be deleted.'
              : 'Its files will no longer appear in sources. Your server files will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              borrowers > 0 ? 'Disconnect for all profiles' : 'Disconnect',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || ProfileRuntime.scope.value != scope) {
      return;
    }
    setState(() => _busy = true);
    try {
      await MediaServerService.remove(resource, revokeBorrowers: borrowers > 0);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not disconnect. If this connection is shared, manage its sharing in Profiles first.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPageScaffold(
    title: AppLocalizations.of(context).mediaServersTitle,
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                AppLocalizations.of(context).mediaServersBlurb,
              ),
              const SizedBox(height: 12),
              const Text(
                'Matching uses the server’s IMDb, TMDB or TVDB IDs and season/episode numbers. Missing IDs or different anime numbering may produce no match. Server transcoding is not included.',
              ),
              if (ProfileCollectionResourceFacade.active)
                SettingsToggleTile(
                  icon: Icons.sync,
                  title: AppLocalizations.of(context).t('Sync server watch progress'),
                  subtitle:
                      'For this Debrify profile: resume from the selected server and report playback/watched status back. Shared connections update the same server user. Applies to new playback sessions; no background library sync.',
                  subtitleMaxLines: 5,
                  value: _watchSync,
                  onChanged: _setWatchSync,
                ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: Text(AppLocalizations.of(context).retry)),
              ],
              if (!ProfileCollectionResourceFacade.active)
                const Text(
                  'An active Debrify profile is required to store server credentials securely.',
                ),
              for (final resource in _connections)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          resource.secretPending
                              ? 'Reconnect to restore access'
                              : 'Configured',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: _busy || resource.secretPending
                                  ? null
                                  : () => _test(resource),
                              child: Text(AppLocalizations.of(context).testConnection),
                            ),
                            if (resource.ownerProfileId ==
                                ProfileRuntime.scope.value?.profileId)
                              TextButton(
                                onPressed: _busy ? null : () => _edit(resource),
                                child: Text(AppLocalizations.of(context).reconnect),
                              ),
                            TextButton(
                              onPressed: _busy ? null : () => _remove(resource),
                              child: Text(AppLocalizations.of(context).disconnect),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy || !ProfileCollectionResourceFacade.active
                    ? null
                    : () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).connectServer),
              ),
            ],
          ),
  );
}

class _MediaServerConnectPage extends StatefulWidget {
  const _MediaServerConnectPage({this.resource});
  final ConnectionResource? resource;
  @override
  State<_MediaServerConnectPage> createState() =>
      _MediaServerConnectPageState();
}

class _MediaServerConnectPageState extends State<_MediaServerConnectPage> {
  final _label = TextEditingController();
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _token = TextEditingController();
  MediaServerKind _kind = MediaServerKind.jellyfin;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label.text = widget.resource?.label ?? '';
    final label = widget.resource?.publicConfig['accountLabel'];
    if (label == 'Emby') {
      _kind = MediaServerKind.emby;
    } else if (label == 'Plex') {
      _kind = MediaServerKind.plex;
    }
    _token.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    _user.dispose();
    _password.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _linkPlex() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final deviceId = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final client = PlexClient();
    var cancelled = false;
    try {
      final session = await client.createPin(deviceId: deviceId);
      if (!mounted) return;
      // Show PIN dialog and poll until the user finishes plex.tv/link.
      final token = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _PlexLinkDialog(
            session: session,
            deviceId: deviceId,
            client: client,
            onCancel: () => cancelled = true,
          );
        },
      );
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() {
          _busy = false;
          _error = cancelled
              ? null
              : AppLocalizations.of(context).plexLinkCancelled;
        });
        return;
      }

      // Discover servers; prefer explicit URL when the user filled one.
      var baseUrl = _url.text.trim();
      var accessToken = token;
      if (baseUrl.isEmpty) {
        final servers = await client.listServers(
          token: token,
          deviceId: deviceId,
        );
        if (servers.isEmpty) {
          setState(() {
            _busy = false;
            _error =
                'No Plex servers found. Enter a server URL and try again, or claim the server on plex.tv.';
          });
          return;
        }
        if (servers.length == 1) {
          baseUrl = servers.first.preferredUri;
          accessToken = servers.first.accessToken;
        } else if (mounted) {
          final chosen = await showDialog<PlexServerResource>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text(AppLocalizations.of(context).plexLinkTitle),
              children: [
                for (final s in servers)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, s),
                    child: Text('${s.name}\n${s.preferredUri}'),
                  ),
              ],
            ),
          );
          if (chosen == null) {
            setState(() => _busy = false);
            return;
          }
          baseUrl = chosen.preferredUri;
          accessToken = chosen.accessToken;
        }
      }

      await MediaServerService.connect(
        kind: MediaServerKind.plex,
        label: _label.text.isEmpty ? 'Plex' : _label.text,
        baseUrl: baseUrl,
        username: '',
        password: '',
        token: accessToken,
        replaceId: widget.resource?.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is MediaServerException
              ? error.message
              : AppLocalizations.of(context).couldNotSaveConnection;
        });
      }
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {

    if (_busy) return;
    final url = _url.text.trim();
    final token = _token.text.trim();
    final isPlexToken = _kind == MediaServerKind.plex && token.isNotEmpty;
    if (url.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterServerUrl);
      return;
    }
    if (!isPlexToken && _user.text.trim().isEmpty) {
      setState(
        () => _error = _kind == MediaServerKind.plex
            ? AppLocalizations.of(context).enterPlexTokenOrCredentials
            : AppLocalizations.of(context).enterUrlAndUsername,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MediaServerService.connect(
        kind: _kind,
        label: _label.text,
        baseUrl: _url.text,
        username: _user.text,
        password: _password.text,
        token: isPlexToken ? token : null,
        replaceId: widget.resource?.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is MediaServerException
              ? error.message
              : AppLocalizations.of(context).couldNotSaveConnection,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsPageScaffold(
    title: widget.resource == null
        ? AppLocalizations.of(context).connectMediaServer
        : AppLocalizations.of(context).reconnectMediaServer,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DropdownButtonFormField<MediaServerKind>(
          initialValue: _kind,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).serverType),
          items: [
            for (final kind in MediaServerKind.values)
              DropdownMenuItem(value: kind, child: Text(kind.label)),
          ],
          onChanged: _busy
              ? null
              : (kind) {
                  if (kind != null) setState(() => _kind = kind);
                },
        ),
        const SizedBox(height: 16),
        if (widget.resource == null) ...[
          TvTextField(
            controller: _label,
            enabled: !_busy,
            labelText: AppLocalizations.of(context).displayNameOptional,
          ),
          const SizedBox(height: 16),
        ],
        TvTextField(
          controller: _url,
          enabled: !_busy,
          labelText: AppLocalizations.of(context).serverUrl,
          hintText: _kind == MediaServerKind.plex
              ? 'http://192.168.1.10:32400'
              : 'https://media.example.com',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        if (_kind == MediaServerKind.plex) ...[
          TvTextField(
            controller: _token,
            enabled: !_busy,
            labelText: AppLocalizations.of(context).plexTokenRecommended,
            hintText: AppLocalizations.of(context).plexTokenHint,
            obscureText: true,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).plexTokenHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TvTextField(
            controller: _user,
            enabled: !_busy && _token.text.trim().isEmpty,
            labelText: AppLocalizations.of(context).usernameOptionalIfToken,
          ),
          const SizedBox(height: 16),
          TvTextField(
            controller: _password,
            enabled: !_busy && _token.text.trim().isEmpty,
            labelText: AppLocalizations.of(context).passwordOptionalIfToken,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).plexTokenOnlyHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          TvTextField(controller: _user, enabled: !_busy, labelText: AppLocalizations.of(context).username),
          const SizedBox(height: 16),
          TvTextField(
            controller: _password,
            enabled: !_busy,
            labelText: AppLocalizations.of(context).password,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).jellyfinEmbyConnectHelp,
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_kind == MediaServerKind.plex) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _linkPlex,
            icon: const Icon(Icons.link),
            label: Text(
              _busy
                  ? AppLocalizations.of(context).connecting
                  : AppLocalizations.of(context).plexLinkButton,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).plexLinkInstructions,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _connect,
          child: Text(_busy ? AppLocalizations.of(context).connecting : AppLocalizations.of(context).connect),
        ),
      ],
    ),
  );
}


/// PIN dialog for https://www.plex.tv/link (aligned with plex-for-kodi PinLogin).
class _PlexLinkDialog extends StatefulWidget {
  const _PlexLinkDialog({
    required this.session,
    required this.deviceId,
    required this.client,
    required this.onCancel,
  });

  final PlexPinSession session;
  final String deviceId;
  final PlexClient client;
  final VoidCallback onCancel;

  @override
  State<_PlexLinkDialog> createState() => _PlexLinkDialogState();
}

class _PlexLinkDialogState extends State<_PlexLinkDialog> {
  bool _cancelled = false;
  String? _error;
  bool _polling = true;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    try {
      final token = await widget.client.pollPinToken(
        session: widget.session,
        deviceId: widget.deviceId,
        isCancelled: () => _cancelled,
      );
      if (!mounted || _cancelled) return;
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pop(token);
        return;
      }
      setState(() {
        _polling = false;
        _error = AppLocalizations.of(context).plexLinkExpired;
      });
    } catch (e) {
      if (!mounted || _cancelled) return;
      setState(() {
        _polling = false;
        _error = e is MediaServerException
            ? e.message
            : AppLocalizations.of(context).plexLinkExpired;
      });
    }
  }

  Future<void> _openLink() async {
    final uri = Uri.parse('https://www.plex.tv/link');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _cancel() {
    _cancelled = true;
    widget.onCancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.plexLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.plexLinkInstructions),
          const SizedBox(height: 16),
          SelectableText(
            widget.session.code,
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_polling) ...[
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.plexLinkWaiting)),
              ],
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _openLink,
          child: Text(l10n.plexLinkOpenUrl),
        ),
        TextButton(
          onPressed: _cancel,
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
