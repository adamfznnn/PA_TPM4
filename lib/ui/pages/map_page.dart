import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  final Color primaryColor = const Color(0xFF800000);
  final LatLng _center = const LatLng(-7.8052, 110.3642);

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionStream;

  double _direction = 0;
  double _lastBearing = 0;

  bool _isCompassAvailable = true;
  bool _isLikelyEmulator = false;
  bool _isAutoRotate = true;

  LatLng? _currentPosition;
  Set<Polyline> _polylines = {};
  Set<Marker> _displayedMarkers = {};

  // Inisialisasi marker di initState agar kita bisa menambahkan fungsi onTap
  late List<Marker> _allMarkers;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _initSensors();
  }

  void _initializeMarkers() {
    // Kita tambahkan onTap pada setiap marker agar memicu pembuatan rute
    _allMarkers = [
      Marker(
        markerId: const MarkerId('sonobudoyo'),
        position: const LatLng(-7.8025, 110.3638),
        infoWindow: const InfoWindow(
          title: 'Museum Sonobudoyo',
          snippet: 'Ketuk untuk rute',
        ),
        onTap: () => _getRouteTo(const LatLng(-7.8025, 110.3638)),
      ),
      Marker(
        markerId: const MarkerId('kraton'),
        position: const LatLng(-7.8052, 110.3642),
        infoWindow: const InfoWindow(
          title: 'Kraton Yogyakarta',
          snippet: 'Ketuk untuk rute',
        ),
        onTap: () => _getRouteTo(const LatLng(-7.8052, 110.3642)),
      ),
      Marker(
        markerId: const MarkerId('taman_sari'),
        position: const LatLng(-7.8098, 110.3592),
        infoWindow: const InfoWindow(
          title: 'Taman Sari',
          snippet: 'Ketuk untuk rute',
        ),
        onTap: () => _getRouteTo(const LatLng(-7.8098, 110.3592)),
      ),
      Marker(
        markerId: const MarkerId('vredeburg'),
        position: const LatLng(-7.8001, 110.3663),
        infoWindow: const InfoWindow(
          title: 'Museum Benteng Vredeburg',
          snippet: 'Ketuk untuk rute',
        ),
        onTap: () => _getRouteTo(const LatLng(-7.8001, 110.3663)),
      ),
      Marker(
        markerId: const MarkerId('affandi'),
        position: const LatLng(-7.7827, 110.3962),
        infoWindow: const InfoWindow(
          title: 'Museum Affandi',
          snippet: 'Ketuk untuk rute',
        ),
        onTap: () => _getRouteTo(const LatLng(-7.7827, 110.3962)),
      ),
    ];
    _displayedMarkers = _allMarkers.toSet();
  }

  void _initSensors() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Ambil lokasi awal satu kali agar _currentPosition tidak null saat klik rute pertama kali
    Position initialPos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(initialPos.latitude, initialPos.longitude);
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _updateMapRotation();
        });

    if (FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!.listen((event) {
        if (!mounted) return;
        if (event.heading == null) return;
        setState(() {
          _direction = event.heading!;
          _isCompassAvailable = true;
        });
        _updateMapRotation();
      });
    }
  }

  void _updateMapRotation() {
    if (_mapController == null || _currentPosition == null || !_isAutoRotate)
      return;
    if ((_direction - _lastBearing).abs() < 5) return;
    _lastBearing = _direction;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 17,
          bearing: _direction,
          tilt: 45,
        ),
      ),
    );
  }

  // FUNGSI UTAMA RUTE
  void _getRouteTo(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mencari lokasi Anda... mohon tunggu.")),
      );
      return;
    }

    PolylinePoints polylinePoints = PolylinePoints();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: dotenv.get("MAPS_API_KEY"),
        request: PolylineRequest(
          origin: PointLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.status == 'OK' && result.points.isNotEmpty) {
        List<LatLng> coords = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: coords,
              color: Colors.blueAccent,
              width: 8,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });

        // Zoom otomatis agar rute terlihat semua
        LatLngBounds bounds;
        if (_currentPosition!.latitude > destination.latitude) {
          bounds = LatLngBounds(
            southwest: destination,
            northeast: _currentPosition!,
          );
        } else {
          bounds = LatLngBounds(
            southwest: _currentPosition!,
            northeast: destination,
          );
        }
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } else {
        debugPrint("Error rute: ${result.errorMessage}");
      }
    } catch (e) {
      debugPrint("Kesalahan sistem: $e");
    }
  }

  void _filterLocations(String query) {
    if (_mapController == null) return;
    if (query.isEmpty) {
      setState(() {
        _displayedMarkers = _allMarkers.toSet();
        _polylines.clear();
      });
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
      return;
    }

    final matches = _allMarkers
        .where(
          (m) => (m.infoWindow.title?.toLowerCase() ?? "").contains(
            query.toLowerCase(),
          ),
        )
        .toList();

    if (matches.isNotEmpty) {
      setState(() => _displayedMarkers = matches.toSet());
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(matches[0].position, 16),
      );
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eksplor Budaya"),
        backgroundColor: primaryColor,
        actions: [
          if (_polylines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => setState(() => _polylines.clear()),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            markers: _displayedMarkers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // SEARCH BOX
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                onSubmitted: _filterLocations,
                decoration: InputDecoration(
                  hintText: "Cari situs budaya...",
                  prefixIcon: const Icon(Icons.map_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _filterLocations(_searchController.text),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Floating Action Buttons (Compass & Rotate)
          Positioned(
            bottom: 30,
            right: 15,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "compass",
                  onPressed: () => _updateMapRotation(),
                  child: const Icon(Icons.explore),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "rotate",
                  backgroundColor: _isAutoRotate ? Colors.green : Colors.grey,
                  onPressed: () =>
                      setState(() => _isAutoRotate = !_isAutoRotate),
                  child: const Icon(Icons.screen_rotation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
