import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'data.dart';

const teal = Color(0xFF086E63);
void main() => runApp(const MauriGuide());

class MauriGuide extends StatelessWidget {
  const MauriGuide({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MauriGuide',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      scaffoldBackgroundColor: const Color(0xFFF6F8F5),
      fontFamily: 'IslandSans',
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    ),
    home: const GuideHome(),
  );
}

class GuideHome extends StatefulWidget {
  const GuideHome({super.key});
  @override
  State<GuideHome> createState() => _GuideHomeState();
}

class _GuideHomeState extends State<GuideHome> {
  int tab = 0, days = 3;
  double budget = 1500;
  String category = 'All', query = '', language = 'English', name = 'Traveller';
  final Set<String> interests = {'Nature', 'Beach'}, saved = {};
  final input = TextEditingController();
  final chatScroll = ScrollController();
  List<List<Place>> itinerary = [];
  List<Map<String, String>> messages = [
    {
      'role': 'assistant',
      'text': 'Bonzour! I’m your Mauritius travel companion. Ask me about beaches, local food, transport or your next adventure. Local guide mode is active.',
    },
  ];
  bool busy = false;
  Position? position;
  int rating = 5;
  String tr(String en, String fr, String cr) => language == 'Français'
      ? fr
      : language == 'Kreol'
      ? cr
      : en;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      saved.addAll(p.getStringList('saved') ?? []);
      interests
        ..clear()
        ..addAll(p.getStringList('interests') ?? ['Nature', 'Beach']);
      name = p.getString('name') ?? 'Traveller';
      language = p.getString('language') ?? 'English';
      days = p.getInt('days') ?? 3;
      budget = p.getDouble('budget') ?? 1500;
      final stored = p.getStringList('itinerary');
      if (stored != null) {
        itinerary = stored
            .map(
              (row) =>
                  places.where((p) => row.split(',').contains(p.id)).toList(),
            )
            .toList();
      }
    });
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('saved', saved.toList());
    await p.setStringList('interests', interests.toList());
    await p.setString('name', name);
    await p.setString('language', language);
    await p.setInt('days', days);
    await p.setDouble('budget', budget);
    await p.setStringList(
      'itinerary',
      itinerary.map((d) => d.map((p) => p.id).join(',')).toList(),
    );
  }

  void notice(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  Future<void> open(String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        notice('Unable to open link.');
      }
    } catch (_) {
      notice('Unable to open link.');
    }
  }

  Future<void> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        notice('Enable location services to find nearby places.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        notice(
          'Location permission is unavailable. You can still explore every place.',
        );
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) setState(() => position = p);
      notice('Nearby places sorted using your location.');
    } catch (_) {
      notice(
        'Could not get your location. Try again outdoors or check browser permissions.',
      );
    }
  }

  @override
  void dispose() {
    input.dispose();
    chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final labels = [
      tr('Discover', 'Découvrir', 'Dekouver'),
      tr('My itinerary', 'Mon itinéraire', 'Mo vwayaz'),
      tr('Island map', 'Carte', 'Kart'),
      tr('AI companion', 'Assistant IA', 'Asistan'),
      tr('My profile', 'Mon profil', 'Mo profil'),
    ];
    final icons = [
      Icons.explore_outlined,
      Icons.route_outlined,
      Icons.map_outlined,
      Icons.auto_awesome_outlined,
      Icons.person_outline,
    ];
    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: List.generate(
                5,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 238,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brand(),
                    const SizedBox(height: 48),
                    const Text(
                      'YOUR ISLAND COMPANION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: tab == i,
                          selectedTileColor: teal.withValues(alpha: .08),
                          leading: Icon(icons[i]),
                          title: Text(labels[i]),
                          onTap: () => setState(() => tab = i),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF5EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.eco_outlined, color: teal),
                          SizedBox(height: 8),
                          Text(
                            'Small island. Big impact.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Support local. Tread lightly. Take your memories home.',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MADE FOR MAURITIUS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 20,
                      vertical: 18,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        if (!wide)
                          brand()
                        else
                          const Text(
                            'Explore more. Experience deeper.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: language,
                            items: ['English', 'Français', 'Kreol']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (s) {
                              setState(() => language = s!);
                              persist();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE4EEE6),
                          child: Text(
                            name.isEmpty ? 'T' : name[0].toUpperCase(),
                            style: const TextStyle(color: teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: tab,
                      children: [
                        discover(),
                        planner(),
                        islandMap(),
                        chat(),
                        profile(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget brand() => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.travel_explore, color: teal, size: 29),
      SizedBox(width: 8),
      Text(
        'mauri',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 25,
          color: teal,
        ),
      ),
      Text('guide', style: TextStyle(fontSize: 25, color: teal)),
    ],
  );
  Widget page(List<Widget> children) =>
      ListView(padding: const EdgeInsets.all(28), children: children);
  Widget title(String eyebrow, String heading, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: teal,
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          heading,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, height: 1.5),
        ),
      ],
    ),
  );
  Future<void> weather() async {
    notice('Fetching current weather for Port Louis…');
    try {
      final r = await http
          .get(
            Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=-20.16&longitude=57.50&current=temperature_2m,wind_speed_10m,precipitation&timezone=Indian%2FMauritius',
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw Exception();
      final c = jsonDecode(r.body)['current'];
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Port Louis • current weather'),
          content: Text(
            '${c['temperature_2m']} °C\nWind: ${c['wind_speed_10m']} km/h\nPrecipitation: ${c['precipitation']} mm\nUpdated: ${c['time']} (Mauritius)\n\nSource: Open-Meteo model data. Check official warnings before outdoor activities.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      notice(
        'Weather is unavailable. Check metservice.intnet.mu for official updates.',
      );
    }
  }

  Widget discover() {
    var filtered = places
        .where(
          (p) =>
              (category == 'All' || p.category == category) &&
              ('${p.name} ${p.region}').toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    if (position != null) {
      filtered.sort((a, b) => distance(a).compareTo(distance(b)));
    }
    return page([
      Container(
        height: 400,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: teal,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/beach.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => const SizedBox(),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE6003934), Color(0x35003934)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'YOUR MAURITIUS, REIMAGINED',
                    style: TextStyle(
                      color: Color(0xFFDAE9B5),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'A little island.\nEndless possibilities.',
                      'Une île.\nTant à découvrir.',
                      'Enn ti zil.\nBoukou pou dekouver.',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find hidden gems, embrace local culture,\nand make every day your own.',
                    style: TextStyle(color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDCEAB7),
                      foregroundColor: const Color(0xFF163D32),
                    ),
                    onPressed: () => setState(() => tab = 1),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      tr(
                        'Plan my adventure',
                        'Planifier mon voyage',
                        'Plan mo vwayaz',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.cloud_outlined, size: 18),
            label: const Text('Current weather'),
            onPressed: weather,
          ),
          ActionChip(
            avatar: const Icon(Icons.restaurant_outlined, size: 18),
            label: const Text('Local restaurants ↗'),
            onPressed: () => open(
              'https://www.google.com/maps/search/restaurants+Mauritius/',
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.hotel_outlined, size: 18),
            label: const Text('Places to stay ↗'),
            onPressed: () =>
                open('https://www.google.com/maps/search/hotels+Mauritius/'),
          ),
          ActionChip(
            label: const Text('Events & culture ↗'),
            onPressed: () => open('https://mauritiusnow.com/'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search places or regions',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              onChanged: (s) => setState(() => query = s),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: locate,
            tooltip: 'Find nearby places',
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ['All', 'Beach', 'Nature', 'Culture', 'Adventure']
            .map(
              (s) => ChoiceChip(
                label: Text(s),
                selected: category == s,
                onSelected: (_) => setState(() => category = s),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 28),
      title(
        'CURATED FOR YOUR CURIOSITY',
        tr(
          'Find your kind of escape',
          'Trouvez votre évasion',
          'Trouv ou lavantir',
        ),
        'A few island favourites to get you started. Costs are planning estimates.',
      ),
      if (filtered.isEmpty) const Text('No places found. Try another search.'),
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 1000
              ? 3
              : c.maxWidth > 600
              ? 2
              : 1;
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: filtered
                .map(
                  (p) => SizedBox(
                    width: (c.maxWidth - 18 * (cols - 1)) / cols,
                    child: placeCard(p),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 24),
      const Text(
        'Travel thoughtfully · Respect protected areas · Choose local guides',
        style: TextStyle(color: teal),
      ),
    ]);
  }

  double distance(Place p) =>
      Geolocator.distanceBetween(
        position!.latitude,
        position!.longitude,
        p.lat,
        p.lon,
      ) /
      1000;
  Widget placeCard(Place p) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => detail(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                'https://images.unsplash.com/${p.image}?w=700&q=80',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  height: 170,
                  color: const Color(0xFFD7E7DB),
                  child: const Center(
                    child: Icon(Icons.landscape, size: 60, color: teal),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Chip(
                  label: Text(p.category, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Save place',
                  onPressed: () {
                    setState(
                      () => saved.contains(p.id)
                          ? saved.remove(p.id)
                          : saved.add(p.id),
                    );
                    persist();
                  },
                  icon: Icon(
                    saved.contains(p.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.region.toUpperCase(),
                  style: const TextStyle(
                    color: teal,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    Text(
                      ' ${p.minutes ~/ 60}h ${p.minutes % 60}m',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      p.cost == 0 ? 'Free' : '~ Rs ${p.cost}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (position != null)
                  Text(
                    '${distance(p).toStringAsFixed(1)} km away · straight-line',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  void detail(Place p) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(
            '${p.region} • ${p.category}',
            style: const TextStyle(color: teal),
          ),
          const SizedBox(height: 16),
          Text(p.description, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 16),
          Text(
            'Estimated activity cost: Rs ${p.cost} per person. Transport and meals excluded. Verify current hours and prices before visiting.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => open(
                  'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lon}',
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
              ),
              OutlinedButton(
                onPressed: () => open(
                  'https://www.google.com/search?q=${Uri.encodeComponent('${p.name} Mauritius official opening hours')}',
                ),
                child: const Text('Check current information'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget planner() => page([
    title(
      'LESS PLANNING, MORE LIVING',
      tr('Your island itinerary', 'Votre itinéraire', 'Ou vwayaz lor zil'),
      'Personalised to your interests and daily activity budget.',
    ),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Length of stay: $days days',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: days.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$days',
              onChanged: (v) => setState(() => days = v.round()),
            ),
            Text('Daily activity budget: Rs ${budget.round()} per person'),
            Slider(
              value: budget,
              min: 0,
              max: 5000,
              divisions: 20,
              onChanged: (v) => setState(() => budget = v),
            ),
            const Text('Your interests'),
            Wrap(
              spacing: 8,
              children: ['Beach', 'Nature', 'Culture', 'Adventure']
                  .map(
                    (s) => FilterChip(
                      label: Text(s),
                      selected: interests.contains(s),
                      onSelected: (v) => setState(
                        () => v ? interests.add(s) : interests.remove(s),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() => itinerary = planTrip(days, budget, interests));
                persist();
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate itinerary'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Groups nearby regions where possible. Travel times, meals, accommodation and availability are not included.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 24),
    ...itinerary.asMap().entries.map(
      (e) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAY ${e.key + 1}',
                  style: const TextStyle(
                    color: teal,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (e.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Free day — relax or revisit a favourite. The local catalogue has no more unique matching stops.',
                    ),
                  ),
                ...e.value.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.place_outlined),
                    ),
                    title: Text(p.name),
                    subtitle: Text('${p.region} • ~ Rs ${p.cost}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => detail(p),
                  ),
                ),
                Text(
                  'Estimated activities: Rs ${e.value.fold<int>(0, (sum, p) => sum + p.cost)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ]);
  Widget islandMap() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Explore the island',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: locate,
              tooltip: 'Get my location',
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Text(
          'Tap a marker for details and navigation. Map tiles require internet.',
        ),
      ),
      Expanded(
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-20.27, 57.55),
            initialZoom: 9.3,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'mu.mauriguide.mauriguide',
            ),
            MarkerLayer(
              markers: [
                ...places.map(
                  (p) => Marker(
                    point: LatLng(p.lat, p.lon),
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: p.name,
                      onPressed: () => detail(p),
                      icon: const Icon(
                        Icons.location_on,
                        color: teal,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                if (position != null)
                  Marker(
                    point: LatLng(position!.latitude, position!.longitude),
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => open('https://www.openstreetmap.org/copyright'),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
  Future<void> send([String? prompt]) async {
    final text = (prompt ?? input.text).trim();
    if (text.isEmpty || busy) return;
    input.clear();
    setState(() {
      busy = true;
      messages.add({'role': 'user', 'text': text});
    });
    String reply;
    const endpoint = String.fromEnvironment('AI_ENDPOINT');
    try {
      if (endpoint.isNotEmpty) {
        final uri = Uri.parse(endpoint);
        if (uri.scheme != 'https') throw Exception('HTTPS required');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'messages': messages,
                'language': language,
                'interests': interests.toList(),
                'budget': budget,
              }),
            )
            .timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) throw Exception('Service unavailable');
        reply =
            (jsonDecode(response.body) as Map<String, dynamic>)['reply']
                as String;
      } else {
        reply = localReply(text);
      }
    } catch (_) {
      reply =
          'The live assistant is unavailable. Local guide: ${localReply(text)}';
    }
    if (!mounted) return;
    setState(() {
      messages.add({'role': 'assistant', 'text': reply});
      busy = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScroll.hasClients) {
        chatScroll.animateTo(
          chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String localReply(String text) {
    final q = text.toLowerCase();
    if (q.contains('food') || q.contains('manger') || q.contains('manze')) {
      return tr(
        'Try dholl puri, farata and gateaux piments at local vendors. Port Louis Central Market and Mahébourg are good starting points. Ask about ingredients and allergies.',
        'Goûtez le dholl puri, le farata et les gâteaux piments à Port Louis ou Mahébourg. Vérifiez les ingrédients et allergènes.',
        'Gout dholl puri, farata ek gato pima dan Port Louis ouswa Mahébourg. Demann lor ingredian ek alerzi.',
      );
    }
    if (q.contains('transport') || q.contains('bus')) {
      return tr(
        'Buses are a budget-friendly option; confirm routes and last departures locally. Use licensed taxis and agree the fare first. Open a place and tap Directions for routing.',
        'Les bus sont économiques. Confirmez les horaires sur place. Choisissez un taxi agréé et convenez du prix avant le départ.',
        'Bis enn opsion bonmarse. Verifie ler dernie bis. Pran taxi lisansie ek dakor pri avan ale.',
      );
    }
    if (q.contains('weather') || q.contains('météo') || q.contains('lapli')) {
      return tr(
        'I do not have live weather data. Check Mauritius Meteorological Services at metservice.intnet.mu before hiking, boating or swimming.',
        'Je ne dispose pas de météo en direct. Consultez metservice.intnet.mu avant toute sortie.',
        'Mo pena meteo an direk. Verifie metservice.intnet.mu avan ou sorti.',
      );
    }
    if (q.contains('beach') || q.contains('plage') || q.contains('laplaz')) {
      return tr(
        'Try Flic en Flac for sunset or Blue Bay for the lagoon. Follow local swimming warnings and protect coral. You can find both on the Island map.',
        'Découvrez Flic en Flac au coucher du soleil ou le lagon de Blue Bay. Respectez les consignes de baignade.',
        'Al Flic en Flac pou kouse soley ouswa Blue Bay pou lagon. Respekte bann lavertisman naze.',
      );
    }
    return tr(
      'For your interests, consider ${recommend(interests, budget).take(3).map((p) => p.name).join(', ')}. Use My itinerary to build a budget-aware plan. Local guide mode answers beaches, food, transport and weather questions; open-ended AI requires a configured server.',
      'Selon vos intérêts : ${recommend(interests, budget).take(3).map((p) => p.name).join(', ')}. Créez votre itinéraire dans l’onglet dédié. Le mode local répond aux questions sur les plages, la cuisine, les transports et la météo.',
      'Dapre ou lintere : ${recommend(interests, budget).take(3).map((p) => p.name).join(', ')}. Servi Mo vwayaz pou planifie. Mod lokal reponn lor laplaz, manze, transpor ek meteo.',
    );
  }

  Widget chat() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(24),
        child: title(
          'A LOCAL PERSPECTIVE',
          tr(
            'Meet your island companion',
            'Votre compagnon local',
            'Ou kamarad lokal',
          ),
          const String.fromEnvironment('AI_ENDPOINT').isEmpty
              ? 'Local guide mode • curated answers, no live data'
              : 'Connected assistant • verify travel information',
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: chatScroll,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: messages.length,
          itemBuilder: (c, i) {
            final user = messages[i]['role'] == 'user';
            return Align(
              alignment: user ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 650),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: user ? teal : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  messages[i]['text']!,
                  style: TextStyle(
                    color: user ? Colors.white : Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      if (busy) const LinearProgressIndicator(),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: ['Best beaches', 'Local food', 'Transport tips', 'Weather']
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q),
                    onPressed: busy ? null : () => send(q),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: TextField(
          controller: input,
          onSubmitted: busy ? null : (_) => send(),
          decoration: InputDecoration(
            hintText: 'Ask about Mauritius…',
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            suffixIcon: IconButton(
              onPressed: busy ? null : () => send(),
              icon: const Icon(Icons.arrow_upward, color: teal),
            ),
          ),
        ),
      ),
    ],
  );
  Widget profile() => page([
    title(
      'MAKE YOURSELF AT HOME',
      tr('Your travel profile', 'Votre profil', 'Ou profil'),
      'Preferences and favourites are stored on this device.',
    ),
    TextFormField(
      initialValue: name,
      decoration: const InputDecoration(
        labelText: 'Your name',
        border: OutlineInputBorder(),
      ),
      onChanged: (s) {
        setState(() => name = s);
        persist();
      },
    ),
    const SizedBox(height: 26),
    const Text(
      'SAVED PLACES',
      style: TextStyle(
        color: teal,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 12),
    if (saved.isEmpty) const Text('Tap the heart on a place to save it here.'),
    ...places
        .where((p) => saved.contains(p.id))
        .map(
          (p) => ListTile(
            title: Text(p.name),
            subtitle: Text(p.region),
            onTap: () => detail(p),
            trailing: IconButton(
              onPressed: () {
                setState(() => saved.remove(p.id));
                persist();
              },
              icon: const Icon(Icons.favorite, color: teal),
            ),
          ),
        ),
    const SizedBox(height: 32),
    const Text(
      'How useful is MauriGuide?',
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
    ),
    Row(
      children: List.generate(
        5,
        (i) => IconButton(
          onPressed: () => setState(() => rating = i + 1),
          icon: Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFC39535),
          ),
        ),
      ),
    ),
    FilledButton.tonal(
      onPressed: () async {
        final p = await SharedPreferences.getInstance();
        await p.setInt('feedback', rating);
        notice('Thank you — your rating is saved on this device.');
      },
      child: const Text('Save feedback'),
    ),
    const SizedBox(height: 30),
    const Text(
      'About this prototype',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    const Text(
      'Curated Mauritius attraction catalogue. Photos are illustrative. Prices are estimates. Weather uses Open-Meteo when online. Restaurant, accommodation and event links open external sources. No bookings, live event feed, hotel availability or real-time transport data are connected. English, French and Kreol navigation and core guide replies are included; place descriptions are in English.',
      style: TextStyle(height: 1.6, color: Colors.black54),
    ),
  ]);
}
