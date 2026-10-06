import 'package:flutter/material.dart';

import '../../l10n/app_locale_controller.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class LanguageSettingsPage extends StatelessWidget {
  LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppLocaleController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SettingsPageScaffold(
          title: l10n.language,
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.languageBlurb,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: l10n.language,
                children: [
                  for (final option in AppLocalizations.languageOptions)
                    RadioListTile<String>(
                      value: option.$1,
                      groupValue: controller.preference,
                      title: Text(
                        option.$1 == 'system'
                            ? l10n.languageSystem
                            : option.$2,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setPreference(value);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
