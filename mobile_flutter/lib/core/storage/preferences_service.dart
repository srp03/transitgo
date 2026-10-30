import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyApiUrl = 'transitgo_api_base_url';
  static const String keyFavourites = 'transitgo_favourite_routes';
  static const String keyRecentSearches = 'transitgo_recent_searches';
  static const String keyThemeMode = 'transitgo_theme_mode';
  static const String keyGuestMode = 'transitgo_guest_mode';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // API Base URL
  String? getApiBaseUrl() => _prefs.getString(keyApiUrl);
  Future<void> setApiBaseUrl(String url) async => _prefs.setString(keyApiUrl, url);
  Future<void> clearApiBaseUrl() async => _prefs.remove(keyApiUrl);

  // Favourites
  List<String> getFavouriteRouteIds() {
    return _prefs.getStringList(keyFavourites) ?? [];
  }

  Future<void> toggleFavouriteRouteId(String routeId) async {
    final list = getFavouriteRouteIds().toList();
    if (list.contains(routeId)) {
      list.remove(routeId);
    } else {
      list.add(routeId);
    }
    await _prefs.setStringList(keyFavourites, list);
  }

  bool isFavourite(String routeId) {
    return getFavouriteRouteIds().contains(routeId);
  }

  // Recent Searches
  List<Map<String, String>> getRecentSearches() {
    final raw = _prefs.getStringList(keyRecentSearches) ?? [];
    return raw.map((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return {
          'from': map['from']?.toString() ?? '',
          'to': map['to']?.toString() ?? '',
        };
      } catch (_) {
        return {'from': '', 'to': ''};
      }
    }).where((element) => element['from']!.isNotEmpty || element['to']!.isNotEmpty).toList();
  }

  Future<void> addRecentSearch(String from, String to) async {
    if (from.trim().isEmpty && to.trim().isEmpty) return;
    final current = getRecentSearches();
    current.removeWhere((item) =>
        item['from']?.toLowerCase() == from.toLowerCase() &&
        item['to']?.toLowerCase() == to.toLowerCase());
    current.insert(0, {'from': from.trim(), 'to': to.trim()});
    final truncated = current.take(10).toList();
    final serialized = truncated.map((e) => jsonEncode(e)).toList();
    await _prefs.setStringList(keyRecentSearches, serialized);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(keyRecentSearches);
  }

  // Theme mode
  String getThemeMode() => _prefs.getString(keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) async => _prefs.setString(keyThemeMode, mode);
}
