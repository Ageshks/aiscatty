/// Kerala districts with approximate district-centre coordinates.
/// Coordinates are used ONLY to detect which district a user is in and to
/// compute approximate distances. They are never shown to users.
class KeralaDistrict {
  final String name;
  final double lat;
  final double lng;
  const KeralaDistrict(this.name, this.lat, this.lng);
}

class KeralaDistricts {
  static const List<KeralaDistrict> all = [
    KeralaDistrict('Thiruvananthapuram', 8.5241, 76.9366),
    KeralaDistrict('Kollam', 8.8932, 76.6141),
    KeralaDistrict('Pathanamthitta', 9.2648, 76.7870),
    KeralaDistrict('Alappuzha', 9.4981, 76.3388),
    KeralaDistrict('Kottayam', 9.5916, 76.5222),
    KeralaDistrict('Idukki', 9.8497, 76.9730),
    KeralaDistrict('Ernakulam', 9.9816, 76.2999),
    KeralaDistrict('Thrissur', 10.5276, 76.2144),
    KeralaDistrict('Palakkad', 10.7867, 76.6548),
    KeralaDistrict('Malappuram', 11.0510, 76.0711),
    KeralaDistrict('Kozhikode', 11.2588, 75.7804),
    KeralaDistrict('Wayanad', 11.6854, 76.1320),
    KeralaDistrict('Kannur', 11.8745, 75.3704),
    KeralaDistrict('Kasaragod', 12.4996, 74.9869),
  ];

  static final List<String> names =
      all.map((d) => d.name).toList(growable: false);

  static const defaultState = 'Kerala';

  /// Finds the district whose centre is nearest to the given coordinates.
  /// This is an offline approximation — accurate enough for district-level
  /// discovery in Kerala and it never fails because of network issues.
  static String detectDistrict(double latitude, double longitude) {
    KeralaDistrict? best;
    double bestDistance = double.infinity;
    for (final d in all) {
      final dx = (d.lat - latitude) * 111.0; // ~km per degree latitude
      final dy = (d.lng - longitude) * 107.0; // ~km per degree longitude here
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = d;
      }
    }
    return best?.name ?? defaultState;
  }
}
