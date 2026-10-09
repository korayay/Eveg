import 'package:flutter/material.dart';
import '../constants/colors.dart';

class RunControlButtons extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const RunControlButtons({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!isRunning)
          _buildControlButton(
            icon: Icons.play_arrow,
            label: 'Başla',
            color: AppColors.success,
            onPressed: onStart,
          )
        else if (isPaused)
          _buildControlButton(
            icon: Icons.play_arrow,
            label: 'Devam',
            color: AppColors.success,
            onPressed: onResume,
          )
        else
          _buildControlButton(
            icon: Icons.pause,
            label: 'Duraklat',
            color: AppColors.secondary,
            onPressed: onPause,
          ),
        
        if (isRunning)
          _buildControlButton(
            icon: Icons.stop,
            label: 'Bitir',
            color: AppColors.error,
            onPressed: onStop,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 