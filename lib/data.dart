class Place {
  final String id, name, region, category, description, image;
  final double lat, lon;
  final int cost, minutes;
  const Place(
    this.id,
    this.name,
    this.region,
    this.category,
    this.description,
    this.lat,
    this.lon,
    this.cost,
    this.minutes,
    this.image,
  );
}

const places = <Place>[
  Place(
    'morne',
    'Le Morne Brabant',
    'Southwest',
    'Adventure',
    'Discover the UNESCO cultural landscape and dramatic lagoon views. Use a qualified guide for the summit; conditions can change.',
    -20.451,
    57.313,
    0,
    180,
    'photo-1516026672322-bc52d61a55d5',
  ),
  Place(
    'chamarel',
    'Seven Coloured Earth',
    'Southwest',
    'Nature',
    'Explore the colourful dunes and nearby waterfall. Entry prices and opening hours must be confirmed with the operator.',
    -20.440,
    57.373,
    600,
    90,
    'photo-1464822759023-fed622ff2c3b',
  ),
  Place(
    'pamplemousses',
    'SSR Botanical Garden',
    'North',
    'Nature',
    'Walk among giant water lilies, palms and historic gardens. Bring water and allow time for a slow stroll.',
    -20.105,
    57.580,
    300,
    120,
    'photo-1441974231531-c6227db76b6e',
  ),
  Place(
    'portlouis',
    'Port Louis Central Market',
    'North',
    'Culture',
    'Taste local snacks, browse crafts and meet market vendors. Ask before photographing people and carry small change.',
    -20.161,
    57.503,
    250,
    90,
    'photo-1555396273-367ea4eb4db5',
  ),
  Place(
    'flic',
    'Flic en Flac',
    'West',
    'Beach',
    'Enjoy a public beach and sunset over the Indian Ocean. Respect swimming warnings and leave coral undisturbed.',
    -20.279,
    57.365,
    0,
    120,
    'photo-1507525428034-b723cf961d3e',
  ),
  Place(
    'bluebay',
    'Blue Bay Marine Park',
    'Southeast',
    'Beach',
    'Discover a protected lagoon with a licensed boat operator. Use reef-safe practices and never touch marine life.',
    -20.443,
    57.716,
    800,
    120,
    'photo-1544551763-46a013bb70d5',
  ),
  Place(
    'mahebourg',
    'Mahébourg Waterfront',
    'Southeast',
    'Culture',
    'Explore the waterfront and local food culture in this historic coastal town. Try dholl puri or a fresh fruit salad.',
    -20.408,
    57.707,
    200,
    90,
    'photo-1510414842594-a61c69b5ae57',
  ),
  Place(
    'gorges',
    'Black River Gorges',
    'Southwest',
    'Adventure',
    'Hike marked forest trails to discover endemic wildlife. Check trail conditions, bring water and stay on signed paths.',
    -20.426,
    57.451,
    0,
    180,
    'photo-1472396961693-142e6e269027',
  ),
];
List<Place> recommend(Set<String> interests, double budget) {
  final result = places.where((p) => p.cost <= budget).toList();
  result.sort((a, b) {
    final score =
        (interests.contains(b.category) ? 1 : 0) -
        (interests.contains(a.category) ? 1 : 0);
    return score != 0 ? score : a.region.compareTo(b.region);
  });
  return result;
}

List<List<Place>> planTrip(int days, double budget, Set<String> interests) {
  final ranked = recommend(interests, budget);
  final remaining = List<Place>.from(ranked);
  final result = <List<Place>>[];
  for (var day = 0; day < days; day++) {
    final stops = <Place>[];
    var spent = 0;
    if (remaining.isNotEmpty) {
      final region = remaining.first.region;
      final options = [
        ...remaining.where((p) => p.region == region),
        ...remaining.where((p) => p.region != region),
      ];
      for (final p in options) {
        if (stops.length >= 2) break;
        if (spent + p.cost <= budget) {
          stops.add(p);
          spent += p.cost;
          remaining.remove(p);
        }
      }
    }
    result.add(stops);
  }
  return result;
}
