import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PlaceCandidate {
  final String id;
  String name;
  String placeId;
  double lat;
  double lng;
  double? rating;

  PlaceCandidate({
    String? id,
    required this.name,
    required this.placeId,
    required this.lat,
    required this.lng,
    this.rating,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'placeId': placeId,
    'lat': lat,
    'lng': lng,
    'rating': rating,
  };

  factory PlaceCandidate.fromJson(Map<String, dynamic> json) => PlaceCandidate(
    id: json['id'] as String,
    name: json['name'] as String,
    placeId: json['placeId'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    rating: (json['rating'] as num?)?.toDouble(),
  );
}

class TripStage {
  final String id;
  String label;
  List<PlaceCandidate> candidates;
  int selectedIndex;

  TripStage({
    String? id,
    required this.label,
    List<PlaceCandidate>? candidates,
    this.selectedIndex = 0,
  }) : id = id ?? _uuid.v4(),
       candidates = candidates ?? [];

  bool get hasPlace => candidates.isNotEmpty;

  PlaceCandidate? get selectedPlace =>
      candidates.isNotEmpty && selectedIndex < candidates.length
      ? candidates[selectedIndex]
      : null;

  // Convenience getters for backward compatibility
  String? get placeName => selectedPlace?.name;
  String? get placeId => selectedPlace?.placeId;
  double? get lat => selectedPlace?.lat;
  double? get lng => selectedPlace?.lng;

  void addCandidate(PlaceCandidate candidate) {
    candidates.add(candidate);
    // Auto-select the first added candidate
    if (candidates.length == 1) {
      selectedIndex = 0;
    }
  }

  void removeCandidate(int index) {
    candidates.removeAt(index);
    if (selectedIndex >= candidates.length && candidates.isNotEmpty) {
      selectedIndex = candidates.length - 1;
    }
  }

  void selectCandidate(int index) {
    if (index >= 0 && index < candidates.length) {
      selectedIndex = index;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'candidates': candidates.map((c) => c.toJson()).toList(),
    'selectedIndex': selectedIndex,
  };

  factory TripStage.fromJson(Map<String, dynamic> json) {
    // Backward compatibility: old format had placeName/lat/lng directly
    if (json.containsKey('candidates')) {
      return TripStage(
        id: json['id'] as String,
        label: json['label'] as String,
        candidates: (json['candidates'] as List)
            .map((c) => PlaceCandidate.fromJson(c as Map<String, dynamic>))
            .toList(),
        selectedIndex: json['selectedIndex'] as int? ?? 0,
      );
    } else {
      // Legacy migration
      final stage = TripStage(
        id: json['id'] as String,
        label: json['label'] as String,
      );
      if (json['placeName'] != null && json['lat'] != null) {
        stage.addCandidate(
          PlaceCandidate(
            name: json['placeName'] as String,
            placeId: json['placeId'] as String? ?? '',
            lat: (json['lat'] as num).toDouble(),
            lng: (json['lng'] as num).toDouble(),
          ),
        );
      }
      return stage;
    }
  }
}

class Trip {
  final String id;
  String name;
  List<TripStage> stages;
  final DateTime createdAt;

  Trip({
    String? id,
    required this.name,
    List<TripStage>? stages,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       stages = stages ?? [],
       createdAt = createdAt ?? DateTime.now();

  /// Returns only stages that have a valid place selected.
  List<TripStage> get validStages => stages.where((s) => s.hasPlace).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stages': stages.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    name: json['name'] as String,
    stages: (json['stages'] as List)
        .map((s) => TripStage.fromJson(s as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
