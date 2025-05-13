import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_green_track/fitur/authentication/LoginScreen.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/jadwal_perawatan/jadwal_perawatan_page.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';

enum IntroPageType {
  welcome,
  qrCode,
  label,
}

class QRCodePainter extends CustomPainter {
  final Animation<double> animation;
  final bool showScanLine;

  QRCodePainter({required this.animation, this.showScanLine = true});

  @override
  void paint(Canvas canvas, Size size) {
    final qrPaint = Paint()
      ..color = Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    // Draw the QR code frame
    final framePaint = Paint()
      ..color = Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw QR code outer frame
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerRRect = RRect.fromRectAndRadius(outerRect, Radius.circular(12));
    canvas.drawRRect(outerRRect, framePaint);

    // Calculate the size of QR modules
    final moduleSize =
        size.width / 25; // Assuming a 21x21 QR code with some padding

    // Add position detection patterns (the three big squares in corners)
    _drawPositionDetectionPattern(canvas,
        Offset(4 * moduleSize, 4 * moduleSize), moduleSize * 7, qrPaint);
    _drawPositionDetectionPattern(
        canvas,
        Offset(4 * moduleSize, size.height - 4 * moduleSize - moduleSize * 7),
        moduleSize * 7,
        qrPaint);
    _drawPositionDetectionPattern(
        canvas,
        Offset(size.width - 4 * moduleSize - moduleSize * 7, 4 * moduleSize),
        moduleSize * 7,
        qrPaint);

    // Draw small random squares to simulate QR code data modules
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 80; i++) {
      final x = 4 * moduleSize + random.nextInt(17) * moduleSize;
      final y = 4 * moduleSize + random.nextInt(17) * moduleSize;

      // Skip if inside or too close to position detection patterns
      if (_isInsidePositionPatternArea(x, y, size, moduleSize)) continue;

      // Use animation to fade in elements gradually
      if (random.nextDouble() < animation.value) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, moduleSize, moduleSize),
          qrPaint,
        );
      }
    }

    // Draw the scanning line animation if enabled
    if (showScanLine) {
      final scanPaint = Paint()
        ..color = Color(0xFF4CAF50).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final scanY = size.height * animation.value;

      // Draw scan line with glow effect
      for (int i = 0; i < 4; i++) {
        scanPaint.color = Color(0xFF4CAF50).withOpacity(0.7 - i * 0.15);
        scanPaint.strokeWidth = 2 - i * 0.4;
        canvas.drawLine(
          Offset(moduleSize, scanY - i * 2),
          Offset(size.width - moduleSize, scanY - i * 2),
          scanPaint,
        );
      }

      // Add scan highlight
      final highlightPaint = Paint()
        ..color = Color(0xFF4CAF50).withOpacity(0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(moduleSize, 0, size.width - 2 * moduleSize, scanY),
        highlightPaint,
      );
    }
  }

  // Helper method to draw the position detection patterns (3 corners of QR code)
  void _drawPositionDetectionPattern(
      Canvas canvas, Offset position, double size, Paint paint) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(position.dx, position.dy, size, size), paint);

    // Inner white square
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(position.dx + size / 7, position.dy + size / 7,
          size * 5 / 7, size * 5 / 7),
      whitePaint,
    );

    // Center square
    canvas.drawRect(
      Rect.fromLTWH(position.dx + size * 2 / 7, position.dy + size * 2 / 7,
          size * 3 / 7, size * 3 / 7),
      paint,
    );
  }

  // Helper method to check if a point is inside or near a position detection pattern
  bool _isInsidePositionPatternArea(
      double x, double y, Size size, double moduleSize) {
    // Check top-left pattern
    if (x < 11 * moduleSize && y < 11 * moduleSize) return true;

    // Check bottom-left pattern
    if (x < 11 * moduleSize && y > size.height - 11 * moduleSize) return true;

    // Check top-right pattern
    if (x > size.width - 11 * moduleSize && y < 11 * moduleSize) return true;

    return false;
  }

  @override
  bool shouldRepaint(QRCodePainter oldDelegate) =>
      animation.value != oldDelegate.animation.value;
}

