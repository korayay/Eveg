import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/area.dart';
import '../models/lat_lng.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/run_provider.dart';
import '../widgets/flutter_map_widget.dart';
import '../widgets/run_control_buttons.dart';
import '../widgets/run_stats_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Area> _areas = [];
  Area? _selectedArea;
  bool _isRunMode = false; // Koşu modu toggle

  @override
  void initState() {
    super.initState();
    // Firebase + Mock karışık data
    _loadAreas(); // Firestore'dan yükle
    // _loadMockAreasWithRealIds(); // Mock data devre dışı
  }

  void _loadAreas() {
    try {
      print('🔥 Firebase\'den area verileri yükleniyor...');
      FirebaseService().getAllAreas().listen((areas) {
        if (mounted) {
          print('🔥 Firebase\'den ${areas.length} alan yüklendi');
          
          // Her alanın sahiplik bilgisini logla
          for (final area in areas) {
            print('📍 Alan: ${area.name}');
            print('   Sahip ID: ${area.currentOwnerId}');
            print('   Sahip Adı: ${area.currentOwnerName}');
            print('   Koordinat sayısı: ${area.coordinates.length}');
            print('   ---');
          }
          
          setState(() {
            _areas = areas;
            _updateMapOverlays();
          });
        }
      });
    } catch (e) {
      print('❌ Firebase area yükleme hatası: $e');
      // Fallback: Mock data kullan
      print('🔄 Mock area data kullanılacak');
      // Mock data zaten initState'de yüklendi, ek bir şey yapmaya gerek yok
    }
  }
  
  void _loadMockAreasWithRealIds() {
    // Gerçek kullanıcı ID'leri ile mock alanlar
    final mockAreas = [
      // SENİN ALANLARIN (vJGf4meB3HhbNJo3aFvaH5If2ur1)
      Area(
        id: 'area1',
        name: 'Merkez Park',
        coordinates: [
          LatLng(41.0082, 28.974),
          LatLng(41.0085, 28.979),
          LatLng(41.0088, 28.976),
          LatLng(41.0085, 28.972),
        ],
        area: 5000,
        currentOwnerId: 'vJGf4meB3HhbNJo3aFvaH5If2ur1', // Sen
        currentOwnerName: 'TestKoşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 2)),
        captureCount: 3,
        points: 150,
      ),
      Area(
        id: 'area2',
        name: 'Spor Kompleksi',
        coordinates: [
          LatLng(41.0102, 28.9805),
          LatLng(41.0105, 28.9810),
          LatLng(41.0108, 28.9808),
          LatLng(41.0106, 28.9803),
        ],
        area: 12000.0,
        currentOwnerId: 'vJGf4meB3HhbNJo3aFvaH5If2ur1', // Sen
        currentOwnerName: 'TestKoşucu',
        capturedAt: DateTime.now().subtract(Duration(minutes: 30)),
        captureCount: 5,
        points: 300,
      ),
      
      // DİĞER KULLANICININ ALANLARI (4Tuh3pHiIdax3QLPC6958koa6m43)
      Area(
        id: 'area3',
        name: 'Gülhane Parkı',
        coordinates: [
          LatLng(41.0115, 28.9815),
          LatLng(41.0120, 28.9825),
          LatLng(41.0125, 28.9820),
          LatLng(41.0118, 28.9810),
        ],
        area: 15000.0,
        currentOwnerId: '4Tuh3pHiIdax3QLPC6958koa6m43', // Diğer kullanıcı
        currentOwnerName: 'RivalKoşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 3)),
        captureCount: 8,
        points: 450,
      ),
      Area(
        id: 'area4',
        name: 'Beşiktaş Sahili',
        coordinates: [
          LatLng(41.0430, 29.0080),
          LatLng(41.0435, 29.0090),
          LatLng(41.0440, 29.0085),
          LatLng(41.0438, 29.0075),
        ],
        area: 8500.0,
        currentOwnerId: '4Tuh3pHiIdax3QLPC6958koa6m43', // Diğer kullanıcı
        currentOwnerName: 'RivalKoşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 1)),
        captureCount: 3,
        points: 250,
      ),
      Area(
        id: 'area5',
        name: 'Kadıköy Meydanı',
        coordinates: [
          LatLng(40.9900, 29.0250),
          LatLng(40.9905, 29.0260),
          LatLng(40.9910, 29.0255),
          LatLng(40.9908, 29.0245),
        ],
        area: 6200.0,
        currentOwnerId: '4Tuh3pHiIdax3QLPC6958koa6m43', // Diğer kullanıcı
        currentOwnerName: 'RivalKoşucu',
        capturedAt: DateTime.now().subtract(Duration(days: 2)),
        captureCount: 12,
        points: 380,
      ),
    ];
    
    if (mounted) {
      setState(() {
        _areas = mockAreas;
        _updateMapOverlays();
      });
      print('🎮 Mock alanlar yüklendi: ${mockAreas.length} alan');
      print('💚 Senin alanların: ${mockAreas.where((a) => a.currentOwnerId == "vJGf4meB3HhbNJo3aFvaH5If2ur1").length}');
      print('❤️ Diğerinin alanları: ${mockAreas.where((a) => a.currentOwnerId == "4Tuh3pHiIdax3QLPC6958koa6m43").length}');
    }
  }

  void _loadMockAreas() {
    // Firebase'deki gerçek verilerinize uygun mock data
    final mockAreas = [
      Area(
        id: 'area1',
        name: 'Merkez Park', // Firebase'deki gerçek alan adı
        coordinates: [
          LatLng(41.0082, 28.974), // Firebase'deki gerçek geopoint koordinatları
          LatLng(41.0085, 28.979),
          LatLng(41.0088, 28.976),
          LatLng(41.0085, 28.972),
        ],
        area: 5000, // Firebase'deki gerçek alan değeri
        currentOwnerId: 'test_user_uid', // Firebase'deki gerçek UID
        currentOwnerName: 'TestKoşucu', // Firebase'deki gerçek kullanıcı adı
        capturedAt: DateTime.now().subtract(Duration(hours: 2)),
        captureCount: 3, // Firebase'deki gerçek değer
        points: 150, // Firebase'deki gerçek değer
      ),
      Area(
        id: 'area2', 
        name: 'Sahil Yolu',
        coordinates: [
          LatLng(41.0092, 28.9795),
          LatLng(41.0095, 28.9800),
          LatLng(41.0098, 28.9798),
          LatLng(41.0096, 28.9793),
        ],
        area: 8000.0,
        currentOwnerId: 'other_user',
        currentOwnerName: 'Ahmet',
        capturedAt: DateTime.now().subtract(Duration(days: 1)),
        captureCount: 1,
        points: 200,
      ),
      Area(
        id: 'area3',
        name: 'Spor Kompleksi',
        coordinates: [
          LatLng(41.0102, 28.9805),
          LatLng(41.0105, 28.9810),
          LatLng(41.0108, 28.9808),
          LatLng(41.0106, 28.9803),
        ],
        area: 12000.0,
        currentOwnerId: 'test_user_id',
        currentOwnerName: 'Sen',
        capturedAt: DateTime.now().subtract(Duration(minutes: 30)),
        captureCount: 5,
        points: 300,
      ),
      // Başka kullanıcıların alanları
      Area(
        id: 'area4',
        name: 'Gülhane Parkı',
        coordinates: [
          LatLng(41.0115, 28.9815),
          LatLng(41.0120, 28.9825),
          LatLng(41.0125, 28.9820),
          LatLng(41.0118, 28.9810),
        ],
        area: 15000.0,
        currentOwnerId: 'user_fatma',
        currentOwnerName: 'Fatma Koşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 3)),
        captureCount: 8,
        points: 450,
      ),
      Area(
        id: 'area5',
        name: 'Beşiktaş Sahili',
        coordinates: [
          LatLng(41.0430, 29.0080),
          LatLng(41.0435, 29.0090),
          LatLng(41.0440, 29.0085),
          LatLng(41.0438, 29.0075),
        ],
        area: 8500.0,
        currentOwnerId: 'user_mehmet',
        currentOwnerName: 'Mehmet Yılmaz',
        capturedAt: DateTime.now().subtract(Duration(hours: 1)),
        captureCount: 3,
        points: 250,
      ),
      Area(
        id: 'area6',
        name: 'Kadıköy Meydanı',
        coordinates: [
          LatLng(40.9900, 29.0250),
          LatLng(40.9905, 29.0260),
          LatLng(40.9910, 29.0255),
          LatLng(40.9908, 29.0245),
        ],
        area: 6200.0,
        currentOwnerId: 'user_ayse',
        currentOwnerName: 'Ayşe Demir',
        capturedAt: DateTime.now().subtract(Duration(days: 2)),
        captureCount: 12,
        points: 380,
      ),
      Area(
        id: 'area7',
        name: 'Ulus Parkı',
        coordinates: [
          LatLng(41.0050, 28.9700),
          LatLng(41.0055, 28.9710),
          LatLng(41.0060, 28.9705),
          LatLng(41.0058, 28.9695),
        ],
        area: 9800.0,
        currentOwnerId: 'user_ali',
        currentOwnerName: 'Ali Özkan',
        capturedAt: DateTime.now().subtract(Duration(hours: 6)),
        captureCount: 2,
        points: 180,
      ),
      Area(
        id: 'area8',
        name: 'Taksim Meydanı',
        coordinates: [
          LatLng(41.0370, 28.9850),
          LatLng(41.0375, 28.9860),
          LatLng(41.0380, 28.9855),
          LatLng(41.0378, 28.9845),
        ],
        area: 11500.0,
        currentOwnerId: 'user_zehra',
        currentOwnerName: 'Zehra Aktaş',
        capturedAt: DateTime.now().subtract(Duration(minutes: 45)),
        captureCount: 6,
        points: 320,
      ),
      Area(
        id: 'area9',
        name: 'Florya Sahili',
        coordinates: [
          LatLng(40.9700, 28.7900),
          LatLng(40.9705, 28.7910),
          LatLng(40.9710, 28.7905),
          LatLng(40.9708, 28.7895),
        ],
        area: 13200.0,
        currentOwnerId: 'user_hasan',
        currentOwnerName: 'Hasan Kaya',
        capturedAt: DateTime.now().subtract(Duration(hours: 4)),
        captureCount: 4,
        points: 290,
      ),
      Area(
        id: 'area10',
        name: 'Çamlıca Tepesi',
        coordinates: [
          LatLng(41.0200, 29.0600),
          LatLng(41.0205, 29.0610),
          LatLng(41.0210, 29.0605),
          LatLng(41.0208, 29.0595),
        ],
        area: 16800.0,
        currentOwnerId: 'test_user_id',
        currentOwnerName: 'Sen',
        capturedAt: DateTime.now().subtract(Duration(hours: 2)),
        captureCount: 7,
        points: 420,
      ),
    ];
    
    if (mounted) {
      setState(() {
        _areas = mockAreas;
        _updateMapOverlays();
      });
    }
  }

  void _updateMapOverlays() {
    // Basit harita kullandığımız için bu fonksiyon artık gerekli değil
  }

  LatLng _calculatePolygonCenter(List<LatLng> coordinates) {
    double lat = 0, lng = 0;
    for (final coord in coordinates) {
      lat += coord.latitude;
      lng += coord.longitude;
    }
    return LatLng(lat / coordinates.length, lng / coordinates.length);
  }

  void _showAreaDetails(Area area) {
    setState(() {
      _selectedArea = area;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAreaDetailsSheet(area),
    );
  }

  void _showMapInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMapInfoSheet(),
    );
  }

  Widget _buildAreaDetailsSheet(Area area) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? 'vJGf4meB3HhbNJo3aFvaH5If2ur1';
        final isMyArea = area.currentOwnerId == currentUserId;
        
        return Container(
          height: 200,
          decoration: const BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: isMyArea ? AppColors.myArea : AppColors.otherArea,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        area.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMyArea 
                            ? AppColors.myArea.withOpacity(0.2)
                            : AppColors.otherArea.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMyArea ? 'SENİN' : 'BAŞKASININ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMyArea ? AppColors.myArea : AppColors.otherArea,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Detaylar
                _buildDetailRow('Sahip', area.currentOwnerName),
                _buildDetailRow('Alan', area.formattedArea),
                _buildDetailRow('Alınma Tarihi', area.timeSinceCapture),
                _buildDetailRow('Ele Geçirme Sayısı', '${area.captureCount}'),
                _buildDetailRow('Puan', '${area.points}'),
                
                const SizedBox(height: 24),
                
                // Aksiyon butonları
                if (!isMyArea)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.directions_run),
                      label: const Text('Bu Alanı Ele Geçir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapInfoSheet() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Harita Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Legend
            Row(
              children: [
                _buildLegendItem('Senin Alanların', AppColors.myArea),
                const SizedBox(width: 16),
                _buildLegendItem('Başkalarının Alanları', AppColors.otherArea),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Map info
            const Text(
              'Flutter Map + Google Tiles',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Flutter Map (Google Maps tiles ile)
            Consumer<RunProvider>(
              builder: (context, runProvider, child) {
                return FlutterMapWidget(
                  areas: _areas,
                  currentRoute: _isRunMode ? runProvider.currentRoute : null,
                  onAreaTap: _showAreaDetails,
                  autoFocusLocation: _isRunMode, // Koşu modunda otomatik focus
                );
              },
            ),
            
            // Üst panel
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopPanel(),
            ),
            
            // Alt panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _isRunMode ? _buildRunControls() : _buildBottomPanel(),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkGrey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Koşu modu toggle
          Row(
            children: [
              Icon(
                _isRunMode ? Icons.directions_run : Icons.map,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isRunMode ? 'Koşu Modu' : 'Harita Modu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              // Info butonu
              IconButton(
                onPressed: _showMapInfo,
                icon: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              
              // Mode toggle butonu
              IconButton(
                onPressed: () {
                  setState(() {
                    _isRunMode = !_isRunMode;
                  });
                },
                icon: Icon(
                  _isRunMode ? Icons.map : Icons.directions_run,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? 'vJGf4meB3HhbNJo3aFvaH5If2ur1';
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkBackground.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.darkGrey,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Toplam Alan',
                  '${_areas.length}',
                  Icons.map,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Senin Alanların',
                  '${_areas.where((area) => area.currentOwnerId == currentUserId).length}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rekabet Alanları',
                  '${_areas.where((area) => area.currentOwnerId != currentUserId).length}',
                  Icons.warning,
                  AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRunControls() {
    return Consumer<RunProvider>(
      builder: (context, runProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkBackground.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.darkGrey,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alan bilgisi
              if (runProvider.currentArea > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alan: ${runProvider.formattedArea}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Kontrol butonları
              RunControlButtons(
                isRunning: runProvider.isRunning,
                isPaused: runProvider.isPaused,
                onStart: runProvider.startRun,
                onStop: runProvider.stopRun,
                onPause: runProvider.pauseRun,
                onResume: runProvider.resumeRun,
              ),
            ],
          ),
        );
      },
    );
  }
}