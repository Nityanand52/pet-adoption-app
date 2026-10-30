
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RescueMapPage extends StatefulWidget {
  const RescueMapPage({super.key});

  @override
  State<RescueMapPage> createState() => _RescueMapPageState();
}

class _RescueMapPageState extends State<RescueMapPage> {
  final MapController mapController = MapController();

  bool locating = false;

  void zoomIn() {
    final camera = mapController.camera;
    mapController.move(
      camera.center,
      (camera.zoom + 1).clamp(2.0, 19.0).toDouble(),
    );
  }

  void zoomOut() {
    final camera = mapController.camera;
    mapController.move(
      camera.center,
      (camera.zoom - 1).clamp(2.0, 19.0).toDouble(),
    );
  }

  void resetRotation() {
    mapController.rotate(0);
  }

  Future<void> goToMyLocation() async {
    setState(() => locating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please enable location services');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      mapController.move(
        LatLng(position.latitude, position.longitude),
        15,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => locating = false);
      }
    }
  }

  void showReportDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['animalType']?.toString() ?? 'Animal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Condition: ${data['condition'] ?? ''}'),
              Text('Location: ${data['location'] ?? ''}'),
              Text('Status: ${data['status'] ?? 'Pending'}'),
              const SizedBox(height: 10),
              Text(data['description']?.toString() ?? ''),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Rescue Map'),
        actions: [
          IconButton(
            tooltip: 'My location',
            onPressed: locating ? null : goToMyLocation,
            icon: locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('animalReports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load reports: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final markers = <Marker>[];

          for (final doc in snapshot.data!.docs) {
            final data = doc.data();

            if (data['latitude'] is! num ||
                data['longitude'] is! num) {
              continue;
            }

            final lat = (data['latitude'] as num).toDouble();
            final lng = (data['longitude'] as num).toDouble();

            final status = data['status']?.toString() ?? 'Pending';

            final color = status == 'Resolved'
                ? Colors.green
                : status == 'In Progress'
                    ? Colors.orange
                    : Colors.red;

            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => showReportDetails(data),
                  child: Icon(
                    Icons.location_on,
                    color: color,
                    size: 40,
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: markers.isNotEmpty
                      ? markers.first.point
                      : const LatLng(20.5937, 78.9629),
                  initialZoom: markers.isNotEmpty ? 12 : 5,
                  minZoom: 2,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.pet_adoption_app',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),

              // ZOOM AND MAP CONTROLS
              Positioned(
                right: 15,
                bottom: 70,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoomIn',
                      tooltip: 'Zoom in',
                      onPressed: zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'zoomOut',
                      tooltip: 'Zoom out',
                      onPressed: zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'north',
                      tooltip: 'Reset rotation',
                      onPressed: resetRotation,
                      child: const Icon(Icons.explore),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'location',
                      tooltip: 'My location',
                      onPressed: locating ? null : goToMyLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // REPORT COUNT
              Positioned(
                top: 15,
                left: 15,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${markers.length} Rescue Reports',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
