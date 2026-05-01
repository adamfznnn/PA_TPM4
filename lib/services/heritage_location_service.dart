import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HeritagePlace {
  final String name;
  final String vicinity;
  final double lat;
  final double lng;
  final double distanceKm;
  final String? photoReference;
  final double? rating;
  final String placeId;

  HeritagePlace({
    required this.name,
    required this.vicinity,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.photoReference,
    this.rating,
    required this.placeId,
  });

  factory HeritagePlace.fromJson(Map<String, dynamic> json, double distanceKm) {
    final loc = json['geometry']['location'];
    final photos = json['photos'] as List?;
    return HeritagePlace(
      name: json['name'],
      vicinity: json['vicinity'] ?? '',
      lat: loc['lat'].toDouble(),
      lng: loc['lng'].toDouble(),
      distanceKm: distanceKm,
      photoReference: photos != null && photos.isNotEmpty
          ? photos[0]['photo_reference']
          : null,
      rating: json['rating']?.toDouble(),
      placeId: json['place_id'],
    );
  }
}

class HeritageLocationService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Keyword untuk filter warisan budaya
  static const List<String> _heritageKeywords = [
    'museum', 'batik', 'candi', 'keraton', 'kraton',
    'heritage', 'budaya', 'traditional'
  ];

  /// Minta izin dan ambil lokasi saat ini
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location service disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Ambil tempat warisan terdekat dari Google Places API
  static Future<List<HeritagePlace>> getNearbyHeritagePlaces({
    int radiusMeters = 5000,
  }) async {
    final position = await getCurrentPosition();
    final lat = position.latitude;
    final lng = position.longitude;

    List<HeritagePlace> allPlaces = [];

    // Cari dengan beberapa keyword
    for (String keyword in ['museum', 'batik', 'candi', 'keraton']) {
      final uri = Uri.parse(
        '$_baseUrl?location=$lat,$lng'
        '&radius=$radiusMeters'
        '&keyword=$keyword'
        '&language=id'
        '&key=$_apiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        for (var place in results) {
          final pLat = place['geometry']['location']['lat'].toDouble();
          final pLng = place['geometry']['location']['lng'].toDouble();
          final distanceM = Geolocator.distanceBetween(lat, lng, pLat, pLng);

          // Hindari duplikat berdasarkan placeId
          final alreadyAdded =
              allPlaces.any((p) => p.placeId == place['place_id']);
          if (!alreadyAdded) {
            allPlaces.add(
              HeritagePlace.fromJson(place, distanceM / 1000),
            );
          }
        }
      }
    }

    // Urutkan berdasarkan jarak
    allPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return allPlaces;
  }

  /// URL foto dari photo_reference
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }
}