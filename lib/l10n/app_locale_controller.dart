import 'package:flutter/widgets.dart';

import '../services/storage_service.dart';
import 'app_localizations.dart';

/// Persisted app UI language. `null` means follow the device locale.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();
  static final AppLocaleController instance = AppLocaleController._();

  /// Preference code: `system`, `en`, `zh`, `ja`, …
  String _preference = 'system';
  String get preference => _preference;

  /// Resolved locale for [MaterialApp.locale]. `null` = device default.
  Locale? get locale {
    if (_preference == 'system' || _preference.isEmpty) return null;
    return Locale(_preference);
  }

  /// Warm before [runApp] so the first frame uses the saved language.
  Future<void> load() async {
    final stored = await StorageService.getAppLanguage();
    _preference = _normalize(stored);
  }

  Future<void> setPreference(String code) async {
    final next = _normalize(code);
    if (next == _preference) return;
    _preference = next;
    await StorageService.setAppLanguage(next);
    notifyListeners();
  }

  String _normalize(String? raw) {
    final value = (raw ?? 'system').trim().toLowerCase();
    if (value.isEmpty || value == 'system') return 'system';
    final supported = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    return supported.contains(value) ? value : 'system';
  }

  String labelForPreference(String code) {
    for (final option in AppLocalizations.languageOptions) {
      if (option.$1 == code) {
        if (code == 'system') {
          // Prefer localized "System default" when available.
          return option.$2;
        }
        return option.$2;
      }
    }
    return code;
  }
}
