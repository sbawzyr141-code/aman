import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormDraftStorage {
  static const String _keyPrefix = 'aman_app.draft';

  static String _keyFor(String formId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return '$_keyPrefix.$userId.$formId';
  }

  static Future<Map<String, dynamic>> load(String formId) async {
    final preferences = SharedPreferencesAsync();
    final encodedDraft = await preferences.getString(_keyFor(formId));
    if (encodedDraft == null) return {};

    final decodedDraft = jsonDecode(encodedDraft);
    if (decodedDraft is Map<String, dynamic>) return decodedDraft;

    throw const FormatException('Stored form draft is not a JSON object.');
  }

  static Future<void> save(
    String formId,
    Map<String, dynamic> draft,
  ) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(_keyFor(formId), jsonEncode(draft));
  }

  static Future<void> clear(String formId) async {
    final preferences = SharedPreferencesAsync();
    await preferences.remove(_keyFor(formId));
  }
}
