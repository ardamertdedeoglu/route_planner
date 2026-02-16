import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../services/directions_service.dart';

class MapScreen extends StatefulWidget {
  final Trip trip;

  const MapScreen({super.key, required this.trip});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DirectionsService _directions = DirectionsService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loadingRoute = true;

  List<TripStage> get _validStages => widget.trip.validStages;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _fetchRoute();
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < _validStages.length; i++) {
      final stage = _validStages[i];
      markers.add(
        Marker(
          markerId: MarkerId(stage.id),
          position: LatLng(stage.lat!, stage.lng!),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stage.label.isEmpty ? "Durak" : stage.label}',
            snippet: stage.placeName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0
                ? BitmapDescriptor.hueGreen
                : i == _validStages.length - 1
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    _markers = markers;
  }

  Future<void> _fetchRoute() async {
    if (_validStages.length < 2) {
      setState(() => _loadingRoute = false);
      return;
    }

    final waypoints = _validStages.map((s) => LatLng(s.lat!, s.lng!)).toList();
    final routePoints = await _directions.getRoute(waypoints);

    if (routePoints.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Theme.of(context).colorScheme.primary,
            width: 5,
          ),
        };
      });
    }

    setState(() => _loadingRoute = false);
    _fitBounds();
  }

  void _fitBounds() {
    if (_validStages.isEmpty || _mapController == null) return;

    double minLat = _validStages.first.lat!;
    double maxLat = _validStages.first.lat!;
    double minLng = _validStages.first.lng!;
    double maxLng = _validStages.first.lng!;

    for (final s in _validStages) {
      if (s.lat! < minLat) minLat = s.lat!;
      if (s.lat! > maxLat) maxLat = s.lat!;
      if (s.lng! < minLng) minLng = s.lng!;
      if (s.lng! > maxLng) maxLng = s.lng!;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    if (_validStages.length < 2) return;

    final origin = '${_validStages.first.lat},${_validStages.first.lng}';
    final destination = '${_validStages.last.lat},${_validStages.last.lng}';

    String waypoints = '';
    if (_validStages.length > 2) {
      final middle = _validStages.sublist(1, _validStages.length - 1);
      waypoints =
          '&waypoints=${middle.map((s) => '${s.lat},${s.lng}').join('|')}';
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$destination'
      '$waypoints'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialPos = _validStages.isNotEmpty
        ? LatLng(_validStages.first.lat!, _validStages.first.lng!)
        : const LatLng(41.0082, 28.9784); // Default: Istanbul

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        actions: [
          if (_validStages.length >= 2)
            TextButton.icon(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.navigation),
              label: const Text('Navigasyon'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 13),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              // Delay to ensure map is rendered before fitting bounds
              Future.delayed(const Duration(milliseconds: 500), _fitBounds);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading overlay
          if (_loadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Rota hesaplanıyor...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Bottom stage list
      bottomSheet: _buildStageList(theme),
    );
  }

  Widget _buildStageList(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _validStages.length,
              itemBuilder: (context, index) {
                final stage = _validStages[index];
                final isFirst = index == 0;
                final isLast = index == _validStages.length - 1;

                return Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card(
                    color: isFirst
                        ? Colors.green.shade50
                        : isLast
                        ? Colors.red.shade50
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? Colors.green
                                      : isLast
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  stage.label.isEmpty ? 'Durak' : stage.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage.placeName ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
