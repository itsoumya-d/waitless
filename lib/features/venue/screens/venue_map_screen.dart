import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/venue_data_provider.dart';
import '../../../models/venue.dart';

/// Interactive venue map view using Flutter Map (OpenStreetMap)
class VenueMapScreen extends ConsumerStatefulWidget {
  const VenueMapScreen({super.key});

  @override
  ConsumerState<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends ConsumerState<VenueMapScreen> {
  final MapController _mapController = MapController();
  Venue? _selectedVenue;
  CrowdLevel? _filterLevel;
  
  // Default center (New York) if no venues
  final LatLng _defaultCenter = const LatLng(40.7128, -74.0060);
  final double _defaultZoom = 13.0;

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(fetchNearbyVenuesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Map'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          PopupMenuButton<CrowdLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (level) => setState(() => _filterLevel = level),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Venues'),
              ),
              ...CrowdLevel.values.map((level) => PopupMenuItem(
                value: level,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getLevelColor(level),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(level.displayName),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: venuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('Venue Map Error: $e');
          return Center(child: Text('Error loading map data: $e'));
        },
        data: (venues) => _buildMapView(venues),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () {
              final zoom = _mapController.camera.zoom + 1;
              _mapController.move(_mapController.camera.center, zoom);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () {
              final zoom = _mapController.camera.zoom - 1;
              _mapController.move(_mapController.camera.center, zoom);
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'my_location',
            onPressed: () {
              // In a real app we'd get current location. 
              // For now, reset to default or first venue.
               _mapController.move(_defaultCenter, _defaultZoom);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(List<Venue> allVenues) {
    // Filter venues
    final venues = _filterLevel != null
        ? allVenues.where((v) => v.currentCrowdLevel == _filterLevel).toList()
        : allVenues;
        
    // Calculate center
    LatLng center = _defaultCenter;
    if (venues.isNotEmpty) {
      // Simple average for center
      double sumLat = 0;
      double sumLng = 0;
      for (var v in venues) {
        sumLat += v.latitude;
        sumLng += v.longitude;
      }
      center = LatLng(sumLat / venues.length, sumLng / venues.length);
    }
    
    // Create markers
    final markers = venues.map((venue) => Marker(
      point: LatLng(venue.latitude, venue.longitude),
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: () {
           HapticFeedback.selectionClick();
           setState(() => _selectedVenue = venue);
        },
        child: _buildVenueMarkerIcon(venue),
      ),
    )).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _defaultZoom,
            onTap: (_, __) => setState(() => _selectedVenue = null),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.waitless.app',
              maxZoom: 19,
            ),
            MarkerLayer(markers: markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
              ],
            ),
          ],
        ),
        
        // Selected venue card
        if (_selectedVenue != null)
          Positioned(
            bottom: 100, // Above FABs
            left: 16,
            right: 16,
            child: _buildVenueCard(_selectedVenue!),
          ),
      ],
    );
  }
  
  Widget _buildVenueMarkerIcon(Venue venue) {
    final isSelected = _selectedVenue?.id == venue.id;
    final color = _getLevelColor(venue.currentCrowdLevel);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getCategoryEmoji(venue),
          style: const TextStyle(fontSize: 22), // Slightly larger emoji
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.2, 1.2),
      duration: 200.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildVenueCard(Venue venue) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getLevelColor(venue.currentCrowdLevel).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(venue),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue.name, style: AppTypography.titleSmall),
                    Text(
                      venue.address,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildCrowdBadge(venue.currentCrowdLevel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedVenue = null),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/venue/${venue.id}'),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCrowdBadge(CrowdLevel level) {
    final color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            level.displayName,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return AppColors.crowdLow;
      case CrowdLevel.medium:
        return AppColors.crowdMedium;
      case CrowdLevel.high:
        return AppColors.crowdHigh;
      case CrowdLevel.veryHigh:
        return AppColors.crowdVeryHigh;
    }
  }

  String _getCategoryEmoji(Venue venue) {
    final category = VenueCategory.values.firstWhere(
      (c) => c.name == venue.category,
      orElse: () => VenueCategory.other,
    );
    return category.icon;
  }
}
