import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BadgeItem extends StatelessWidget {
  final String badgeName;
  final bool isUnlocked;

  const BadgeItem({
    super.key,
    required this.badgeName,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked 
            ? AppColors.secondary.withOpacity(0.1)
            : AppColors.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked 
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.darkGrey,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getBadgeIcon(badgeName),
            color: isUnlocked ? AppColors.secondary : AppColors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            badgeName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppColors.white : AppColors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getBadgeIcon(String badgeName) {
    switch (badgeName.toLowerCase()) {
      case 'ilk koşu':
        return Icons.directions_run;
      case '5 km':
        return Icons.straighten;
      case '10 km':
        return Icons.straighten;
      case 'maraton':
        return Icons.flag;
      case 'alan fatihi':
        return Icons.map;
      case 'hız canavarı':
        return Icons.speed;
      case 'sürekli':
        return Icons.calendar_today;
      case 'haftalık':
        return Icons.view_week;
      case 'aylık':
        return Icons.calendar_month;
      case 'yıllık':
        return Icons.calendar_month;
      case 'sosyal':
        return Icons.people;
      case 'lider':
        return Icons.emoji_events;
      case 'veteran':
        return Icons.military_tech;
      case 'yeni başlayan':
        return Icons.school;
      default:
        return Icons.star;
    }
  }
} 