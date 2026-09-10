import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_es.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEs();

  /// Localises a short UI label while a dedicated ARB entry is not warranted.
  /// Business values returned by Odoo must never pass through this helper.
  String uiText(String spanish, String english) {
    final localizations = Localizations.of<AppLocalizations>(
      this,
      AppLocalizations,
    );
    return localizations?.localeName == 'en' ? english : spanish;
  }
}
