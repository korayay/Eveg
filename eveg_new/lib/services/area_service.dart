import 'dart:math';
import '../models/area.dart';
import '../models/run.dart';
import '../models/lat_lng.dart';

// Koşucu performans seviyeleri
enum RunnerPerformance {
  walking('Yürüyüş', '< 6 km/h'),
  beginner('Başlangıç', '6-9 km/h'), 
  intermediate('Orta', '9-12 km/h'),
  advanced('İleri', '12-15 km/h'),
  elite('Elit', '> 15 km/h');

  const RunnerPerformance(this.displayName, this.speedRange);
  final String displayName;
  final String speedRange;
}

// Alan validasyon sonucu
class AreaValidationResult {
  final bool isValid;
  final String reason;
  final RunnerPerformance performanceLevel;

  const AreaValidationResult({
    required this.isValid,
    required this.reason, 
    required this.performanceLevel,
  });
}

class AreaService {
  static final AreaService _instance = AreaService._internal();
  factory AreaService() => _instance;
  AreaService._internal();
  
  // Dünya yarıçapı (metre)
  static const double earthRadius = 6371000;

  // Bilimsel koşu verilerine dayalı alan validasyon sistemi
  bool isAreaValid(List<LatLng> route, {Duration? runDuration}) {
    if (route.length < 3) {
      print('❌ Alan geçersiz: Minimum 3 nokta gerekli (${route.length} nokta var)');
      return false;
    }
    
    final area = calculateArea(route);
    final distance = calculateTotalDistance(route);
    final validationResult = _validateAreaByPerformance(distance, area, runDuration);
    
    if (!validationResult.isValid) {
      print('❌ Alan geçersiz: ${validationResult.reason}');
      return false;
    }
    
    // Başlangıç-bitiş mesafesi kontrolü (alan kapalı olmalı)
    final startEndDistance = calculateDistance(route.first, route.last);
    final maxClosingDistance = _calculateMaxClosingDistance(distance);
    
    if (startEndDistance > maxClosingDistance) {
      print('❌ Alan geçersiz: Başlangıç-bitiş çok uzak ${startEndDistance.toStringAsFixed(2)} m (max: ${maxClosingDistance.toStringAsFixed(2)} m)');
      return false;
    }
    
    print('✅ Alan geçerli: ${area.toStringAsFixed(2)} m², ${distance.toStringAsFixed(2)} m mesafe, ${route.length} nokta');
    print('📊 Performans seviyesi: ${validationResult.performanceLevel}');
    return true;
  }

  // Performans bazlı alan validasyon
  AreaValidationResult _validateAreaByPerformance(double distance, double area, Duration? runDuration) {
    final performance = _calculatePerformanceLevel(distance, runDuration);
    final minArea = _calculateMinimumArea(distance, performance);
    final maxArea = _calculateMaximumArea(distance, performance);
    
    // Minimum mesafe kontrolü (performansa göre)
    final minDistance = _calculateMinimumDistance(performance);
    if (distance < minDistance) {
      return AreaValidationResult(
        isValid: false,
        reason: 'Çok kısa mesafe ${distance.toStringAsFixed(0)}m (min: ${minDistance.toStringAsFixed(0)}m - ${performance.displayName})',
        performanceLevel: performance,
      );
    }
    
    // Maximum mesafe kontrolü (makul sınırlar)
    final maxDistance = _calculateMaximumDistance(performance);
    if (distance > maxDistance) {
      return AreaValidationResult(
        isValid: false,
        reason: 'Çok uzun mesafe ${distance.toStringAsFixed(0)}m (max: ${maxDistance.toStringAsFixed(0)}m - ${performance.displayName})',
        performanceLevel: performance,
      );
    }
    
    // Minimum alan kontrolü
    if (area < minArea) {
      return AreaValidationResult(
        isValid: false,
        reason: 'Çok küçük alan ${area.toStringAsFixed(0)}m² (min: ${minArea.toStringAsFixed(0)}m² - ${performance.displayName})',
        performanceLevel: performance,
      );
    }
    
    // Maximum alan kontrolü (şüpheli büyük alanları engelle)
    if (area > maxArea) {
      return AreaValidationResult(
        isValid: false,
        reason: 'Çok büyük alan ${(area/10000).toStringAsFixed(2)}ha (max: ${(maxArea/10000).toStringAsFixed(2)}ha - ${performance.displayName})',
        performanceLevel: performance,
      );
    }
    
    return AreaValidationResult(
      isValid: true,
      reason: 'Geçerli alan',
      performanceLevel: performance,
    );
  }

  // Koşu performansı hesaplama
  RunnerPerformance _calculatePerformanceLevel(double distance, Duration? runDuration) {
    if (runDuration == null || runDuration.inSeconds == 0) {
      return RunnerPerformance.beginner; // Süre bilgisi yoksa başlangıç seviyesi
    }
    
    final avgSpeedKmh = (distance / 1000) / (runDuration.inSeconds / 3600);
    
    if (avgSpeedKmh >= 15.0) return RunnerPerformance.elite;
    if (avgSpeedKmh >= 12.0) return RunnerPerformance.advanced;
    if (avgSpeedKmh >= 9.0) return RunnerPerformance.intermediate;
    if (avgSpeedKmh >= 6.0) return RunnerPerformance.beginner;
    return RunnerPerformance.walking;
  }

