import 'package:flutter/material.dart';

/// Holds the current language choice (English / Tamil) and notifies the
/// whole app to rebuild when the user toggles it.
class LanguageProvider extends ChangeNotifier {
  bool _isTamil = false;

  bool get isTamil => _isTamil;

  void toggleLanguage() {
    _isTamil = !_isTamil;
    notifyListeners();
  }

  void setTamil(bool value) {
    _isTamil = value;
    notifyListeners();
  }

  // Small helper so screens can do: lang.t('Scan', 'ஸ்கேன்')
  String t(String english, String tamil) => _isTamil ? tamil : english;
}
