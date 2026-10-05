import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App UI strings. Prefer [AppLocalizations.of] in widgets.
///
/// Add a key to every locale map below when introducing a new string.
/// System / Material strings still come from [MaterialLocalizations].
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('ja'),
  ];

  static const languageOptions = <(String code, String nativeName)>[
    ('system', 'System'),
    ('en', 'English'),
    ('zh', '中文'),
    ('ja', '日本語'),
  ];

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context');
    return value!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations lookup(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    if (_tables.containsKey(language)) {
      return AppLocalizations._(Locale(language), _tables[language]!);
    }
    return AppLocalizations._(const Locale('en'), _tables['en']!);
  }

  AppLocalizations._(this.locale, this._t);

  final Map<String, String> _t;

  String _s(String key) => _t[key] ?? _tables['en']![key] ?? key;

  // --- Common ---
  String get appName => _s('appName');
  String get cancel => _s('cancel');
  String get retry => _s('retry');
  String get save => _s('save');
  String get delete => _s('delete');
  String get connect => _s('connect');
  String get disconnect => _s('disconnect');
  String get reconnect => _s('reconnect');
  String get settings => _s('settings');
  String get language => _s('language');
  String get languageBlurb => _s('languageBlurb');
  String get languageSystem => _s('languageSystem');
  String get done => _s('done');
  String get loading => _s('loading');
  String get errorGeneric => _s('errorGeneric');

  // --- Media servers ---
  String get mediaServersTitle => _s('mediaServersTitle');
  String get mediaServersBlurb => _s('mediaServersBlurb');
  String get connectServer => _s('connectServer');
  String get connectMediaServer => _s('connectMediaServer');
  String get reconnectMediaServer => _s('reconnectMediaServer');
  String get serverType => _s('serverType');
  String get displayNameOptional => _s('displayNameOptional');
  String get serverUrl => _s('serverUrl');
  String get username => _s('username');
  String get password => _s('password');
  String get plexTokenRecommended => _s('plexTokenRecommended');
  String get plexTokenHint => _s('plexTokenHint');
  String get plexTokenHelp => _s('plexTokenHelp');
  String get usernameOptionalIfToken => _s('usernameOptionalIfToken');
  String get passwordOptionalIfToken => _s('passwordOptionalIfToken');
  String get plexTokenOnlyHelp => _s('plexTokenOnlyHelp');
  String get jellyfinEmbyConnectHelp => _s('jellyfinEmbyConnectHelp');
  String get connecting => _s('connecting');
  String get testConnection => _s('testConnection');
  String get connectionSuccessful => _s('connectionSuccessful');
  String get connectionUnavailable => _s('connectionUnavailable');
  String get couldNotLoadMediaServers => _s('couldNotLoadMediaServers');
  String get enterServerUrl => _s('enterServerUrl');
  String get enterUrlAndUsername => _s('enterUrlAndUsername');
  String get enterPlexTokenOrCredentials => _s('enterPlexTokenOrCredentials');
  String get couldNotSaveConnection => _s('couldNotSaveConnection');
  String disconnectServerConfirm(String name) =>
      _s('disconnectServerConfirm').replaceAll('{name}', name);
  String get watchProgressSync => _s('watchProgressSync');
  String get plexLinkButton => _s('plexLinkButton');
  String get plexLinkTitle => _s('plexLinkTitle');
  String get plexLinkInstructions => _s('plexLinkInstructions');
  String get plexLinkWaiting => _s('plexLinkWaiting');
  String get plexLinkExpired => _s('plexLinkExpired');
  String get plexLinkCancelled => _s('plexLinkCancelled');
  String get plexLinkOpenUrl => _s('plexLinkOpenUrl');
  String get watchProgressSyncBlurb => _s('watchProgressSyncBlurb');

  // --- Settings sections (high traffic) ---
  String get appearance => _s('appearance');
  String get accountsAndServices => _s('accountsAndServices');
  String get playback => _s('playback');
  String get about => _s('about');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations.lookup(locale),
    );
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

