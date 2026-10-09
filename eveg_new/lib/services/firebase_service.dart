import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../models/run.dart';
import '../models/area.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore? get _firestoreInstance {
    try {
      _firestore ??= FirebaseFirestore.instance;
      return _firestore;
    } catch (e) {
      print('Firestore başlatılamadı: $e');
      return null;
    }
  }

  FirebaseAuth? get _authInstance {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth;
    } catch (e) {
      print('Firebase Auth başlatılamadı: $e');
      return null;
    }
  }

  // Kullanıcı işlemleri
  Future<app_user.User?> getCurrentUser() async {
    try {
      if (_authInstance == null || _firestoreInstance == null) {
        return null;
      }

      final user = _authInstance!.currentUser;
      if (user == null) return null;

      final doc = await _firestoreInstance!.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return app_user.User.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Kullanıcı bilgisi alınamadı: $e');
      return null;
    }
  }

  Future<void> createUser(app_user.User user) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, kullanıcı oluşturulamadı');
        return;
      }
      await _firestoreInstance!.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      print('Kullanıcı oluşturulamadı: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  Future<void> updateUser(app_user.User user) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, kullanıcı güncellenemedi');
        return;
      }
      await _firestoreInstance!.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Kullanıcı güncellenemedi: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  // Koşu işlemleri
  Future<void> saveRun(Run run) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, koşu kaydedilemedi');
        return;
      }
      await _firestoreInstance!.collection('runs').add(run.toJson());
    } catch (e) {
      print('Koşu kaydedilemedi: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  Stream<List<Run>> getUserRuns(String userId) {
    // Index sorunu nedeniyle geçici olarak devre dışı
    print('⚠️ Runs sorgusu index hatası nedeniyle devre dışı');
    return Stream.value([]);
    
    /* Index oluşturulduktan sonra bu kodu kullan:
    if (_firestoreInstance == null) {
      print('Firestore başlatılmamış, boş liste döndürülüyor');
      return Stream.value([]);
    }
    
    return _firestoreInstance!
        .collection('runs')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Run.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
    */
  }

  Stream<List<Run>> getAllRuns() {
    // Index sorunu nedeniyle geçici olarak devre dışı
    print('⚠️ All runs sorgusu index hatası nedeniyle devre dışı');
    return Stream.value([]);
    
    /* Index oluşturulduktan sonra bu kodu kullan:
    if (_firestoreInstance == null) {
      print('Firestore başlatılmamış, boş liste döndürülüyor');
      return Stream.value([]);
    }
    
    return _firestoreInstance!
        .collection('runs')
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Run.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
    */
  }

  // Alan işlemleri
  Future<void> saveArea(Area area) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, alan kaydedilemedi');
        return;
      }
      await _firestoreInstance!.collection('areas').doc(area.id).set(area.toJson());
    } catch (e) {
      print('Alan kaydedilemedi: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  Future<void> updateArea(Area area) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, alan güncellenemedi');
        return;
      }
      await _firestoreInstance!.collection('areas').doc(area.id).update(area.toJson());
    } catch (e) {
      print('Alan güncellenemedi: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  Stream<List<Area>> getAllAreas() {
    if (_firestoreInstance == null) {
      print('Firestore başlatılmamış, boş liste döndürülüyor');
      return Stream.value([]);
    }
    
    return _firestoreInstance!
        .collection('areas')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Area.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<Area>> getUserAreas(String userId) {
    if (_firestoreInstance == null) {
      print('Firestore başlatılmamış, boş liste döndürülüyor');
      return Stream.value([]);
    }
    
    return _firestoreInstance!
        .collection('areas')
        .where('currentOwnerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Area.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Liderlik tablosu
  Stream<List<app_user.User>> getLeaderboard() {
    if (_firestoreInstance == null) {
      print('Firestore başlatılmamış, boş liste döndürülüyor');
      return Stream.value([]);
    }
    
    return _firestoreInstance!
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .orderBy('totalAreas', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_user.User.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Alan çakışması kontrolü
  Future<Area?> findOverlappingArea(List<dynamic> coordinates) async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, alan çakışması kontrol edilemedi');
        return null;
      }
      
      // Basit çakışma kontrolü - gerçek uygulamada daha gelişmiş algoritma kullanılmalı
      final areas = await _firestoreInstance!.collection('areas').get();
      
      for (var doc in areas.docs) {
        final area = Area.fromJson({...doc.data(), 'id': doc.id});
        
        // Basit mesafe kontrolü - gerçek uygulamada polygon intersection kontrolü yapılmalı
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
    } catch (e) {
      print('Alan çakışması kontrol edilemedi: $e');
      return null;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formülü ile mesafe hesaplama
    const double earthRadius = 6371000; // metre
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // İstatistikler
  Future<Map<String, dynamic>> getDailyStats() async {
    try {
      if (_firestoreInstance == null) {
        print('Firestore başlatılmamış, günlük istatistikler alınamadı');
        return {
          'totalRuns': 0,
          'totalDistance': 0.0,
          'totalAreas': 0,
        };
      }
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final runsQuery = await _firestoreInstance!
          .collection('runs')
          .where('startTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();
      
      final totalRuns = runsQuery.docs.length;
      double totalDistance = 0;
      int totalAreas = 0;
      
      for (var doc in runsQuery.docs) {
        final run = Run.fromJson({...doc.data(), 'id': doc.id});
        totalDistance += run.distance;
        totalAreas += 1; // Her koşu bir alan oluşturur
      }
      
      return {
        'totalRuns': totalRuns,
        'totalDistance': totalDistance,
        'totalAreas': totalAreas,
      };
    } catch (e) {
      print('Günlük istatistikler alınamadı: $e');
      return {
        'totalRuns': 0,
        'totalDistance': 0.0,
        'totalAreas': 0,
      };
    }
  }
} 