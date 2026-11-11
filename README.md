# MauriGuide — Flutter tourism companion

A runnable academic prototype for **MST_AC_03: MauriGuide: An AI-Embedded Smart Travel Guide for Mauritius**. Flutter application targets Android, iOS and web.

## Run

Install current stable Flutter (this project was validated using Flutter 3.47.9 / Dart 3.13.7). From this directory:

```sh
flutter pub get
flutter run -d chrome
```

For Android, start an emulator or connect a device, then use `flutter run`. For iOS use macOS with Xcode and a simulator/device. Device location requires permission; web location requires localhost or HTTPS.

```sh
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

The included `pubspec.lock` pins the validated dependencies. Android and iOS build scaffolds are included; native release signing must be configured for distribution.

## Working features

- Responsive discovery interface with search, category filters and eight curated places.
- Budget-aware, interest-ranked itinerary generation for 1–7 days. Stops are unique and each day's activity estimates stay within budget. Places in a common region are preferred, but this is not a route optimiser.
- Locally saved profile, preferences, itinerary, favourites and rating via SharedPreferences.
- OpenStreetMap interactive map, location permission handling, straight-line nearby sorting, external Google Maps directions.
- Live Port Louis weather through Open-Meteo, with timestamps and failure handling.
- English, French and Mauritian Kreol navigation and core assistant replies. Catalogue descriptions and secondary UI copy remain English. Kreol copy should receive native-speaker review.
- Local rule-based travel assistant, including food, beaches, transport and weather advice. It is explicitly labelled local mode.
- Optional real AI through a server-side OpenAI proxy, with timeout/error fallback to local guidance.
- External links for restaurant/hotel discovery, current operator information and tourism events.

## Optional AI setup

`server/server.py` uses Python 3 standard library; no Python dependencies are required. Set `OPENAI_API_KEY` privately in your server environment and optionally `OPENAI_MODEL` (default `gpt-4.1-mini`). Do not put a provider key in Flutter or commit it.

```sh
python3 server/server.py
```

The development server binds `127.0.0.1:8787`. For Flutter integration, put it behind your own HTTPS endpoint and build:

```sh
flutter run -d chrome --web-port=8080 --dart-define=AI_ENDPOINT=https://YOUR-SERVER/chat
```

Set server `ALLOWED_ORIGIN` to the exact deployed web origin. `POST /chat` accepts `messages: [{role: "user"|"assistant", text: "..."}]`, `language`, `interests`, and `budget`; returns `{ "reply": "..." }`. The app requires HTTPS for this endpoint.

The proxy is development scaffolding. Before public deployment add authentication, per-user quotas, rate limits, monitoring and appropriate privacy disclosures. The AI has no live browsing tools; it must not be used as a source of verified availability, emergency advice or current weather.

## Data and limitations

Attraction prices are illustrative planning estimates in MUR, not quotations. Transport, accommodation and meal costs are excluded. Images come from Unsplash and are illustrative, not verified attraction photographs. Replace with licensed, location-accurate images for submission/publication. OpenStreetMap tiles and Open-Meteo require internet; respect their usage terms and attribution requirements. Weather is model data, not an official warning feed.

No web scraping pipeline, hotel inventory, bookings, live event ingestion, live public transport feed, cloud accounts, shared feedback database or production authentication is included. The eight-place catalogue can be extended in `lib/data.dart`; verify prices, coordinates and descriptions against operators before release. Feedback is stored on the device and is not sent to anyone.

## Structure

- `lib/main.dart`: application, screens, device persistence, map, weather and chat integration.
- `lib/data.dart`: curated catalogue, ranking and itinerary functions.
- `server/server.py`: optional AI proxy.
- `test/widget_test.dart`: budget, uniqueness, ranking and UI flow tests.
- `PROJECT_REPORT.md`: scope mapping and evaluation approach.
