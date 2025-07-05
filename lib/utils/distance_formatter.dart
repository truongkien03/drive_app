class DistanceFormatter {
  /// Format distance in meters to human readable format
  static String format(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      double km = distanceInMeters / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)} km';
      } else {
        return '${km.toStringAsFixed(0)} km';
      }
    }
  }

  /// Format distance in kilometers to human readable format
  static String formatKm(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toInt()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)} km';
    }
  }

  /// Convert meters to kilometers
  static double metersToKm(double meters) {
    return meters / 1000;
  }

  /// Convert kilometers to meters
  static double kmToMeters(double km) {
    return km * 1000;
  }

  /// Parse distance string to meters
  static double? parseToMeters(String value) {
    try {
      String cleaned = value.toLowerCase().trim();

      if (cleaned.endsWith('km')) {
        double? km = double.tryParse(cleaned.replaceAll('km', '').trim());
        return km != null ? km * 1000 : null;
      } else if (cleaned.endsWith('m')) {
        return double.tryParse(cleaned.replaceAll('m', '').trim());
      } else {
        // Assume meters if no unit
        return double.tryParse(cleaned);
      }
    } catch (e) {
      return null;
    }
  }
}
