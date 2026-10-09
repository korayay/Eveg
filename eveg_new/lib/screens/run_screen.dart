import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';
import '../widgets/run_stats_card.dart';
import '../widgets/run_control_buttons.dart';
import '../models/run.dart';
import '../models/area.dart';
import '../models/lat_lng.dart';
import '../widgets/flutter_map_widget.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Consumer<RunProvider>(
          builder: (context, runProvider, child) {
            return Stack(
              children: [
                // Harita
                _buildMap(runProvider),
                
                // Üst bilgi paneli
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopPanel(runProvider),
                ),
                
                // Alt kontrol paneli
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomPanel(runProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(RunProvider runProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Mock alanları al (map_screen ile aynı)
          final mockAreas = _getMockAreas();
          
          return FlutterMapWidget(
            areas: mockAreas,
            currentRoute: runProvider.currentRoute,
          );
        },
      ),
    );
  }
  
  List<Area> _getMockAreas() {
    // Map screen ile aynı mock data
    return [
      // SENİN ALANLARIN
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
        currentOwnerId: 'vJGf4meB3HhbNJo3aFvaH5If2ur1',
        currentOwnerName: 'TestKoşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 2)),
        captureCount: 3,
        points: 150,
      ),
      // DİĞER KULLANICININ ALANLARI
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
        currentOwnerId: '4Tuh3pHiIdax3QLPC6958koa6m43',
        currentOwnerName: 'RivalKoşucu',
        capturedAt: DateTime.now().subtract(Duration(hours: 3)),
        captureCount: 8,
        points: 450,
      ),
    ];
  }

  Widget _buildTopPanel(RunProvider runProvider) {
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
      child: Column(
        children: [
          // Durum göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: runProvider.isRunning 
                      ? (runProvider.isPaused ? AppColors.secondary : AppColors.success)
                      : AppColors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                runProvider.isRunning 
                    ? (runProvider.isPaused ? 'DURAKLATILDI' : 'KOŞUYOR')
                    : 'HAZIR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: runProvider.isRunning 
                      ? (runProvider.isPaused ? AppColors.secondary : AppColors.success)
                      : AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // İstatistikler
          Row(
            children: [
              Expanded(
                child: RunStatsCard(
                  title: 'Süre',
                  value: runProvider.formattedElapsedTime,
                  icon: Icons.timer,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RunStatsCard(
                  title: 'Mesafe',
                  value: runProvider.formattedDistance,
                  icon: Icons.straighten,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RunStatsCard(
                  title: 'Hız',
                  value: runProvider.formattedSpeed,
                  icon: Icons.speed,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(RunProvider runProvider) {
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
            onStart: () => _startRun(runProvider),
            onPause: () => runProvider.pauseRun(),
            onResume: () => runProvider.resumeRun(),
            onStop: () => _stopRun(runProvider),
          ),
        ],
      ),
    );
  }

  Future<void> _startRun(RunProvider runProvider) async {
    try {
      await runProvider.startRun();
      _updateMapPolyline();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koşu başlatılamadı: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopRun(RunProvider runProvider) async {
    final run = await runProvider.stopRun();
    if (run != null) {
      _showRunSummary(run);
    }
  }

  void _updateMapPolyline() {
    // Harita üzerinde rota çizimi güncellenir
    setState(() {
      // Polyline güncelleme işlemleri
    });
  }

  void _showRunSummary(Run run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRunSummarySheet(run),
    );
  }

  Widget _buildRunSummarySheet(Run run) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
            const Text(
              'Koşu Tamamlandı! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // İstatistikler
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Mesafe',
                    run.formattedDistance,
                    Icons.straighten,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Süre',
                    run.formattedDuration,
                    Icons.timer,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Hız',
                    run.formattedSpeed,
                    Icons.speed,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Alan',
                    run.formattedArea,
                    Icons.map,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Kaydet butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveRun(run),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Koşuyu Kaydet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // İptal butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'İptal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRun(Run run) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final updatedRun = Run(
          id: run.id,
          userId: authProvider.currentUser!.id,
          username: authProvider.currentUser!.username,
          route: run.route,
          distance: run.distance,
          duration: run.duration,
          averageSpeed: run.averageSpeed,
          area: run.area,
          startTime: run.startTime,
          endTime: run.endTime,
        );
        
        // Koşuyu kaydet
        await Provider.of<RunProvider>(context, listen: false).saveRun(updatedRun);
        
        // Alan oluştur ve çakışma kontrolü yap
        final area = await Provider.of<RunProvider>(context, listen: false)
            .createAreaFromRun(updatedRun, authProvider.currentUser!.id, authProvider.currentUser!.username);
        
        Navigator.pop(context);
        
        if (area != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Koşu kaydedildi ve ${area.name} alanı oluşturuldu!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koşu kaydedildi fakat alan oluşturulamadı (çok küçük veya geçersiz)'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koşu kaydedilemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
} 