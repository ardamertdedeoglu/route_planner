import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class DirectionsService {
  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Returns a list of [LatLng] points representing the route through all
  /// the given [waypoints]. The first element is the origin and the last is
  /// the destination; everything in between is treated as a waypoint.
  Future<List<LatLng>> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return [];

    final origin = waypoints.first;
    final destination = waypoints.last;

    String waypointParam = '';
    if (waypoints.length > 2) {
      final middle = waypoints.sublist(1, waypoints.length - 1);
      waypointParam =
          '&waypoints=${middle.map((w) => '${w.latitude},${w.longitude}').join('|')}';
    }

    final url = Uri.parse(
      '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '$waypointParam'
      '&mode=driving'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return [];

    final overviewPolyline = routes[0]['overview_polyline']['points'] as String;
    return _decodePolyline(overviewPolyline);
  }

  /// Decodes an encoded polyline string into a list of [LatLng].
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
