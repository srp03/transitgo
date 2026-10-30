import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/bus_model.dart';
import '../../data/models/stop_model.dart';

class OsmMapWidget extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final List<StopModel> routeStops;
  final LatLng? userLocation;
  final List<BusLocationModel> buses;
  final void Function(StopModel stop)? onStopSelected;
  final void Function(BusLocationModel bus)? onBusSelected;
  final bool showControls;
  final double height;

  const OsmMapWidget({
    super.key,
    this.initialCenter,
    this.initialZoom = 13.0,
    this.routeStops = const [],
    this.userLocation,
    this.buses = const [],
    this.onStopSelected,
    this.onBusSelected,
    this.showControls = true,
    this.height = 300,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _recenter() {
    final target = widget.userLocation ??
        (widget.routeStops.isNotEmpty
            ? LatLng(widget.routeStops.first.latitude, widget.routeStops.first.longitude)
            : const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude));
    _mapController.move(target, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCenter = widget.initialCenter ??
        widget.userLocation ??
        (widget.routeStops.isNotEmpty
            ? LatLng(widget.routeStops.first.latitude, widget.routeStops.first.longitude)
            : const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude));

    // Construct route polyline from stop coordinates
    final polylinePoints = widget.routeStops
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    // Markers: user, stops, buses
    final markers = <Marker>[];

    // User marker
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          point: widget.userLocation!,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    // Stop markers
    for (int i = 0; i < widget.routeStops.length; i++) {
      final stop = widget.routeStops[i];
      if (stop.latitude == 0.0 || stop.longitude == 0.0) continue;
      final isFirst = i == 0;
      final isLast = i == widget.routeStops.length - 1;

      markers.add(
        Marker(
          point: LatLng(stop.latitude, stop.longitude),
          width: isFirst || isLast ? 34 : 24,
          height: isFirst || isLast ? 34 : 24,
          child: GestureDetector(
            onTap: () => widget.onStopSelected?.call(stop),
            child: Container(
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.success
                    : isLast
                        ? AppColors.danger
                        : AppColors.primaryNavy,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isFirst || isLast ? 11 : 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Bus markers
    for (final bus in widget.buses) {
      if (bus.latitude == 0.0 || bus.longitude == 0.0) continue;
      markers.add(
        Marker(
          point: LatLng(bus.latitude, bus.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => widget.onBusSelected?.call(bus),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accentAmber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentAmber.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.directions_bus, color: Colors.black, size: 22),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: effectiveCenter,
                initialZoom: widget.initialZoom,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: AppConfig.userAgentPackage,
                  tileProvider: NetworkTileProvider(),
                ),
                if (polylinePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        strokeWidth: 4.5,
                        color: AppColors.accentTeal,
                        borderColor: AppColors.primaryNavyDark.withValues(alpha: 0.4),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            // Map controls overlay
            if (widget.showControls)
              PositionEndDock(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onRecenter: _recenter,
              ),
          ],
        ),
      ),
    );
  }
}

class PositionEndDock extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const PositionEndDock({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapButton(
            icon: Icons.my_location_rounded,
            onPressed: onRecenter,
            tooltip: 'Center Location',
          ),
          const SizedBox(height: 6),
          _MapButton(
            icon: Icons.add,
            onPressed: onZoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: 6),
          _MapButton(
            icon: Icons.remove,
            onPressed: onZoomOut,
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppColors.primaryNavy),
        ),
      ),
    );
  }
}
