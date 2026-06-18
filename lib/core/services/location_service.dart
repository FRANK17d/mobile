import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenadas simples.
class LatLng {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Obtiene la ubicación del dispositivo con manejo de permisos.
/// Si el permiso se niega o el servicio está apagado, devuelve null
/// (el flujo cae a la cercanía por distrito — nunca rompe).
class LocationService {
  /// Pide permiso si hace falta y devuelve la posición actual, o null.
  Future<LatLng?> getCurrentLatLng() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }

  /// Distancia en km entre dos coordenadas (Geolocator usa Haversine).
  double distanceKm(LatLng a, LatLng b) {
    final meters = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return meters / 1000.0;
  }
}
