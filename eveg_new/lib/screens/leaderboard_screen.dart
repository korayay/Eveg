import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/user.dart' as app_user;
import '../services/firebase_service.dart';
import '../widgets/leaderboard_item.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<app_user.User> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    FirebaseService().getLeaderboard().listen((users) {
      setState(() {
        _leaderboard = users;
        _isLoading = false;
      });
    });
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
      appBar: AppBar(
        title: const Text(
          'Liderlik Tablosu',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          tabs: const [
            Tab(text: 'Genel'),
            Tab(text: 'Bu Hafta'),
            Tab(text: 'Bu Ay'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(_leaderboard),
                _buildLeaderboardTab(_leaderboard), // Haftalık
                _buildLeaderboardTab(_leaderboard), // Aylık
              ],
            ),
    );
  }

  Widget _buildLeaderboardTab(List<app_user.User> users) {
    return Column(
      children: [
        // Üst 3 için özel kartlar
        if (users.isNotEmpty) ...[
          _buildTopThreeSection(users),
          const SizedBox(height: 16),
        ],
        
        // Diğer sıralamalar
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length > 3 ? users.length - 3 : 0,
            itemBuilder: (context, index) {
              final user = users[index + 3]; // İlk 3'ü atla
              return LeaderboardItem(
                user: user,
                rank: index + 4,
                isCurrentUser: user.id == 'current_user_id',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopThreeSection(List<app_user.User> users) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 2. sıra
          if (users.length > 1)
            Expanded(
              child: _buildTopThreeCard(
                users[1],
                2,
                AppColors.grey,
                isCurrentUser: users[1].id == 'current_user_id',
              ),
            ),
          
          // 1. sıra
          if (users.isNotEmpty)
            Expanded(
              child: _buildTopThreeCard(
                users[0],
                1,
                AppColors.secondary,
                isCurrentUser: users[0].id == 'current_user_id',
                isFirst: true,
              ),
            ),
          
          // 3. sıra
          if (users.length > 2)
            Expanded(
              child: _buildTopThreeCard(
                users[2],
                3,
                AppColors.error,
                isCurrentUser: users[2].id == 'current_user_id',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopThreeCard(
    app_user.User user,
    int rank,
    Color color, {
    bool isFirst = false,
    bool isCurrentUser = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : color.withOpacity(0.3),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sıralama
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Kullanıcı avatarı
          CircleAvatar(
            radius: isFirst ? 30 : 25,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              user.username.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: isFirst ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Kullanıcı adı
          Text(
            user.username,
            style: TextStyle(
              fontSize: isFirst ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? AppColors.primary : AppColors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Puan
          Text(
            '${user.totalPoints} puan',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Alan sayısı
          Text(
            '${user.totalAreas} alan',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 