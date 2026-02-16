# Route Planner

Flutter trip planner with Google Maps integration.

## Setup

1. **Get dependencies:**

   ```bash
   flutter pub get
   ```

2. **Configure Google Maps API Key:**

   Enable these APIs in [Google Cloud Console](https://console.cloud.google.com/google/maps-apis):
   - Maps SDK for Android / iOS
   - Places API
   - Directions API

3. **Run the app with your API key:**
   ```bash
   flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
   ```

## How It Works

The API key is injected via `--dart-define` at build time:

- **Dart code** reads it via `String.fromEnvironment('GOOGLE_MAPS_API_KEY')`
- **AndroidManifest.xml** receives it through Gradle manifest placeholders
- **No secrets in source code** — nothing to leak via git

## Features

- Create trips with named stages (e.g. Kahvaltı, Müze)
- Add multiple place candidates per stage and choose between them
- Search places via Google Places Autocomplete
- View routes on map with markers and polylines
- Export navigation to Google Maps app
- Local storage with SharedPreferences
