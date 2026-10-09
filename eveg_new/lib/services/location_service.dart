import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/lat_lng.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  Future<bool> requestPermissions() async {
    final locationStatus = await Permission.location.request();
    final locationAlwaysStatus = await Permission.locationAlways.request();
    
    return locationStatus.isGranted || locationAlwaysStatus.isGranted;
  }

  Future<bool> checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;
    
    return locationStatus.isGranted || locationAlwaysStatus.isGranted;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return position;
    } catch (e) {
      print('Konum alınamadı: $e');
      return null;
    }
  }

  void startLocationTracking() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10 metre
        ),
      ).listen((Position position) {
        _locationController.add(position);
      });
    } catch (e) {
      print('Konum takibi başlatılamadı: $e');
    }
  }

  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  double calculateDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }
    
    return totalDistance;
  }

  double calculateArea(List<LatLng> route) {
    if (route.length < 3) return 0.0;
    
    // Basit polygon alan hesaplama (Shoelace formula)
    double area = 0.0;
    int j = route.length - 1;
    
    for (int i = 0; i < route.length; i++) {
      area += (route[j].longitude + route[i].longitude) * 
              (route[j].latitude - route[i].latitude);
      j = i;
    }
    
    area = area.abs() / 2.0;
    
    // Yaklaşık metrekare dönüşümü (1 derece ≈ 111000 metre)
    return area * 111000 * 111000;
  }

  double calculateAverageSpeed(double distance, Duration duration) {
    if (duration.inSeconds == 0) return 0.0;
    
    // km/saat cinsinden
    final hours = duration.inSeconds / 3600;
    final km = distance / 1000;
    
    return km / hours;
  }

  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
} 