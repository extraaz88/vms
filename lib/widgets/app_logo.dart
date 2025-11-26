import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/logo.png',
        width: width,
        height: height,
        color: color,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a default icon if logo fails to load
          return Container(
            width: width ?? height ?? 40,
            height: height ?? width ?? 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.business,
              size: (width ?? height ?? 40) * 0.6,
              color: color ?? Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
}
