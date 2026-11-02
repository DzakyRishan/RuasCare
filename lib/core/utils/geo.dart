import 'dart:math' as math;

/// Utilitas geografis murni (tanpa dependensi Flutter).
abstract final class Geo {
  static const double _earthRadiusKm = 6371.0088;

  /// Jarak great-circle (rumus Haversine) dalam kilometer.
  ///
  /// Rumus yang sama dipakai backend (PRD §10) sehingga hasil filter radius
  /// di Fake repository sejalan dengan hasil API nanti.
  static double haversineKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final dLat = _toRadians(toLatitude - fromLatitude);
    final dLng = _toRadians(toLongitude - fromLongitude);
    final lat1 = _toRadians(fromLatitude);
    final lat2 = _toRadians(toLatitude);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static bool isValidLatitude(double value) => value >= -90 && value <= 90;

  static bool isValidLongitude(double value) => value >= -180 && value <= 180;

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
