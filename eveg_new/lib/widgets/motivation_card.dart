import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MotivationCard extends StatelessWidget {
  const MotivationCard({super.key});

  String _getMotivationalMessage() {
    final messages = [
      'Bugün harika bir koşu günü! 🏃‍♂️',
      'Yeni alanlar keşfetme zamanı! 🗺️',
      'Her adım seni daha güçlü yapıyor! 💪',
      'Hedeflerine bir adım daha yaklaşıyorsun! 🎯',
      'Koşu, özgürlüğün en güzel hali! 🌟',
      'Bugün kendini aşma günü! 🚀',
    ];
    
    final now = DateTime.now();
    final index = now.day % messages.length;
    return messages[index];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Günün Motivasyonu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getMotivationalMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bugün 5 km koş hedefin var',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '3.2 km kaldı',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 