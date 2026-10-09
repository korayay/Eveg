import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/run_provider.dart';
import '../constants/colors.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/badge_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text(
                'Giriş yapmanız gerekiyor',
                style: TextStyle(color: AppColors.white),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Profil başlığı
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.darkBackground,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(authProvider.currentUser!),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.white),
                    onPressed: () {
                      // Ayarlar sayfasına git
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.white),
                    onPressed: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
              
              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.grey,
                    tabs: const [
                      Tab(text: 'Genel'),
                      Tab(text: 'Koşular'),
                      Tab(text: 'Alanlar'),
                    ],
                  ),
                ),
              ),
              
              // Tab içerikleri
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(authProvider.currentUser!),
                    _buildRunsTab(),
                    _buildAreasTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: Text(
                  user.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Kullanıcı adı
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Seviye
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Seviye ${user.level}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistikler
          const Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ProfileStatsCard(
                  title: 'Toplam Puan',
                  value: '${user.totalPoints}',
                  icon: Icons.emoji_events,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProfileStatsCard(
                  title: 'Toplam Alan',
                  value: '${user.totalAreas}',
                  icon: Icons.map,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ProfileStatsCard(
                  title: 'Toplam Mesafe',
                  value: '${(user.totalDistance / 1000).toStringAsFixed(1)} km',
                  icon: Icons.directions_run,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProfileStatsCard(
                  title: 'Üyelik',
                  value: '${DateTime.now().difference(user.createdAt).inDays} gün',
                  icon: Icons.calendar_today,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Rozetler
          const Text(
            'Rozetler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (user.badges.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Henüz rozet kazanmadın. Koşmaya başla!',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: user.badges.length,
              itemBuilder: (context, index) {
                return BadgeItem(
                  badgeName: user.badges[index],
                  isUnlocked: true,
                );
              },
            ),
          
          const SizedBox(height: 32),
          
          // Çıkış butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsTab() {
    return Consumer<RunProvider>(
      builder: (context, runProvider, child) {
        if (runProvider.userRuns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_run,
                  size: 64,
                  color: AppColors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz koşu yapmadın',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'İlk koşunu yapmaya başla!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: runProvider.userRuns.length,
          itemBuilder: (context, index) {
            final run = runProvider.userRuns[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(
                    Icons.directions_run,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  '${run.formattedDistance} koşu',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                subtitle: Text(
                  '${run.formattedDuration} • ${run.formattedArea}',
                  style: const TextStyle(color: AppColors.grey),
                ),
                trailing: Text(
                  run.formattedSpeed,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAreasTab() {
    return const Center(
      child: Text(
        'Alanlar sayfası - geliştiriliyor',
        style: TextStyle(color: AppColors.white),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Hesabından çıkış yapmak istediğinden emin misin?',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: AppColors.darkBackground,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
} 