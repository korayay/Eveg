import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/run_provider.dart';
import '../constants/colors.dart';
import '../widgets/stats_card.dart';
import '../widgets/motivation_card.dart';
import '../widgets/recent_activity_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<RunProvider>(context, listen: false)
            .loadUserRuns(authProvider.currentUser!.id);
      }
    });
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('tr_TR', null);
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    } catch (e) {
      // Fallback: İngilizce kullan
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: !_localeInitialized
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (authProvider.currentUser == null) {
              return _buildLoginPrompt();
            }

            return _buildHomeContent(authProvider.currentUser!);
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return const Center(
      child: Text(
        'Giriş yapılıyor...',
        style: TextStyle(
          fontSize: 16,
          color: AppColors.grey,
        ),
      ),
    );
  }

  Widget _buildHomeContent(user) {
    return Consumer<RunProvider>(
      builder: (context, runProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karşılama mesajı
              _buildWelcomeSection(user),
              const SizedBox(height: 32),
              
              // Koşu durumu kartı (eğer koşu varsa)
              if (runProvider.isRunning || runProvider.isPaused)
                _buildActiveRunCard(runProvider),
              if (runProvider.isRunning || runProvider.isPaused)
                const SizedBox(height: 24),
              
              // Koşu başlatma kartı
              _buildStartRunCard(runProvider),
              const SizedBox(height: 24),
              
              // Haftalık takvim
              _buildWeeklyCalendar(),
              const SizedBox(height: 32),
              
              // Günlük koşu kartı
              _buildDailyRunCard(),
              const SizedBox(height: 24),
              
              // Canlı takip kartı
              _buildLiveTrackingCard(),
              const SizedBox(height: 24),
              
              // Haftalık özet kartı
              _buildWeeklySummaryCard(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(user) {
    final now = DateTime.now();
    final greeting = _getGreetingByTime(now.hour);
    final dailyMotivation = _getDailyMotivation(now.weekday);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.username.isNotEmpty ? user.username : 'Koşucu',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
                Container(
          padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
              const SizedBox(width: 8),
                Expanded(
                  child: Text(
                  dailyMotivation,
                  style: TextStyle(
                    fontSize: 14,
                      color: AppColors.white,
                    fontStyle: FontStyle.italic,
                  ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getGreetingByTime(int hour) {
    if (hour < 6) {
      return 'Günaydın Erken Kuş!';
    } else if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi Öğleden Sonra';
    } else if (hour < 22) {
      return 'İyi Akşamlar';
    } else {
      return 'Gece Koşusu mu?';
    }
  }

  String _getDailyMotivation(int weekday) {
    final motivations = [
      'Yeni haftaya enerjik başla! Her adım seni hedefe yakınlaştırıyor.',
      'Salı motivasyonu! Dünün yorgunluğu bugünün gücüne dönüşüyor.',
      'Çarşamba şansı! Haftanın ortasındayız, devam et!',
      'Perşembe enerjisi! Koşu yapmanın tam zamanı.',
      'Cuma koşusu en iyisi! Haftayı güzel bitir.',
      'Hafta sonu özgürlüğü! Koşmak için mükemmel zaman.',
      'Pazar huzuru! Sakin bir koşu ile ruhu dinlendir.',
    ];
    return motivations[weekday - 1];
  }

  String _formatDate(DateTime date, String pattern) {
    if (!_localeInitialized) {
      // Fallback simple format
      return '${date.day}/${date.month}/${date.year}';
    }
    
    try {
      return DateFormat(pattern, 'tr_TR').format(date);
    } catch (e) {
      // Fallback without locale
      return DateFormat(pattern).format(date);
    }
  }

  Widget _buildWeeklyCalendar() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkGrey.withOpacity(0.5),
          width: 1,
        ),
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bu Hafta',
                  style: TextStyle(
                  fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
              ),
              Text(
                _formatDate(now, 'MMMM yyyy'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
                ),
                const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isToday = date.day == now.day && date.month == now.month;
              final hasRun = _hasRunOnDate(date); // Koşu yapılıp yapılmadığı
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                      children: [
                      Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday 
                            ? AppColors.primary 
                            : hasRun 
                              ? AppColors.success.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday 
                              ? AppColors.primary 
                              : hasRun 
                                ? AppColors.success
                                : AppColors.darkGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isToday 
                                ? AppColors.white 
                                : hasRun 
                                  ? AppColors.success
                                  : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasRun)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _hasRunOnDate(DateTime date) {
    // Burada gerçek koşu verilerini kontrol edeceksiniz
    // Şimdilik örnek veri
    final random = date.day % 3;
    return random != 0;
  }

  Widget _buildDailyRunCard() {
    final today = DateTime.now();
    final todayGoal = _getTodayGoal(today.weekday);
    final hasCompletedToday = _hasRunOnDate(today);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(45),
                ),
                child: Center(
                  child: Icon(
                    hasCompletedToday ? Icons.check_circle : Icons.directions_run,
                    size: 45,
                    color: hasCompletedToday ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCompletedToday 
                        ? 'Bugün koşu\ntamamlandı!' 
                        : 'Bugün koşu\nhedefin',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.black.withOpacity(0.8),
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasCompletedToday ? '${todayGoal.toStringAsFixed(1)} km' : '${todayGoal.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: hasCompletedToday ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    if (hasCompletedToday) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tebrikler! 🎉',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    DefaultTabController.of(context)?.animateTo(2);
                  },
                  icon: Icon(
                    hasCompletedToday ? Icons.analytics : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    hasCompletedToday ? 'Detayları Gör' : 'Koşuya Başla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasCompletedToday ? AppColors.success : Color(0xFFFF6B6B),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (!hasCompletedToday) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Hedef değiştirme
                      _showGoalChangeDialog();
                    },
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  double _getTodayGoal(int weekday) {
    // Haftanın gününe göre farklı hedefler (kullanıcının seviyesine göre ayarlanabilir)
    final goals = [5.0, 3.5, 4.0, 6.0, 5.5, 7.0, 4.5]; // Pzt-Paz
    return goals[weekday - 1];
  }

  void _showGoalChangeDialog() {
    // Hedef değiştirme dialog'u
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: Text(
          'Günlük Hedefi Değiştir',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Bugünkü koşu hedefini değiştirmek ister misiniz?',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Iptal', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Değiştir', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingCard() {
    final now = DateTime.now();
    final isActiveSession = false; // Aktif koşu varsa true
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActiveSession ? 'Aktif Koşu' : 'Bugünkü İstatistikler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    isActiveSession 
                      ? 'Canlı takip aktif'
                      : _formatDate(now, 'd MMMM, EEEE'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isActiveSession 
                  ? CustomPaint(painter: WaveformPainter())
                  : Icon(
                      Icons.analytics,
                      color: AppColors.white.withOpacity(0.8),
                      size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_walk,
                  value: '4.2K',
                  label: 'adım',
                  subtitle: '+1.2K bugün',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite,
                  value: '85',
                  label: 'nabz',
                  subtitle: 'ortalama',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  value: '320',
                  label: 'kalori',
                  subtitle: 'yakılan',
                ),
              ),
            ],
          ),
          if (isActiveSession) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Koşu devam ediyor... Süre: 23:45',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, String? subtitle}) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
        Text(
          label,
                              style: TextStyle(
            fontSize: 12,
            color: AppColors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.white.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.6),
      Offset(size.width, size.height * 0.4),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Haftalık özet kartı için ek widget
extension HomeScreenExtension on _HomeScreenState {
  Widget _buildWeeklySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkGrey.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bu Hafta Özet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Toplam Mesafe',
                  value: '18.5 km',
                  change: '+2.3 km',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Koşu Sayısı',
                  value: '4',
                  change: '+1',
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Ort. Hız',
                  value: '8.2 km/h',
                  change: '+0.5',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Kalori',
                  value: '1.2K',
                  change: '+180',
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
                  width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Haftalık hedefinin %85\'ini tamamladın! Harika gidiyorsun! 🎯',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 2),
            Text(
              change,
              style: TextStyle(
                fontSize: 11,
                color: isPositive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveRunCard(RunProvider runProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                runProvider.isPaused ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                runProvider.isPaused ? 'Koşu Duraklatıldı' : 'Koşu Devam Ediyor',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildRunStat('Süre', runProvider.formattedElapsedTime, Icons.timer),
              ),
              Expanded(
                child: _buildRunStat('Mesafe', runProvider.formattedDistance, Icons.straighten),
              ),
              Expanded(
                child: _buildRunStat('Alan', runProvider.formattedArea, Icons.map),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: runProvider.isPaused ? runProvider.resumeRun : runProvider.pauseRun,
                  icon: Icon(runProvider.isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(runProvider.isPaused ? 'Devam Et' : 'Duraklat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: runProvider.stopRun,
                  icon: const Icon(Icons.stop),
                  label: const Text('Bitir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStartRunCard(RunProvider runProvider) {
    if (runProvider.isRunning || runProvider.isPaused) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_run,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Koşuya Hazır mısın?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Yeni alanlar keşfet ve rakiplerinden toprak kazan!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await runProvider.startRun();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Koşuya Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 