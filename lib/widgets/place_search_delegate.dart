import 'package:flutter/material.dart';
import '../services/places_service.dart';

class PlaceSearchDelegate extends SearchDelegate<PlaceDetails?> {
  final PlacesService _placesService = PlacesService();
  List<PlacePrediction> _predictions = [];

  PlaceSearchDelegate()
    : super(
        searchFieldLabel: 'Mekan ara...',
        searchFieldStyle: const TextStyle(fontSize: 16),
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _predictions = [];
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildPredictionList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Mekan aramak için yazın',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<PlacePrediction>>(
      future: _placesService.autocomplete(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        _predictions = snapshot.data ?? [];
        return _buildPredictionList(context);
      },
    );
  }

  Widget _buildPredictionList(BuildContext context) {
    if (_predictions.isEmpty) {
      return Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _predictions.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.place,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            prediction.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () async {
            final details = await _placesService.getDetails(prediction.placeId);
            if (context.mounted) {
              close(context, details);
            }
          },
        );
      },
    );
  }
}
