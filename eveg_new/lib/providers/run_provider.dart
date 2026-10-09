import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/run.dart';
import '../models/area.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/area_service.dart';

import '../models/lat_lng.dart';

class RunProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  FirebaseService? _firebaseService;
  final AreaService _areaService = AreaService();
  
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _elapsedTime = Duration.zero;
  List<LatLng> _currentRoute = [];
  Timer? _timer;
  
  // Koşu verileri
  double _currentDistance = 0.0;
  double _currentSpeed = 0.0;
  double _currentArea = 0.0;
  
  // Stream'ler
  Stream<List<Run>>? _userRunsStream;
  List<Run> _userRuns = [];

  // Getter'lar
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  DateTime? get startTime => _startTime;
  Duration get elapsedTime => _elapsedTime;
  List<LatLng> get currentRoute => _currentRoute;
  double get currentDistance => _currentDistance;
  double get currentSpeed => _currentSpeed;
  double get currentArea => _currentArea;
  List<Run> get userRuns => _userRuns;

  FirebaseService? get _firebaseServiceInstance {
    try {
      _firebaseService ??= FirebaseService();
      return _firebaseService;
    } catch (e) {
      print('FirebaseService başlatılamadı: $e');
      return null;
    }
  }

  RunProvider() {
    // Location tracking'i sadece gerektiğinde başlat
  }

  void _addLocationPoint(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    
    if (_currentRoute.isNotEmpty) {
      final lastPoint = _currentRoute.last;
      final distance = _locationService.calculateDistance([lastPoint, latLng]);
      _currentDistance += distance;
      
      // Hız hesaplama
      if (_elapsedTime.inSeconds > 0) {
        _currentSpeed = _locationService.calculateAverageSpeed(
          _currentDistance,
          _elapsedTime,
        );
      }
    }
    
    _currentRoute.add(latLng);
    
    // Alan hesaplama (minimum 3 nokta gerekli)
    if (_currentRoute.length >= 3) {
      _currentArea = _locationService.calculateArea(_currentRoute);
    }
    
    notifyListeners();
  }

  Future<void> startRun() async {
    if (_isRunning) return;

    try {
      // Konum izni kontrolü - izin yoksa otomatik iste
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        print('📍 Konum izni yok, otomatik olarak isteniyor...');
        final granted = await _locationService.requestPermissions();
        if (!granted) {
          print('❌ Konum izni reddedildi, mock konum kullanılacak');
          // İzin reddedilse bile koşuya başla (mock data ile)
          _startRunWithoutLocation();
          return;
        } else {
          print('✅ Konum izni verildi');
        }
      }

      _isRunning = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _currentRoute.clear();
      _currentDistance = 0.0;
      _currentSpeed = 0.0;
      _currentArea = 0.0;

      _locationService.startLocationTracking();
      _startTimer();
      
      // Location stream'i dinle
      _locationService.locationStream.listen((Position position) {
        if (_isRunning && !_isPaused) {
          _addLocationPoint(position);
        }
      });
      
      notifyListeners();
    } catch (e) {
      print('Koşu başlatılamadı: $e');
      rethrow;
    }
  }

  void pauseRun() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    _pauseTime = DateTime.now();
    _timer?.cancel();
    
    notifyListeners();
  }

  void resumeRun() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    if (_pauseTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseTime!);
      _startTime = _startTime!.add(pauseDuration);
    }
    _pauseTime = null;
    _startTimer();
    
    notifyListeners();
  }

  Future<Run?> stopRun() async {
    if (!_isRunning) return null;

    try {
      _isRunning = false;
      _isPaused = false;
      _timer?.cancel();
      _locationService.stopLocationTracking();

      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime!);
      
      // Son alan hesaplama
      if (_currentRoute.length >= 3) {
        _currentArea = _areaService.calculateArea(_currentRoute);
      }

      final run = Run(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // AuthProvider'dan alınacak
        username: '', // AuthProvider'dan alınacak
        route: List.from(_currentRoute),
        distance: _currentDistance,
        duration: duration,
        averageSpeed: _currentSpeed,
        area: _currentArea,
        startTime: _startTime!,
        endTime: endTime,
      );

      // Reset state
      _startTime = null;
      _pauseTime = null;
      _elapsedTime = Duration.zero;
      _currentRoute.clear();
      _currentDistance = 0.0;
      _currentSpeed = 0.0;
      _currentArea = 0.0;

      notifyListeners();
      return run;
    } catch (e) {
      print('Koşu durdurulamadı: $e');
      return null;
    }
  }

  // Alan oluşturma ve çakışma kontrolü
  Future<Area?> createAreaFromRun(Run run, String userId, String username) async {
    try {
      if (_firebaseServiceInstance == null) {
        print('FirebaseService başlatılmamış, alan oluşturulamadı');
        return null;
      }

      // Alan geçerlilik kontrolü
      if (!_areaService.isAreaValid(run.route)) {
        print('Alan geçersiz: Çok küçük veya başlangıç-bitiş noktaları uzak');
        return null;
      }

      // Mevcut alanlarda çakışma kontrolü
      final existingAreas = await _firebaseServiceInstance!.getAllAreas().first;
      Area? conflictingArea;
      
      for (final area in existingAreas) {
        if (_areaService.hasSignificantOverlap(area, run.route)) {
          conflictingArea = area;
          break;
        }
      }

      Area? newArea;
      
      if (conflictingArea != null) {
        // Çakışma var - sahipliği güncelle
        newArea = _areaService.updateAreaOwnership(conflictingArea, userId, username);
        await _firebaseServiceInstance!.updateArea(newArea);
        print('Alan sahipliği güncellendi: ${conflictingArea.name}');
      } else {
        // Yeni alan oluştur
        newArea = _areaService.createAreaFromRun(run, userId, username);
        if (newArea != null) {
          await _firebaseServiceInstance!.saveArea(newArea);
          print('Yeni alan oluşturuldu: ${newArea.name}');
        }
      }

      return newArea;
    } catch (e) {
      print('Alan oluşturulamadı: $e');
      return null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && !_isPaused && _startTime != null) {
        _elapsedTime = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });
  }

  Future<void> saveRun(Run run) async {
    try {
      if (_firebaseServiceInstance == null) {
        print('FirebaseService başlatılmamış, koşu kaydedilemedi');
        return;
      }
      await _firebaseServiceInstance!.saveRun(run);
    } catch (e) {
      print('Koşu kaydedilemedi: $e');
      // Hata durumunda rethrow yapma, sadece log
    }
  }

  void loadUserRuns(String userId) {
    if (_firebaseServiceInstance == null) {
      print('FirebaseService başlatılmamış, kullanıcı koşuları yüklenemedi');
      return;
    }
    _userRunsStream = _firebaseServiceInstance!.getUserRuns(userId);
    _userRunsStream?.listen((runs) {
      _userRuns = runs;
      notifyListeners();
    });
  }

  String get formattedElapsedTime {
    final hours = _elapsedTime.inHours;
    final minutes = _elapsedTime.inMinutes % 60;
    final seconds = _elapsedTime.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedDistance {
    if (_currentDistance < 1000) {
      return '${_currentDistance.toStringAsFixed(0)} m';
    } else {
      return '${(_currentDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedSpeed {
    return '${_currentSpeed.toStringAsFixed(1)} km/s';
  }

  String get formattedArea {
    if (_currentArea < 10000) {
      return '${_currentArea.toStringAsFixed(0)} m²';
    } else {
      return '${(_currentArea / 10000).toStringAsFixed(2)} ha';
    }
  }

  // Konum izni olmadan mock konum ile koşu başlat
  void _startRunWithoutLocation() {
    _isRunning = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _elapsedTime = Duration.zero;
    _currentRoute.clear();
    _currentDistance = 0.0;
    _currentSpeed = 0.0;
    
    print('🏃‍♂️ Koşu mock konum ile başlatıldı');
    
    // Mock konum timer'ı başlat (test için)
    _startMockLocationTimer();
    
    notifyListeners();
  }
  
  Timer? _mockLocationTimer;
  int _mockLocationIndex = 0;
  
  void _startMockLocationTimer() {
    // Büyük kare alan oluşturacak önceden belirlenmiş rota
    final List<LatLng> _mockRoute = [
      LatLng(41.0082, 28.9784),      // Başlangıç (merkez)
      LatLng(41.0090, 28.9784),      // Kuzey (80m)
      LatLng(41.0090, 28.9795),      // Kuzeydoğu (80m kuzey, 80m doğu)
      LatLng(41.0082, 28.9795),      // Doğu (80m doğu)
      LatLng(41.0074, 28.9795),      // Güneydoğu (80m güney, 80m doğu)
      LatLng(41.0074, 28.9784),      // Güney (80m güney)
      LatLng(41.0074, 28.9773),      // Güneybatı (80m güney, 80m batı)
      LatLng(41.0082, 28.9773),      // Batı (80m batı)
      LatLng(41.0090, 28.9773),      // Kuzeybatı (80m kuzey, 80m batı)
      LatLng(41.0082, 28.9784),      // Başlangıca dön (kapalı alan)
    ];
    
    _mockLocationIndex = 0;
    
    // Her 3 saniyede bir sonraki mock konum
    _mockLocationTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isRunning || _isPaused) {
        timer.cancel();
        return;
      }
      
      if (_mockLocationIndex < _mockRoute.length) {
        final mockLocation = _mockRoute[_mockLocationIndex];
        _currentRoute.add(mockLocation);
        _mockLocationIndex++;
        
        print('🎯 Mock konum eklendi: ${mockLocation.latitude}, ${mockLocation.longitude} (${_mockLocationIndex}/${_mockRoute.length})');
        
        // Mock mesafe ve hız hesapla
        if (_currentRoute.length > 1) {
          _currentDistance = _locationService.calculateDistance(_currentRoute);
          _currentSpeed = Random().nextDouble() * 5 + 8; // 8-13 km/h arası
        }
        
        notifyListeners();
      } else {
        // Rota tamamlandı, otomatik durdur
        print('🏁 Mock rota tamamlandı, koşu otomatik durduruluyor');
        timer.cancel();
        // 2 saniye sonra otomatik stop
        Future.delayed(Duration(seconds: 2), () {
          if (_isRunning) {
            stopRun();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mockLocationTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }
} 