class AnimatedQRCode extends StatefulWidget {
  final double size;
  final Duration duration;

  AnimatedQRCode({
    this.size = 200,
    this.duration = const Duration(seconds: 3),
  });

  @override
  _AnimatedQRCodeState createState() => _AnimatedQRCodeState();
}

class _AnimatedQRCodeState extends State<AnimatedQRCode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // Loop the animation
    _controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: QRCodePainter(animation: _animation),
            );
          },
        ),
      ),
    );
  }
}

class ScanningBox extends StatefulWidget {
  final double size;

  ScanningBox({this.size = 250});

  @override
  _ScanningBoxState createState() => _ScanningBoxState();
}

class _ScanningBoxState extends State<ScanningBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // Loop the animation
    _controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // QR Code
        AnimatedQRCode(size: widget.size),

        // Scanning line
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              top: _animation.value * widget.size,
              child: Container(
                width: widget.size * 0.8,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final bool isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final bool isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;

    return Transform.rotate(
      angle:
          isLeft ? (isTop ? 0 : math.pi / 2) : (isTop ? -math.pi / 2 : math.pi),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(width: 3, color: Color(0xFF4CAF50)),
            left: BorderSide(width: 3, color: Color(0xFF4CAF50)),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool isUserAlreadyLogin;
  static String? routeName = "/SplashScreen";

  SplashScreen({this.isUserAlreadyLogin = false});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main animation controllers
  late AnimationController _mainController;
  late Animation<double> _mainAnimation;

  // Breathing effect animation controller
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  // Swipe indicator animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Leaf floating animations
  late AnimationController _leafFloatingController;
  late Animation<double> _leafFloatingAnimation;

  // Swipe physics simulation
  late AnimationController _swipeController;
  late Animation<double> _swipeAnimation;

  // Variables to track drag gesture and swipe status
  bool _hasCompletedSwipe = false;
  double _dragOffset = 0.0;
  final double _swipeThreshold =
      100.0; // Lowered threshold for easier triggering

  // Particle system for ambient effects
  List<Particle> _particles = [];
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    // Setup main animation
    _mainController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    );

    // Setup breathing animation
    _breathingController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _breathingAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Setup pulse animation for swipe indicator
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Setup floating leaves animation
    _leafFloatingController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );

    _leafFloatingAnimation = CurvedAnimation(
      parent: _leafFloatingController,
      curve: Curves.linear,
    );

    // Setup swipe physics controller
    _swipeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    // Setup particle controller
    _particleController = AnimationController(
      duration: Duration(milliseconds: 5000),
      vsync: this,
    )..addListener(() {
        if (mounted) {
          setState(() {
            // Update particle positions
            _updateParticles();
          });
        }
      });

    // Generate initial particles
    _generateParticles();

    // Start animations
    _mainController.forward();
    _breathingController.repeat(reverse: false);
    _leafFloatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: false);
    _particleController.repeat();

    // If user is already logged in, navigate automatically after animation
    if (widget.isUserAlreadyLogin) {
      Timer(Duration(seconds: 3), () {
        _navigateToIntro();
      });
    }
  }

  void _generateParticles() {
    final random = math.Random();
    _particles = List.generate(15, (index) {
      return Particle(
        position: Offset(
          random.nextDouble() * MediaQuery.of(Get.context!).size.width,
          random.nextDouble() * MediaQuery.of(Get.context!).size.height,
        ),
        size: random.nextDouble() * 6 + 2,
        color: Color(0xFF4CAF50).withOpacity(random.nextDouble() * 0.2 + 0.05),
        speed: Offset(
          (random.nextDouble() - 0.5) * 1.5,
          (random.nextDouble() - 0.5) * 1.5,
        ),
      );
    });
  }

  void _updateParticles() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (var particle in _particles) {
      particle.position += particle.speed;

      // Wrap particles around screen boundaries
      if (particle.position.dx < 0) {
        particle.position = Offset(screenWidth, particle.position.dy);
      } else if (particle.position.dx > screenWidth) {
        particle.position = Offset(0, particle.position.dy);
      }

      if (particle.position.dy < 0) {
        particle.position = Offset(particle.position.dx, screenHeight);
      } else if (particle.position.dy > screenHeight) {
        particle.position = Offset(particle.position.dx, 0);
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _breathingController.dispose();
    _pulseController.dispose();
    _leafFloatingController.dispose();
    _swipeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // Navigate to intro screen with smooth transition
  void _navigateToIntro() {
    if (!_hasCompletedSwipe) {
      setState(() {
        _hasCompletedSwipe = true;
      });

      Get.off(
        () => IntroScreen(),
        transition: Transition.fadeIn,
        duration: Duration(milliseconds: 700),
      );
    }
  }

  // Handle the beginning of drag gesture
  void _handleDragStart(DragStartDetails details) {
    if (_mainController.isCompleted && !widget.isUserAlreadyLogin) {
      // Stop any running swipe simulation
      _swipeController.stop();

      setState(() {
        _dragOffset = 0;
      });
    }
  }

  // Handle the drag update
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_mainController.isCompleted &&
        !widget.isUserAlreadyLogin &&
        !_hasCompletedSwipe) {
      setState(() {
        // Only allow upward swipe (negative delta Y) and limit max drag
        if (details.delta.dy < 0) {
          _dragOffset = math.min(_dragOffset - details.delta.dy, 250);
        }
      });
    }
  }

  // Handle the end of drag gesture
  void _handleDragEnd(DragEndDetails details) {
    if (_mainController.isCompleted &&
        !widget.isUserAlreadyLogin &&
        !_hasCompletedSwipe) {
      if (_dragOffset > _swipeThreshold) {
        // Calculate velocity
        final velocity = details.velocity.pixelsPerSecond.dy;

        // Apply spring simulation for smooth transition
        final simulation = SpringSimulation(
          SpringDescription(
            mass: 1.0,
            stiffness: 500.0,
            damping: 25.0,
          ),
          _dragOffset,
          250, // Target position
          -velocity / 1000, // Normalized velocity
        );

        _swipeAnimation =
            _swipeController.drive(Tween<double>(begin: _dragOffset, end: 250));

        _swipeController.animateWith(simulation).then((_) {
          _navigateToIntro();
        });
      } else {
        // Reset with spring bounce if swipe wasn't sufficient
        final simulation = SpringSimulation(
          SpringDescription(
            mass: 1.0,
            stiffness: 500.0,
            damping: 20.0,
          ),
          _dragOffset,
          0, // Target position (back to 0)
          details.velocity.pixelsPerSecond.dy / 1000, // Normalized velocity
        );

        _swipeAnimation =
            _swipeController.drive(Tween<double>(begin: _dragOffset, end: 0));

        setState(() {
          _dragOffset = 0; // Reset immediately to prevent UI jumps
        });

        _swipeController.animateWith(simulation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use animation value for drag offset if swipe animation is running
    final effectiveDragOffset =
        _swipeController.isAnimating ? _swipeAnimation.value : _dragOffset;

    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFE8F5E9),
                      ],
                      stops: [
                        0,
                        0.7 +
                            0.05 *
                                math.sin(
                                    _breathingController.value * 2 * math.pi),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Floating particles
            CustomPaint(
              painter: ParticlePainter(particles: _particles),
              size: Size.infinite,
            ),

            // Animated background elements
            Positioned(
              top: -50,
              left: -50,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_mainAnimation, _breathingAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: (0.7 + (_mainAnimation.value * 0.3)) *
                        _breathingAnimation.value,
                    child: Opacity(
                      opacity: _mainAnimation.value * 0.3,
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF81C784).withOpacity(0.4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_mainAnimation, _breathingAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: (0.6 + (_mainAnimation.value * 0.4)) *
                        _breathingAnimation.value,
                    child: Opacity(
                      opacity: _mainAnimation.value * 0.4,
                      child: Container(
                        height: 300,
                        width: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50).withOpacity(0.3),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content that moves with swipe
            Transform.translate(
              offset:
                  Offset(0, -effectiveDragOffset * 0.5), // Smoother movement
              child: AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo with breathing effect
                        AnimatedBuilder(
                          animation: _mainAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _mainAnimation.value *
                                  _breathingAnimation.value,
                              child: Opacity(
                                opacity: _mainAnimation.value,
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    boxShadow: [],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/icon/ic_app.png",
                                      width: 120,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 30),

                        // Animated app name
                        AnimatedBuilder(
                          animation: _mainAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _mainAnimation.value,
                              child: Transform.translate(
                                offset:
                                    Offset(0, 20 * (1 - _mainAnimation.value)),
                                child: Text(
                                  "GREEN TRACK",
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 10),

                        // Tagline
                        AnimatedBuilder(
                          animation: _mainAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _mainAnimation.value * 0.8,
                              child: Transform.translate(
                                offset:
                                    Offset(0, 15 * (1 - _mainAnimation.value)),
                                child: Text(
                                  "Aplikasi Pelacakan bibit dan pohon/kayu",
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Swipe up indicator (only shown if user is not logged in)
            if (!widget.isUserAlreadyLogin)
              AnimatedBuilder(
                animation: Listenable.merge([_mainAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Positioned(
                    bottom: 60 - effectiveDragOffset * 0.5, // Move with swipe
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _mainAnimation.value *
                          (_mainController.isCompleted ? 1.0 : 0) *
                          (1.0 - math.min(1.0, effectiveDragOffset / 150)),
                      child: Column(
                        children: [
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              color: Color(0xFF4CAF50),
                              size: 36,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Geser ke atas untuk melanjutkan",
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Loading indicator (only shown if user is already logged in)
            if (widget.isUserAlreadyLogin)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _mainAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _mainAnimation.value,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50)),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Swipe progress indicator - appears as user swipes
            if (!widget.isUserAlreadyLogin && effectiveDragOffset > 0)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: math.min(1.0, effectiveDragOffset / 100),
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 100),
                            width: 100 *
                                math.min(
                                    1.0, effectiveDragOffset / _swipeThreshold),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1.5),
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Particle class for ambient effects
class Particle {
  Offset position;
  final double size;
  final Color color;
  final Offset speed;

  Particle({
    required this.position,
    required this.size,
    required this.color,
    required this.speed,
  });
}

// Painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class IntroController extends GetxController {
  var currentPage = 0.obs;
  var isLastPage = false.obs;

  void updatePage(int page, int totalPages) {
    currentPage.value = page;
    isLastPage.value = page == totalPages - 1;
  }
}

class IntroScreen extends StatefulWidget {
  static String? routeName = "/IntroScreen";

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  final IntroController controller = Get.put(IntroController());
  late PageController pageController;
  late AnimationController _floatingLeafController;
  late AnimationController _backgroundAnimController;
  final List<AnimationController> _pageAnimControllers = [];
  final List<Animation<double>> _pageAnimations = [];

  @override
  void initState() {
    super.initState();
    pageController = PageController();

    _floatingLeafController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat(reverse: true);

    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    // Create animation controllers for each page
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800),
      );

      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );

      _pageAnimControllers.add(controller);
      _pageAnimations.add(animation);
    }

    // Start the first page animation
    _pageAnimControllers[0].forward();
  }

  @override
  void dispose() {
    pageController.dispose();
    _floatingLeafController.dispose();
    _backgroundAnimController.dispose();
    for (var controller in _pageAnimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFE8F5E9),
                      Color(0xFFC8E6C9),
                    ],
                    stops: [
                      0,
                      0.5 +
                          0.1 *
                              math.sin(_backgroundAnimController.value *
                                  2 *
                                  math.pi),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated background shapes
          _buildFloatingElements(),

          // PageView for intro slides
          PageView(
            controller: pageController,
            onPageChanged: (int page) {
              controller.updatePage(page, 3);
              // Start animation for current page
              _pageAnimControllers[page].reset();
              _pageAnimControllers[page].forward();
            },
            children: [
              _buildIntroPage(
                0,
                "Selamat Datang di Green Track",
                "Aplikasi pelacak dan pengelola tanaman dengan tampilan yang ramah lingkungan dan estetik",
                introType: IntroPageType.welcome,
              ),
              _buildIntroPage(
                1,
                "Pindai QR Code",
                "Pindai QR code pada bibit dan pohon untuk mengidentifikasi dan melacak pertumbuhannya dengan mudah",
                introType: IntroPageType.qrCode,
              ),
              _buildIntroPage(
                2,
                "Labeli Tumbuhan",
                "Buat dan kelola label untuk semua tanaman Anda dengan mudah dan menyenangkan",
                introType: IntroPageType.label,
              ),
            ],
          ),

          // Page navigation
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildIntroPage(int index, String title, String description,
      {required IntroPageType introType}) {
    return AnimatedBuilder(
      animation: _pageAnimations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _pageAnimations[index].value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _pageAnimations[index].value)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image or QR code with animated decoration
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative circles
                      Transform.scale(
                        scale: 0.7 + 0.3 * _pageAnimations[index].value,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50).withOpacity(0.1),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.6 + 0.4 * _pageAnimations[index].value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50).withOpacity(0.15),
                          ),
                        ),
                      ),

                      // Content based on intro type
                      Transform.scale(
                        scale: 0.8 + 0.2 * _pageAnimations[index].value,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: _buildIntroContent(introType),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 50),

                  // Text content
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build the appropriate content for each intro page
  Widget _buildIntroContent(IntroPageType type) {
    switch (type) {
      case IntroPageType.welcome:
        return Icon(
          Icons.spa_outlined,
          color: Color(0xFF2E7D32),
          size: 120,
        );

      case IntroPageType.qrCode:
        // Replace with the animated QR code
        return ScanningBox(size: 220);

      case IntroPageType.label:
        return Icon(
          Icons.label_outline,
          color: Color(0xFF2E7D32),
          size: 120,
        );
    }
  }

  Widget _buildNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page indicators
            Obx(() => Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: 8),
                      height: 10,
                      width: controller.currentPage.value == index ? 25 : 10,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? Color(0xFF4CAF50)
                            : Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                )),

            // Skip/Next/Get Started button
            Obx(
              () => controller.isLastPage.value
                  ? GestureDetector(
                      onTap: () {
                        Get.off(
                          () => LoginScreen(),
                          transition: Transition.rightToLeft,
                          duration: Duration(milliseconds: 500),
                        );
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Mulai Sekarang",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.off(
                              () => LoginScreen(),
                              transition: Transition.rightToLeft,
                              duration: Duration(milliseconds: 500),
                            );
                          },
                          child: Text(
                            "Lewati",
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            pageController.nextPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating leaf 1
        Positioned(
          top: 60,
          right: 20,
          child: AnimatedBuilder(
            animation: _floatingLeafController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  5 * math.sin(_floatingLeafController.value * 2 * math.pi),
                  10 * math.cos(_floatingLeafController.value * 2 * math.pi),
                ),
                child: Transform.rotate(
                  angle: 0.1 *
                      math.sin(_floatingLeafController.value * 2 * math.pi),
                  child: Opacity(
                    opacity: 0.7,
                    child: Icon(
                      Icons.eco,
                      color: Color(0xFF66BB6A),
                      size: 35,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating leaf 2
        Positioned(
          bottom: 100,
          left: 30,
          child: AnimatedBuilder(
            animation: _floatingLeafController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  7 * math.cos(_floatingLeafController.value * 2 * math.pi),
                  7 * math.sin(_floatingLeafController.value * 2 * math.pi),
                ),
                child: Transform.rotate(
                  angle: -0.2 *
                      math.sin(_floatingLeafController.value * 2 * math.pi + 1),
                  child: Opacity(
                    opacity: 0.6,
                    child: Icon(
                      Icons.grain,
                      color: Color(0xFF81C784),
                      size: 30,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom plant decoration
        Positioned(
          bottom: -10,
          right: -20,
          child: Opacity(
            opacity: 0.7,
            child: Icon(
              Icons.grass,
              color: Color(0xFF4CAF50),
              size: 120,
            ),
          ),
        ),

        // Top left plant decoration
        Positioned(
          top: -10,
          left: -30,
          child: Opacity(
            opacity: 0.4,
            child: Icon(
              Icons.forest,
              color: Color(0xFF81C784),
              size: 100,
            ),
          ),
        ),
      ],
    );
  }
}
