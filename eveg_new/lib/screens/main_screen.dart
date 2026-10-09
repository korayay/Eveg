import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth_screen.dart';
import '../constants/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),        // 0: Ana Sayfa
    const MapScreen(),         // 1: Harita  
    const LeaderboardScreen(), // 2: Liderler
    const ProfileScreen(),     // 3: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Firebase hatası veya kullanıcı giriş yapmamışsa AuthScreen göster
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }
        
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }
        
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.darkBackground,
              border: Border(
                top: BorderSide(
                  color: AppColors.darkGrey,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.darkBackground,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.grey,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Harita/Koşu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: 'Liderler',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 