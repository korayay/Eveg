import 'dart:async';
import 'dart:math' as math;
import '../models/user.dart' as app_user;
import '../models/run.dart';
import '../models/area.dart';
import '../models/lat_lng.dart';

class MockFirebaseService {
  static final MockFirebaseService _instance = MockFirebaseService._internal();
  factory MockFirebaseService() => _instance;
  MockFirebaseService._internal();

  // Mock veriler
  final List<app_user.User> _users = [];
  final List<Run> _runs = [];
  final List<Area> _areas = [];
  
  // Stream controllers
  final StreamController<List<Run>> _runsController = StreamController<List<Run>>.broadcast();
  final StreamController<List<Area>> _areasController = StreamController<List<Area>>.broadcast();
  final StreamController<List<app_user.User>> _leaderboardController = StreamController<List<app_user.User>>.broadcast();

  // Kullanıcı işlemleri
  Future<app_user.User?> getCurrentUser() async {
    if (_users.isEmpty) return null;
    return _users.first;
  }

  Future<void> createUser(app_user.User user) async {
    _users.add(user);
  }

  Future<void> updateUser(app_user.User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  // Koşu işlemleri
  Future<void> saveRun(Run run) async {
    _runs.add(run);
    _runsController.add(_runs);
  }

  Stream<List<Run>> getUserRuns(String userId) {
    final userRuns = _runs.where((run) => run.userId == userId).toList();
    return Stream.value(userRuns);
  }

  Stream<List<Run>> getAllRuns() {
    return _runsController.stream.map((_) => _runs);
  }

  // Alan işlemleri
  Future<void> saveArea(Area area) async {
    _areas.add(area);
    _areasController.add(_areas);
  }

  Future<void> updateArea(Area area) async {
    final index = _areas.indexWhere((a) => a.id == area.id);
    if (index != -1) {
      _areas[index] = area;
      _areasController.add(_areas);
    }
  }

  Stream<List<Area>> getAllAreas() {
    return _areasController.stream.map((_) => _areas);
  }

  Stream<List<Area>> getUserAreas(String userId) {
    final userAreas = _areas.where((area) => area.currentOwnerId == userId).toList();
    return Stream.value(userAreas);
  }

  // Liderlik tablosu
  Stream<List<app_user.User>> getLeaderboard() {
    final sortedUsers = List<app_user.User>.from(_users)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return _leaderboardController.stream.map((_) => sortedUsers);
  }

  // Alan çakışması kontrolü
  Future<Area?> findOverlappingArea(List<dynamic> coordinates) async {
    // Basit çakışma kontrolü
    for (final area in _areas) {
      bool hasOverlap = false;
      for (var coord in coordinates) {
        for (var areaCoord in area.coordinates) {
          final distance = _calculateDistance(
            coord['latitude'], coord['longitude'],
            areaCoord.latitude, areaCoord.longitude,
          );
          if (distance < 50) { // 50 metre içinde
            hasOverlap = true;
            break;
          }
        }
        if (hasOverlap) break;
      }
      
      if (hasOverlap) return area;
    }
    
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Basit mesafe hesaplama
    const double earthRadius = 6371000; // metre
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        (math.sin(lat1) * math.sin(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // İstatistikler
  Future<Map<String, dynamic>> getDailyStats() async {
    return {
      'totalRuns': _runs.length,
      'totalDistance': _runs.fold(0.0, (sum, run) => sum + run.distance),
      'totalAreas': _areas.length,
    };
  }

  // Mock veri ekleme (test için)
  void addMockData() {
    // Mock kullanıcı
    final mockUser = app_user.User(
      id: 'user1',
      username: 'TestKoşucu',
      email: 'test@example.com',
      level: 5,
      totalPoints: 1250,
      totalAreas: 8,
      totalDistance: 15000,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      badges: ['İlk Koşu', '5 km', 'Alan Fatihi'],
    );
    _users.add(mockUser);

    // Mock alanlar
    final mockArea1 = Area(
      id: 'area1',
      name: 'Park Alanı',
      coordinates: [
        const LatLng(41.0082, 28.9784),
        const LatLng(41.0085, 28.9787),
        const LatLng(41.0088, 28.9784),
        const LatLng(41.0082, 28.9784),
      ],
      area: 2500,
      currentOwnerId: 'user1',
      currentOwnerName: 'TestKoşucu',
      capturedAt: DateTime.now().subtract(const Duration(days: 2)),
      captureCount: 1,
      previousOwners: [],
      points: 25,
    );
    _areas.add(mockArea1);

    // Stream'leri güncelle
    _runsController.add(_runs);
    _areasController.add(_areas);
    _leaderboardController.add(_users);
  }

  void dispose() {
    _runsController.close();
    _areasController.close();
    _leaderboardController.close();
  }
} 