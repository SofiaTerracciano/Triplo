import 'package:flutter/material.dart';

class NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const NavigationButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: disabled ? Colors.grey.shade800 : color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child:  SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: disabled ? Colors.white54 : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}