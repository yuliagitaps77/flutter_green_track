// Widget untuk menggunakan scanner
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_green_track/presentation/pages/navigation/navigation_page.dart';
import 'dart:math' as math;

class ScannerWidget extends StatefulWidget {
  final double width;
  final double height;

  const ScannerWidget({
    Key? key,
    this.width = 300.0,
    this.height = 300.0,
  }) : super(key: key);

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: ScannerPainter(animation: _controller),
      ),
    );
  }
}

// Custom FAB location that places the scan button at the right position
class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final double screenHeight;

  _CustomFloatingActionButtonLocation({
    required this.screenHeight,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Position the FAB centered horizontally and overlapping the bottom nav
    return Offset(
      scaffoldGeometry.scaffoldSize.width / 2 - 32.5,
      scaffoldGeometry.scaffoldSize.height -
          104, // 80 (bottom nav height) + 24 (overlap)
    );
  }
}

// Custom clipper for creating a wave-like curve in the bottom nav
class BottomNavClipper extends CustomClipper<Path> {
  final double waveAnimation;
  final double centerDip;

  BottomNavClipper({
    required this.waveAnimation,
    required this.centerDip,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Starting point
    path.moveTo(0, 0);

    // Top edge with wave
    final centerX = width / 2;

    // Left part of the curve
    path.quadraticBezierTo(
      centerX - 70, // Control point
      0, // Control point
      centerX - 35, // End point X
      centerDip * math.sin(waveAnimation * math.pi * 2) * 0.2 +
          centerDip * 0.8, // End point Y with subtle wave animation
    );

    // Center dip of the curve
    path.quadraticBezierTo(
      centerX, // Control point
      centerDip * 2, // Control point with deeper curve
      centerX + 35, // End point X
      centerDip * math.sin(waveAnimation * math.pi * 2) * 0.2 +
          centerDip * 0.8, // End point Y with subtle wave animation
    );

    // Right part of the curve
    path.quadraticBezierTo(
      centerX + 70, // Control point
      0, // Control point
      width, // End point X
      0, // End point Y
    );

    // Complete the rectangle
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
