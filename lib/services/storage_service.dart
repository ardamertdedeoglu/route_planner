import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

class StorageService {
  static const _key = 'trips';

  Future<List<Trip>> getTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveAll(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(trips.map((t) => t.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> saveTrip(Trip trip) async {
    final trips = await getTrips();
    final idx = trips.indexWhere((t) => t.id == trip.id);
    if (idx >= 0) {
      trips[idx] = trip;
    } else {
      trips.insert(0, trip);
    }
    await _saveAll(trips);
  }

  Future<void> deleteTrip(String id) async {
    final trips = await getTrips();
    trips.removeWhere((t) => t.id == id);
    await _saveAll(trips);
  }
}
