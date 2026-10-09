import 'lat_lng.dart';

class Area {
  final String id;
  final String name;
  final List<LatLng> coordinates;
  final double area; // metrekare cinsinden
  final String currentOwnerId;
  final String currentOwnerName;
  final DateTime capturedAt;
  final int captureCount;
  final List<String> previousOwners;
  final int points;

  Area({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.area,
    required this.currentOwnerId,
    required this.currentOwnerName,
    required this.capturedAt,
    this.captureCount = 1,
    this.previousOwners = const [],
    this.points = 0,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      name: json['name'],
      coordinates: (json['coordinates'] as List)
          .map((point) {
            // Firebase geopoint formatını kontrol et
            if (point is Map<String, dynamic>) {
              return LatLng(point['latitude'], point['longitude']);
            } else if (point.runtimeType.toString().contains('GeoPoint')) {
              // Firebase GeoPoint objesi
              final geoPoint = point as dynamic;
              return LatLng(geoPoint.latitude, geoPoint.longitude);
            } else {
              // Fallback - direct values
              return LatLng(point['latitude'] ?? 0.0, point['longitude'] ?? 0.0);
            }
          })
          .toList(),
      area: (json['area'] ?? 0).toDouble(),
      currentOwnerId: json['currentOwnerId'] ?? '',
      currentOwnerName: json['currentOwnerName'] ?? '',
      capturedAt: json['capturedAt'] is String 
          ? DateTime.parse(json['capturedAt'])
          : (json['capturedAt']?.toDate() ?? DateTime.now()), // Firestore Timestamp
      captureCount: json['captureCount'] ?? 1,
      previousOwners: List<String>.from(json['previousOwners'] ?? []),
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'area': area,
      'currentOwnerId': currentOwnerId,
      'currentOwnerName': currentOwnerName,
      'capturedAt': capturedAt.toIso8601String(),
      'captureCount': captureCount,
      'previousOwners': previousOwners,
      'points': points,
    };
  }

  String get formattedArea {
    if (area < 10000) {
      return '${area.toStringAsFixed(0)} m²';
    } else {
      return '${(area / 10000).toStringAsFixed(2)} ha';
    }
  }

  String get timeSinceCapture {
    final now = DateTime.now();
    final difference = now.difference(capturedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  Area copyWith({
    String? id,
    String? name,
    List<LatLng>? coordinates,
    double? area,
    String? currentOwnerId,
    String? currentOwnerName,
    DateTime? capturedAt,
    int? captureCount,
    List<String>? previousOwners,
    int? points,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      area: area ?? this.area,
      currentOwnerId: currentOwnerId ?? this.currentOwnerId,
      currentOwnerName: currentOwnerName ?? this.currentOwnerName,
      capturedAt: capturedAt ?? this.capturedAt,
      captureCount: captureCount ?? this.captureCount,
      previousOwners: previousOwners ?? this.previousOwners,
      points: points ?? this.points,
    );
  }
} 