const _tables = <String, Map<String, String>>{
  'en': {
    'appName': 'Debrify',
    'cancel': 'Cancel',
    'retry': 'Retry',
    'save': 'Save',
    'delete': 'Delete',
    'connect': 'Connect',
    'disconnect': 'Disconnect',
    'reconnect': 'Reconnect',
    'settings': 'Settings',
    'language': 'Language',
    'languageBlurb':
        'Choose the app interface language. System follows the device setting.',
    'languageSystem': 'System default',
    'done': 'Done',
    'loading': 'Loading…',
    'errorGeneric': 'Something went wrong. Please try again.',
    'mediaServersTitle': 'Jellyfin, Emby & Plex',
    'mediaServersBlurb':
        'Connect a media server to show its movies and episodes in Sources. Files play directly in Debrify; watch progress is saved in Debrify.',
    'connectServer': 'Connect server',
    'connectMediaServer': 'Connect media server',
    'reconnectMediaServer': 'Reconnect media server',
    'serverType': 'Server type',
    'displayNameOptional': 'Display name (optional)',
    'serverUrl': 'Server URL',
    'username': 'Username',
    'password': 'Password',
    'plexTokenRecommended': 'Plex token (recommended)',
    'plexTokenHint': 'X-Plex-Token value',
    'plexTokenHelp':
        'Paste a server or account token. When a token is set, username and password are ignored.',
    'usernameOptionalIfToken': 'Username (optional if token set)',
    'passwordOptionalIfToken': 'Password (optional if token set)',
    'plexTokenOnlyHelp':
        'Token-only: no plex.tv password is sent. Find a token in Plex Web (authorized devices) or from an existing client. HTTPS is recommended outside your home network. Only the token is stored.',
    'jellyfinEmbyConnectHelp':
        'Use a server user with access to the libraries you want to play. HTTPS is recommended outside your home network. Only the sign-in token is saved, not your password.',
    'connecting': 'Connecting…',
    'testConnection': 'Test connection',
    'connectionSuccessful': 'Connection successful',
    'connectionUnavailable':
        'Connection unavailable. Check profile permissions or reconnect.',
    'couldNotLoadMediaServers': 'Could not load media servers. Please retry.',
    'enterServerUrl': 'Enter the server URL.',
    'enterUrlAndUsername': 'Enter the server URL and username.',
    'enterPlexTokenOrCredentials':
        'Enter a Plex token, or a username and password.',
    'couldNotSaveConnection':
        'Could not save the connection. Check profile permissions and try again.',
    'disconnectServerConfirm': 'Disconnect {name}?',
    'watchProgressSync': 'Sync watch progress from server',
    'plexLinkButton': 'Sign in at plex.tv/link',
    'plexLinkTitle': 'Link Plex',
    'plexLinkInstructions': 'Open https://www.plex.tv/link on any device and enter this code:',
    'plexLinkWaiting': 'Waiting for approval…',
    'plexLinkExpired': 'This code expired. Start again.',
    'plexLinkCancelled': 'Sign-in cancelled.',
    'plexLinkOpenUrl': 'Open plex.tv/link',
    'watchProgressSyncBlurb':
        'Import resume positions and played status from the media server when available.',
    'appearance': 'Appearance',
    'accountsAndServices': 'Accounts & services',
    'playback': 'Playback',
    'about': 'About',
  },
  'zh': {
    'appName': 'Debrify',
    'cancel': '取消',
    'retry': '重试',
    'save': '保存',
    'delete': '删除',
    'connect': '连接',
    'disconnect': '断开',
    'reconnect': '重新连接',
    'settings': '设置',
    'language': '语言',
    'languageBlurb': '选择应用界面语言。跟随系统将使用设备语言设置。',
    'languageSystem': '跟随系统',
    'done': '完成',
    'loading': '加载中…',
    'errorGeneric': '出错了，请重试。',
    'mediaServersTitle': 'Jellyfin、Emby 与 Plex',
    'mediaServersBlurb':
        '连接媒体服务器后，可在来源列表中播放其影片与剧集。文件在 Debrify 内直接播放，观看进度保存在 Debrify。',
    'connectServer': '连接服务器',
    'connectMediaServer': '连接媒体服务器',
    'reconnectMediaServer': '重新连接媒体服务器',
    'serverType': '服务器类型',
    'displayNameOptional': '显示名称（可选）',
    'serverUrl': '服务器地址',
    'username': '用户名',
    'password': '密码',
    'plexTokenRecommended': 'Plex Token（推荐）',
    'plexTokenHint': 'X-Plex-Token 值',
    'plexTokenHelp': '粘贴服务器或账号 Token。填写 Token 后将忽略用户名和密码。',
    'usernameOptionalIfToken': '用户名（已填 Token 时可留空）',
    'passwordOptionalIfToken': '密码（已填 Token 时可留空）',
    'plexTokenOnlyHelp':
        '仅 Token 登录：不会向 plex.tv 发送密码。可在 Plex 网页（已授权设备）或其他客户端获取 Token。非家庭网络建议使用 HTTPS。仅保存 Token。',
    'jellyfinEmbyConnectHelp':
        '请使用有权访问目标媒体库的服务器账号。非家庭网络建议使用 HTTPS。仅保存登录 Token，不会保存密码。',
    'connecting': '正在连接…',
    'testConnection': '测试连接',
    'connectionSuccessful': '连接成功',
    'connectionUnavailable': '无法连接。请检查配置权限或重新连接。',
    'couldNotLoadMediaServers': '无法加载媒体服务器，请重试。',
    'enterServerUrl': '请输入服务器地址。',
    'enterUrlAndUsername': '请输入服务器地址和用户名。',
    'enterPlexTokenOrCredentials': '请输入 Plex Token，或用户名和密码。',
    'couldNotSaveConnection': '无法保存连接。请检查配置权限后重试。',
    'disconnectServerConfirm': '断开 {name}？',
    'watchProgressSync': '从服务器同步观看进度',
    'plexLinkButton': '通过 plex.tv/link 登录',
    'plexLinkTitle': '关联 Plex',
    'plexLinkInstructions': '在任意设备打开 https://www.plex.tv/link 并输入以下代码：',
    'plexLinkWaiting': '等待授权…',
    'plexLinkExpired': '代码已过期，请重试。',
    'plexLinkCancelled': '已取消登录。',
    'plexLinkOpenUrl': '打开 plex.tv/link',
    'watchProgressSyncBlurb': '在可用时从媒体服务器导入续播位置与已看状态。',
    'appearance': '外观',
    'accountsAndServices': '账号与服务',
    'playback': '播放',
    'about': '关于',
  },
  'ja': {
    'appName': 'Debrify',
    'cancel': 'キャンセル',
    'retry': '再試行',
    'save': '保存',
    'delete': '削除',
    'connect': '接続',
    'disconnect': '切断',
    'reconnect': '再接続',
    'settings': '設定',
    'language': '言語',
    'languageBlurb': 'アプリの表示言語を選びます。システムは端末の言語設定に従います。',
    'languageSystem': 'システムに合わせる',
    'done': '完了',
    'loading': '読み込み中…',
    'errorGeneric': '問題が発生しました。もう一度お試しください。',
    'mediaServersTitle': 'Jellyfin・Emby・Plex',
    'mediaServersBlurb':
        'メディアサーバーを接続すると、ソース一覧から映画やエピソードを再生できます。ファイルは Debrify 内で直接再生され、視聴進度は Debrify に保存されます。',
    'connectServer': 'サーバーを接続',
    'connectMediaServer': 'メディアサーバーを接続',
    'reconnectMediaServer': 'メディアサーバーを再接続',
    'serverType': 'サーバーの種類',
    'displayNameOptional': '表示名（任意）',
    'serverUrl': 'サーバー URL',
    'username': 'ユーザー名',
    'password': 'パスワード',
    'plexTokenRecommended': 'Plex トークン（推奨）',
    'plexTokenHint': 'X-Plex-Token の値',
    'plexTokenHelp': 'サーバーまたはアカウントのトークンを貼り付けます。トークンがある場合、ユーザー名とパスワードは無視されます。',
    'usernameOptionalIfToken': 'ユーザー名（トークン使用時は任意）',
    'passwordOptionalIfToken': 'パスワード（トークン使用時は任意）',
    'plexTokenOnlyHelp':
        'トークンのみ：plex.tv にパスワードは送信しません。Plex Web（許可済みデバイス）や他クライアントから取得できます。自宅外では HTTPS を推奨。トークンのみ保存します。',
    'jellyfinEmbyConnectHelp':
        '再生したいライブラリにアクセスできるサーバーユーザーを使ってください。自宅外では HTTPS を推奨。パスワードではなくサインイントークンのみ保存します。',
    'connecting': '接続中…',
    'testConnection': '接続をテスト',
    'connectionSuccessful': '接続に成功しました',
    'connectionUnavailable': '接続できません。プロフィール権限を確認するか再接続してください。',
    'couldNotLoadMediaServers': 'メディアサーバーを読み込めませんでした。再試行してください。',
    'enterServerUrl': 'サーバー URL を入力してください。',
    'enterUrlAndUsername': 'サーバー URL とユーザー名を入力してください。',
    'enterPlexTokenOrCredentials': 'Plex トークン、またはユーザー名とパスワードを入力してください。',
    'couldNotSaveConnection': '接続を保存できませんでした。プロフィール権限を確認して再試行してください。',
    'disconnectServerConfirm': '{name} を切断しますか？',
    'watchProgressSync': 'サーバーから視聴進度を同期',
    'plexLinkButton': 'plex.tv/link でサインイン',
    'plexLinkTitle': 'Plex をリンク',
    'plexLinkInstructions': '任意の端末で https://www.plex.tv/link を開き、次のコードを入力してください：',
    'plexLinkWaiting': '承認を待っています…',
    'plexLinkExpired': 'コードの有効期限が切れました。やり直してください。',
    'plexLinkCancelled': 'サインインをキャンセルしました。',
    'plexLinkOpenUrl': 'plex.tv/link を開く',
    'watchProgressSyncBlurb': '可能であればメディアサーバーから再開位置と視聴済み状態を取り込みます。',
    'appearance': '外観',
    'accountsAndServices': 'アカウントとサービス',
    'playback': '再生',
    'about': '情報',
  },
};
