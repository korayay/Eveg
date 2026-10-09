import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../models/area.dart';
import '../models/lat_lng.dart' as app_models;
import '../providers/auth_provider.dart';

class FlutterMapWidget extends StatefulWidget {
  final List<Area> areas;
  final List<app_models.LatLng>? currentRoute;
  final Function(Area)? onAreaTap;
  final bool autoFocusLocation; // Konum otomatik focus

  const FlutterMapWidget({
    super.key,
    required this.areas,
    this.currentRoute,
    this.onAreaTap,
    this.autoFocusLocation = false,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  Timer? _locationTimer;
  bool _locationPermissionGranted = false;

  // İstanbul merkezinden başla
  static const LatLng _defaultLocation = LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    print('🗺️ FlutterMap widget başlatıldı');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionSafe();
      
      // Auto focus modunda konum takibini başlat
      if (widget.autoFocusLocation) {
        _startLocationTracking();
      }
    });
  }
  
  void _startLocationTracking() {
    print('📍 Koşu modu: Konum takibi başlatılıyor...');
    // Her 3 saniyede bir konum güncelle ve haritayı odakla
    _locationTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && widget.autoFocusLocation) {
        _getCurrentLocationAndFocus();
      } else {
        timer.cancel();
      }
    });
  }
  
  void _getCurrentLocationAndFocus() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      
      print('📍 Konum güncellendi: ${position.latitude}, ${position.longitude}');
      
      // Widget build olduktan sonra haritayı hareket ettir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController.mapEventStream != null) {
          try {
            _mapController.move(
              LatLng(position.latitude, position.longitude), 
              17.0  // Yakın zoom seviyesi
            );
            print('🎯 Harita konuma odaklandı');
          } catch (e) {
            print('⚠️ Harita odaklama hatası: $e');
          }
        }
      });
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Konum güncellenirken hata: $e');
    }
  }

  Future<void> _requestLocationPermissionSafe() async {
    try {
      print('📍 Konum izni kontrol ediliyor...');
      
      final status = await Permission.location.status;
      print('📍 Mevcut konum izni durumu: $status');
      
      if (status.isDenied) {
        final newStatus = await Permission.location.request();
        print('📍 Yeni konum izni durumu: $newStatus');
        
        if (newStatus.isGranted) {
          setState(() {
            _locationPermissionGranted = true;
          });
          await _getCurrentLocationSafe();
        }
      } else if (status.isGranted) {
        setState(() {
          _locationPermissionGranted = true;
        });
        await _getCurrentLocationSafe();
      }
    } catch (e) {
      print('❌ Konum izni hatası: $e');
    }
  }

  Future<void> _getCurrentLocationSafe() async {
    try {
      if (!_locationPermissionGranted) {
        print('📍 Konum izni yok, varsayılan konum kullanılıyor');
        return;
      }
      
      print('📍 Konum alınıyor...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      
      print('📍 Konum alındı: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Haritayı konuma odakla
        _mapController.move(
          LatLng(position.latitude, position.longitude), 
          15.0
        );
        print('📍 Harita konuma odaklandı');
      }
    } catch (e) {
      print('❌ Konum alma hatası: $e');
    }
  }

  List<Polygon> _buildPolygons(String currentUserId) {
    final polygons = <Polygon>[];
    
    for (final area in widget.areas) {
      if (area.coordinates.isNotEmpty) {
        final points = area.coordinates.map((coord) => 
          LatLng(coord.latitude, coord.longitude)
        ).toList();
        
        final isMyArea = area.currentOwnerId == currentUserId;
        
        polygons.add(Polygon(
          points: points,
          color: isMyArea 
            ? AppColors.myArea.withOpacity(0.3)
            : AppColors.otherArea.withOpacity(0.3),
          borderColor: isMyArea 
            ? AppColors.myArea
            : AppColors.otherArea,
          borderStrokeWidth: 2,
        ));
      }
    }
    
    return polygons;
  }

  List<Polyline> _buildPolylines(String currentUserId) {
    final polylines = <Polyline>[];
    
    if (widget.currentRoute != null && widget.currentRoute!.isNotEmpty) {
      final points = widget.currentRoute!.map((coord) => 
        LatLng(coord.latitude, coord.longitude)
      ).toList();
      
      // Ana rota polyline'ı
      polylines.add(Polyline(
        points: points,
        color: AppColors.primary,
        strokeWidth: 5.0,
        pattern: StrokePattern.dotted(),
      ));
      
      // Smooth segments
      if (points.length >= 2) {
        for (int i = 0; i < points.length - 1; i++) {
          polylines.add(Polyline(
            points: [points[i], points[i + 1]],
            color: AppColors.secondary.withOpacity(0.7),
            strokeWidth: 3.0,
          ));
        }
      }
    }
    
    return polylines;
  }

  List<Marker> _buildMarkers(String currentUserId) {
    final markers = <Marker>[];
    
    // Mevcut konum marker'ı
    if (_currentPosition != null) {
      markers.add(Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
        width: 40,
        height: 40,
      ));
    }
    
    // Alan merkezi marker'ları
    for (final area in widget.areas) {
      if (area.coordinates.isNotEmpty) {
        final center = _calculateCenter(area.coordinates);
        final isMyArea = area.currentOwnerId == currentUserId;
        
        markers.add(Marker(
          point: LatLng(center.latitude, center.longitude),
          child: GestureDetector(
            onTap: () => widget.onAreaTap?.call(area),
            child: Container(
              decoration: BoxDecoration(
                color: isMyArea ? AppColors.myArea : AppColors.otherArea,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isMyArea ? Icons.check : Icons.flag,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          width: 30,
          height: 30,
        ));
      }
    }
    
    return markers;
  }

  app_models.LatLng _calculateCenter(List<app_models.LatLng> coordinates) {
    double lat = 0, lng = 0;
    for (final coord in coordinates) {
      lat += coord.latitude;
      lng += coord.longitude;
    }
    return app_models.LatLng(lat / coordinates.length, lng / coordinates.length);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? 'vJGf4meB3HhbNJo3aFvaH5If2ur1';
        
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultLocation,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) {
                  print('🗺️ Harita tıklandı: ${point.latitude}, ${point.longitude}');
                },
              ),
              children: [
                // Google Maps satellite (ücretsiz tile servisi)
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.eveg_new',
                  maxZoom: 20,
                  additionalOptions: {
                    'attribution': '© Google Maps',
                  },
                ),
                // Google Maps yol isimleri overlay
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=h&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.example.eveg_new',
                  maxZoom: 20,
                  additionalOptions: {
                    'attribution': '© Google Maps',
                  },
                ),
                // Polygon layer
                PolygonLayer(
                  polygons: _buildPolygons(currentUserId),
                ),
                // Polyline layer
                PolylineLayer(
                  polylines: _buildPolylines(currentUserId),
                ),
                // Marker layer
                MarkerLayer(
                  markers: _buildMarkers(currentUserId),
                ),
              ],
            ),
            
            // Konum butonu
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: "location",
                mini: true,
                backgroundColor: AppColors.primary,
                onPressed: () async {
                  if (_currentPosition != null) {
                    _mapController.move(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                      16.0
                    );
                  } else {
                    await _getCurrentLocationSafe();
                  }
                },
                child: Icon(
                  _currentPosition != null ? Icons.my_location : Icons.location_searching,
                  color: Colors.white,
                ),
              ),
            ),
        
        // Harita tipi değiştirme butonu
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBackground.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapTypeButton('Uydu', Icons.satellite),
                _buildMapTypeButton('Yol', Icons.map),
                _buildMapTypeButton('Hibrit', Icons.layers),
              ],
            ),
          ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildMapTypeButton(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Harita tipi değiştirme fonksiyonu eklenebilir
        print('🗺️ Harita tipi değiştirildi: $label');
      },
      child: Container(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
