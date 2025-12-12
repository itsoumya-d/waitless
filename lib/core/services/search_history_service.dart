import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_providers.dart';

/// Service to manage search history using SharedPreferences
class SearchHistoryService {
  final SharedPreferences _prefs;
  static const String _key = 'recent_searches';
  static const int _maxHistory = 10;

  SearchHistoryService(this._prefs);

  /// Get list of recent searches
  List<String> getRecentSearches() {
    return _prefs.getStringList(_key) ?? [];
  }

  /// Add a search term to history
  Future<void> addSearch(String term) async {
    if (term.trim().isEmpty) return;
    
    final cleanTerm = term.trim();
    List<String> history = getRecentSearches();
    
    // Remove if already exists (to move to top)
    history.removeWhere((item) => item.toLowerCase() == cleanTerm.toLowerCase());
    
    // Add to front
    history.insert(0, cleanTerm);
    
    // Trim to max length
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }
    
    await _prefs.setStringList(_key, history);
  }

  /// Remove a specific search term
  Future<void> removeSearch(String term) async {
    List<String> history = getRecentSearches();
    history.remove(term);
    await _prefs.setStringList(_key, history);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }
}

/// Provider for SearchHistoryService
final searchHistoryServiceProvider = Provider<SearchHistoryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchHistoryService(prefs);
});

/// StateNotifier to expose reactive search history
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final SearchHistoryService _service;

  SearchHistoryNotifier(this._service) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    state = _service.getRecentSearches();
  }

  Future<void> addSearch(String term) async {
    await _service.addSearch(term);
    _loadHistory();
  }

  Future<void> removeSearch(String term) async {
    await _service.removeSearch(term);
    _loadHistory();
  }

  Future<void> clearHistory() async {
    await _service.clearHistory();
    _loadHistory();
  }
}

/// Provider for reactive search history list
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  final service = ref.watch(searchHistoryServiceProvider);
  return SearchHistoryNotifier(service);
});
