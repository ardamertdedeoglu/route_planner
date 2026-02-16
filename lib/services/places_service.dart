import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({required this.placeId, required this.description});
}

class PlaceDetails {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final double? rating;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.rating,
  });
}

class PlacesService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlacePrediction>> autocomplete(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(query)}'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final predictions = data['predictions'] as List? ?? [];

    return predictions.map((p) {
      return PlacePrediction(
        placeId: p['place_id'] as String,
        description: p['description'] as String,
      );
    }).toList();
  }

  Future<PlaceDetails?> getDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId'
      '&fields=name,geometry,rating,place_id'
      '&key=$googleMapsApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final result = data['result'];
    if (result == null) return null;

    final location = result['geometry']['location'];
    return PlaceDetails(
      placeId: result['place_id'] as String,
      name: result['name'] as String,
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
      rating: (result['rating'] as num?)?.toDouble(),
    );
  }
}
