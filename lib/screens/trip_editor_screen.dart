import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/storage_service.dart';
import '../services/places_service.dart';
import '../widgets/place_search_delegate.dart';
import '../widgets/stage_card.dart';

class TripEditorScreen extends StatefulWidget {
  final Trip trip;

  const TripEditorScreen({super.key, required this.trip});

  @override
  State<TripEditorScreen> createState() => _TripEditorScreenState();
}

class _TripEditorScreenState extends State<TripEditorScreen> {
  final StorageService _storage = StorageService();
  late TextEditingController _nameController;
  late Trip _trip;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Deep-copy so mutations don't affect the original until save
    _trip = Trip.fromJson(widget.trip.toJson());
    _nameController = TextEditingController(text: _trip.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addStage() {
    setState(() {
      _trip.stages.add(TripStage(label: ''));
    });
  }

  void _removeStage(int index) {
    setState(() {
      _trip.stages.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _trip.stages.removeAt(oldIndex);
      _trip.stages.insert(newIndex, item);
    });
  }

  Future<void> _searchPlace(int index) async {
    final result = await showSearch<PlaceDetails?>(
      context: context,
      delegate: PlaceSearchDelegate(),
    );
    if (result != null) {
      setState(() {
        _trip.stages[index].addCandidate(
          PlaceCandidate(
            name: result.name,
            placeId: result.placeId,
            lat: result.lat,
            lng: result.lng,
            rating: result.rating,
          ),
        );
      });
    }
  }

  void _selectCandidate(int stageIndex, int candidateIndex) {
    setState(() {
      _trip.stages[stageIndex].selectCandidate(candidateIndex);
    });
  }

  void _removeCandidate(int stageIndex, int candidateIndex) {
    setState(() {
      _trip.stages[stageIndex].removeCandidate(candidateIndex);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen gezi adını girin.')));
      return;
    }

    setState(() => _saving = true);
    _trip.name = name;
    await _storage.saveTrip(_trip);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name.isEmpty ? 'Yeni Gezi' : 'Gezi Düzenle'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
        ],
      ),
      body: Column(
        children: [
          // Trip name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Gezi Adı',
                hintText: 'ör. İstanbul Turu',
                prefixIcon: const Icon(Icons.edit_road),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aşamalar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_trip.stages.length} aşama',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // Stage list
          Expanded(
            child: _trip.stages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aşama ekleyin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _trip.stages.length,
                    onReorder: _onReorder,
                    proxyDecorator: (child, idx, anim) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final stage = _trip.stages[index];
                      return StageCard(
                        key: ValueKey(stage.id),
                        index: index,
                        stage: stage,
                        onAddPlace: () => _searchPlace(index),
                        onDelete: () => _removeStage(index),
                        onLabelChanged: (value) {
                          _trip.stages[index].label = value;
                        },
                        onSelectCandidate: (ci) => _selectCandidate(index, ci),
                        onRemoveCandidate: (ci) => _removeCandidate(index, ci),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStage,
        tooltip: 'Aşama Ekle',
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
