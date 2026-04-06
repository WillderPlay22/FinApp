import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart'; // reutiliza sharedPreferencesProvider

const String _decimalSepKey = 'decimal_separator';

class DecimalSeparatorNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  DecimalSeparatorNotifier(this._prefs)
      : super(_prefs.getString(_decimalSepKey) ?? '.');

  Future<void> setSeparator(String sep) async {
    assert(sep == '.' || sep == ',');
    state = sep;
    await _prefs.setString(_decimalSepKey, sep);
  }
}

final decimalSeparatorProvider =
    StateNotifierProvider<DecimalSeparatorNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DecimalSeparatorNotifier(prefs);
});
