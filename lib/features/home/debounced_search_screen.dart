import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/venue_data_provider.dart';
import '../../core/services/search_history_service.dart';
import '../../models/venue.dart';
import 'widgets/venue_quick_card.dart';

/// Debounced search screen with real-time filtering and history
class DebouncedSearchScreen extends ConsumerStatefulWidget {
  const DebouncedSearchScreen({super.key});

  @override
  ConsumerState<DebouncedSearchScreen> createState() => _DebouncedSearchScreenState();
}

class _DebouncedSearchScreenState extends ConsumerState<DebouncedSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  
  List<Venue> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Filters
  CrowdLevel? _filterCrowdLevel;
  String? _filterCategory;
  
  // Popular searches
  final _popularSearches = ['Trader Joe\'s', 'Gym', 'Coffee', 'Target', 'Whole Foods'];
  
  @override
  void initState() {
    super.initState();
    // Auto-focus after transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    // Debounce: wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    try {
      final repo = ref.read(venueRepositoryProvider);
      // We assume searchVenues does text match. 
      // We will filter additional properties client-side here for the MVP
      // as Firestore full-text + multiple filters is complex without Algolia/Meilisearch.
      final results = await repo.searchVenues(query);
      
      final filtered = results.where((v) {
        if (_filterCrowdLevel != null && v.currentCrowdLevel != _filterCrowdLevel) {
          return false;
        }
        if (_filterCategory != null && v.category != _filterCategory) {
          return false;
        }
        return true;
      }).toList();
      
      if (mounted) {
        setState(() {
          _results = filtered;
          _isSearching = false;
          _hasSearched = true;
        });
        
        // Add to history if good result
        if (filtered.isNotEmpty) {
           ref.read(searchHistoryProvider.notifier).addSearch(query);
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _results = [];
        });
      }
    }
  }

  void _selectVenue(Venue venue) {
    HapticFeedback.selectionClick();
    // Add to history when selecting a result
    ref.read(searchHistoryProvider.notifier).addSearch(_searchController.text);
    context.push('/venue/${venue.id}');
  }

  void _applyQuickSearch(String term) {
    HapticFeedback.selectionClick();
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _onSearchChanged(term);
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTypography.headlineSmall),
                  if (_filterCrowdLevel != null || _filterCategory != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterCrowdLevel = null;
                          _filterCategory = null;
                        });
                        setSheetState(() {}); // Update local sheet state
                        // Re-run search if active
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Crowd Level', style: AppTypography.labelMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: CrowdLevel.values.map((level) {
                  final isSelected = _filterCrowdLevel == level;
                  return ChoiceChip(
                    label: Text(level.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setSheetState(() => _filterCrowdLevel = selected ? level : null);
                      setState(() {});
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.textTertiaryLight.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Category', style: AppTypography.labelMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VenueCategory.values.map((cat) {
                  final isSelected = _filterCategory == cat.name;
                  return ChoiceChip(
                    label: Text('${cat.icon} ${cat.displayName}'),
                    selected: isSelected,
                    onSelected: (selected) {
                       setSheetState(() => _filterCategory = selected ? cat.name : null);
                       setState(() {});
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    side: BorderSide(
                       color: isSelected ? AppColors.primary : AppColors.textTertiaryLight.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundLight.withValues(alpha: 0.95),
                AppColors.backgroundLight.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: _buildSearchField(),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune, 
              color: (_filterCrowdLevel != null || _filterCategory != null) 
                  ? AppColors.primary 
                  : AppColors.textSecondaryLight
            ),
            onPressed: _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.glassGradientLight,
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search venues...',
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
      ),
      style: AppTypography.bodyLarge,
      textInputAction: TextInputAction.search,
      onSubmitted: _performSearch,
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (!_hasSearched) {
      return _buildSuggestions();
    }
    
    if (_results.isEmpty) {
      return _buildEmptyResults();
    }
    
    return _buildResults();
  }

  Widget _buildSuggestions() {
    final recentSearches = ref.watch(searchHistoryProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(searchHistoryProvider.notifier).clearHistory(),
                  child: Text(
                    'Clear',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                final term = recentSearches[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 20, color: Colors.grey),
                  title: Text(term, style: AppTypography.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => ref.read(searchHistoryProvider.notifier).removeSearch(term),
                  ),
                  onTap: () => _applyQuickSearch(term),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          // Popular searches
          Text(
            'Popular Searches',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _popularSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () => _applyQuickSearch(search),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Quick categories
          Text(
            'Browse Categories',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VenueCategory.values.take(8).map((category) {
              return ActionChip(
                avatar: Text(category.icon, style: const TextStyle(fontSize: 16)),
                label: Text(category.displayName),
                onPressed: () => _applyQuickSearch(category.displayName.toLowerCase()),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No venues found',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try filtering differently',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final venue = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VenueQuickCard(
            venue: venue,
            onTap: () => _selectVenue(venue),
          ).animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.05, end: 0),
        );
      },
    );
  }
}