  // Performansa göre minimum mesafe
  double _calculateMinimumDistance(RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 500; // 500m - elit koşucular daha uzun mesafe
      case RunnerPerformance.advanced:
        return 400; // 400m 
      case RunnerPerformance.intermediate:
        return 300; // 300m
      case RunnerPerformance.beginner:
        return 200; // 200m
      case RunnerPerformance.walking:
        return 150; // 150m - yürüyüş hızı
    }
  }

  // Performansa göre maximum mesafe (makul sınırlar)
  double _calculateMaximumDistance(RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 10000; // 10km
      case RunnerPerformance.advanced:
        return 8000; // 8km
      case RunnerPerformance.intermediate:
        return 6000; // 6km
      case RunnerPerformance.beginner:
        return 4000; // 4km
      case RunnerPerformance.walking:
        return 3000; // 3km
    }
  }

  // Performansa göre minimum alan
  double _calculateMinimumArea(double distance, RunnerPerformance performance) {
    // Alan = (mesafe/π)² * π / 4 formulü ile ideal daire alanının %10'u
    final idealCircleArea = (distance * distance) / (4 * pi);
    final minAreaRatio = _getMinAreaRatio(performance);
    return idealCircleArea * minAreaRatio;
  }

  // Performansa göre maximum alan  
  double _calculateMaximumArea(double distance, RunnerPerformance performance) {
    // İdeal daire alanının 3-5 katı (performansa göre)
    final idealCircleArea = (distance * distance) / (4 * pi);
    final maxAreaRatio = _getMaxAreaRatio(performance);
    return idealCircleArea * maxAreaRatio;
  }

  // Minimum alan oranı (ideal daireye göre)
  double _getMinAreaRatio(RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 0.15; // %15 - elit koşucular daha kompakt
      case RunnerPerformance.advanced:
        return 0.12; // %12
      case RunnerPerformance.intermediate:
        return 0.10; // %10
      case RunnerPerformance.beginner:
        return 0.08; // %8
      case RunnerPerformance.walking:
        return 0.05; // %5 - yavaş hareket, çok geniş alan olabilir
    }
  }

  // Maximum alan oranı (ideal daireye göre)
  double _getMaxAreaRatio(RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 4.0; // 4x - elit koşucular daha kontrollü
      case RunnerPerformance.advanced:
        return 5.0; // 5x
      case RunnerPerformance.intermediate:
        return 6.0; // 6x
      case RunnerPerformance.beginner:
        return 8.0; // 8x - başlangıç seviyesi daha esnek
      case RunnerPerformance.walking:
        return 10.0; // 10x - yürüyüş çok geniş alanlar oluşturabilir
    }
  }

  // Kapanış mesafesi hesaplama (mesafeye göre)
  double _calculateMaxClosingDistance(double totalDistance) {
    // Toplam mesafenin %5'i, minimum 50m, maximum 500m
    final closingDistance = totalDistance * 0.05;
    return closingDistance.clamp(50.0, 500.0);
  }

  // Poligon alanı hesaplama (Shoelace formula)
  double calculateArea(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0.0;
    
    double area = 0.0;
    int j = coordinates.length - 1;
    
    for (int i = 0; i < coordinates.length; i++) {
      area += (coordinates[j].longitude + coordinates[i].longitude) * 
              (coordinates[j].latitude - coordinates[i].latitude);
      j = i;
    }
    
    area = area.abs() / 2.0;
    
    // Yaklaşık metrekare dönüşümü (1 derece ≈ 111000 metre)
    return area * 111000 * 111000;
  }

  // Toplam mesafe hesaplama
  double calculateTotalDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += calculateDistance(route[i], route[i + 1]);
    }
    
    return totalDistance;
  }

  // İki nokta arası mesafe (Haversine formülü)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metre
    
    final dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final dLon = _degreesToRadians(point2.longitude - point1.longitude);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(_degreesToRadians(point1.latitude)) * sin(_degreesToRadians(point2.latitude)) * 
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Poligon overlap kontrolü
  double calculateOverlapPercentage(Area existingArea, List<LatLng> newRoute) {
    // Basit overlap kontrolü - gerçek uygulamada daha gelişmiş algoritma kullanılmalı
    
    // Yeni rotanın alanını hesapla
    final newArea = calculateArea(newRoute);
    if (newArea == 0) return 0.0;
    
    // Ortak noktaları bul
    int overlapPoints = 0;
    for (final newPoint in newRoute) {
      for (final existingPoint in existingArea.coordinates) {
        final distance = calculateDistance(newPoint, existingPoint);
        if (distance < 10) { // 10 metre içinde
          overlapPoints++;
          break;
        }
      }
    }
    
    // Overlap yüzdesi
    final overlapPercentage = (overlapPoints / newRoute.length) * 100;
    
    return overlapPercentage;
  }

  // Alan çakışması kontrolü
  bool hasSignificantOverlap(Area existingArea, List<LatLng> newRoute) {
    final overlapPercentage = calculateOverlapPercentage(existingArea, newRoute);
    
    // %30'dan fazla örtüşme varsa anlamlı çakışma var
    return overlapPercentage > 30;
  }

  // Koşudan alan oluşturma
  Area? createAreaFromRun(Run run, String userId, String username) {
    // Koşu süresini validasyon için kullan
    if (!isAreaValid(run.route, runDuration: run.duration)) return null;
    
    final area = calculateArea(run.route);
    final distance = calculateTotalDistance(run.route);
    final performance = _calculatePerformanceLevel(distance, run.duration);
    final areaName = _generateAreaName(run.route, distance, performance);
    
    return Area(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: areaName,
      coordinates: List.from(run.route),
      area: area,
      currentOwnerId: userId,
      currentOwnerName: username,
      capturedAt: DateTime.now(),
      captureCount: 1,
      previousOwners: [],
      points: _calculateAreaPoints(area, distance, performance),
    );
  }

  // Gelişmiş alan puanı hesaplama (alan + mesafe + performans)
  int _calculateAreaPoints(double area, double distance, RunnerPerformance performance) {
    // Temel puanlar
    final areaPoints = (area / 100).round() * 5; // Her 100m² için 5 puan
    final distancePoints = (distance / 100).round() * 3; // Her 100m için 3 puan
    
    // Performans bonusu
    final performanceMultiplier = _getPerformanceMultiplier(performance);
    final basePoints = areaPoints + distancePoints;
    final totalPoints = (basePoints * performanceMultiplier).round();
    
    // Minimum 10 puan garantisi
    return totalPoints < 10 ? 10 : totalPoints;
  }

  // Performans çarpanı
  double _getPerformanceMultiplier(RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 2.0; // %100 bonus
      case RunnerPerformance.advanced:
        return 1.5; // %50 bonus  
      case RunnerPerformance.intermediate:
        return 1.2; // %20 bonus
      case RunnerPerformance.beginner:
        return 1.0; // Bonus yok
      case RunnerPerformance.walking:
        return 0.8; // %20 ceza
    }
  }

  // Gelişmiş alan adı oluşturma
  String _generateAreaName(List<LatLng> route, double distance, RunnerPerformance performance) {
    final area = calculateArea(route);
    final avgSpeedKmh = _calculateAvgSpeed(distance, performance);
    
    // Performans prefixi
    String performancePrefix = '';
    switch (performance) {
      case RunnerPerformance.elite:
        performancePrefix = '🏃‍♂️ Elit ';
        break;
      case RunnerPerformance.advanced:
        performancePrefix = '🏃 İleri ';
        break;
      case RunnerPerformance.intermediate:
        performancePrefix = '🚶‍♂️ Orta ';
        break;
      case RunnerPerformance.beginner:
        performancePrefix = '🚶 Başlangıç ';
        break;
      case RunnerPerformance.walking:
        performancePrefix = '🚶‍♀️ Yürüyüş ';
        break;
    }
    
    // Alan boyutu kategorisi
    String sizeCategory;
    if (area < 2000) {
      sizeCategory = 'Mini Alan';
    } else if (area < 10000) {
      sizeCategory = 'Küçük Alan';
    } else if (area < 50000) {
      sizeCategory = 'Orta Alan';
    } else if (area < 200000) {
      sizeCategory = 'Büyük Alan';
    } else {
      sizeCategory = 'Dev Alan';
    }
    
    // Mesafe ve hız bilgisi
    final distanceKm = distance / 1000;
    final speedInfo = avgSpeedKmh > 0 ? ' (${avgSpeedKmh.toStringAsFixed(1)} km/h)' : '';
    
    return '$performancePrefix$sizeCategory\n${distanceKm.toStringAsFixed(2)} km$speedInfo';
  }

  // Ortalama hız hesaplama
  double _calculateAvgSpeed(double distance, RunnerPerformance performance) {
    switch (performance) {
      case RunnerPerformance.elite:
        return 16.0;
      case RunnerPerformance.advanced:
        return 13.0;
      case RunnerPerformance.intermediate:
        return 10.0;
      case RunnerPerformance.beginner:
        return 7.5;
      case RunnerPerformance.walking:
        return 5.0;
    }
  }

  // Poligon merkezi hesaplama
  LatLng _calculatePolygonCenter(List<LatLng> coordinates) {
    double lat = 0, lng = 0;
    for (final coord in coordinates) {
      lat += coord.latitude;
      lng += coord.longitude;
    }
    return LatLng(lat / coordinates.length, lng / coordinates.length);
  }

  // Dereceyi radyana çevirme
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Alan güncelleme (sahipliği değiştirme)
  Area updateAreaOwnership(Area area, String newOwnerId, String newOwnerName) {
    final previousOwners = List<String>.from(area.previousOwners);
    previousOwners.add(area.currentOwnerId);
    
    return area.copyWith(
      currentOwnerId: newOwnerId,
      currentOwnerName: newOwnerName,
      capturedAt: DateTime.now(),
      captureCount: area.captureCount + 1,
      previousOwners: previousOwners,
    );
  }
} 