import 'lat_lng.dart';

class Run {
  final String id;
  final String userId;
  final String username;
  final List<LatLng> route;
  final double distance; // metre cinsinden
  final Duration duration;
  final double averageSpeed; // km/saat
  final double area; // metrekare cinsinden
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;

  Run({
    required this.id,
    required this.userId,
    required this.username,
    required this.route,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.area,
    required this.startTime,
    required this.endTime,
    this.isCompleted = true,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      route: (json['route'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList(),
      distance: json['distance'].toDouble(),
      duration: Duration(seconds: json['durationSeconds']),
      averageSpeed: json['averageSpeed'].toDouble(),
      area: json['area'].toDouble(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isCompleted: json['isCompleted'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'route': route.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'distance': distance,
      'durationSeconds': duration.inSeconds,
      'averageSpeed': averageSpeed,
      'area': area,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/s';
  }

  String get formattedArea {
    if (area < 10000) {
      return '${area.toStringAsFixed(0)} m²';
    } else {
      return '${(area / 10000).toStringAsFixed(2)} ha';
    }
  }
} 