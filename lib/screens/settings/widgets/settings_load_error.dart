import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';


/// A failed read must leave an actionable page, without exposing editable
/// fallback values that could overwrite the user's saved settings.
class SettingsLoadError extends StatelessWidget {
  SettingsLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context).t('Unable to load settings. Please try again.'),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).t('Retry'))),
        ],
      ),
    ),
  );
}
