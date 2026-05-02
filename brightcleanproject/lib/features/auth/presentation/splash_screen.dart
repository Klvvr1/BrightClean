import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main animation controller (drives the staggered entrance)
  late final AnimationController _mainController;
  // Pulsing glow behind the logo
  late final AnimationController _pulseController;
  // Floating bubbles controller
  late final AnimationController _bubblesController;

  // Staggered animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _pulseAnimation;

  // Pre-generated bubble data for floating particles
  late final List<_BubbleData> _bubbles;

  @override
  void initState() {
    super.initState();

    // Generate random bubbles
    final rng = Random();
    _bubbles = List.generate(18, (_) => _BubbleData(rng));

    // Main entrance: 2 seconds with staggered intervals
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Pulse glow: loops forever
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Bubbles: loops forever
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // --- Staggered entrance animations ---

    // Logo: scale from 0 → 1 with an elastic overshoot (0% → 45%)
    _logoScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.50, curve: Curves.elasticOut),
    );
    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );

    // Title: fade + slide up (35% → 60%)
    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.35, 0.60, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.35, 0.60, curve: Curves.easeOutCubic),
    ));

    // Subtitle: fade + slide up (50% → 75%)
    _subtitleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.50, 0.75, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.50, 0.75, curve: Curves.easeOutCubic),
    ));

    // Loader: fade in (70% → 90%)
    _loaderOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
    );

    // Pulse: subtle scale 1.0 → 1.08
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the entrance
    _mainController.forward();

    // Navigate after the splash finishes
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _bubblesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Animated gradient background ---
          _buildGradientBackground(),

          // --- Floating bubbles layer ---
          _buildFloatingBubbles(),

          // --- Main content ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo with scale + fade + pulsing glow
                _buildAnimatedLogo(),

                const SizedBox(height: 32),

                // App title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: Text(
                      'برايت كلين',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'خدمات الغسيل والنظافة المنزلية',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.lightBlue.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator
                FadeTransition(
                  opacity: _loaderOpacity,
                  child: _buildShimmerLoader(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Gradient background with subtle animated color shift ---
  Widget _buildGradientBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Subtle hue shift on the gradient stops
        final t = _pulseController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0A1C40),
                  const Color(0xFF0F2854),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF0F2854),
                  const Color(0xFF1C4D8D),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF1C4D8D),
                  const Color(0xFF2D6BB4),
                  t * 0.6,
                )!,
              ],
              stops: [0.0, 0.5 + (t * 0.1), 1.0],
            ),
          ),
        );
      },
    );
  }

  // --- Floating particles (subtle depth effect) ---
  Widget _buildFloatingBubbles() {
    return AnimatedBuilder(
      animation: _bubblesController,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblePainter(
            bubbles: _bubbles,
            progress: _bubblesController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // --- Animated logo with glow ring ---
  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _logoScale,
      child: FadeTransition(
        opacity: _logoOpacity,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _pulseAnimation.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color:
                          AppColors.lightBlue.withValues(alpha: 0.25 * scale),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                    // Inner glow
                    BoxShadow(
                      color: AppColors.tertiary.withValues(alpha: 0.15 * scale),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Custom shimmer-style loading bar ---
  Widget _buildShimmerLoader() {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 3,
              child: AnimatedBuilder(
                animation: _bubblesController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: null,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.lightBlue.withValues(alpha: 0.8),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جارٍ التحميل...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Bubble data model ---
class _BubbleData {
  final double x; // 0..1 horizontal position
  final double startY; // starting Y ratio
  final double size;
  final double speed; // vertical travel speed multiplier
  final double opacity;
  final double drift; // horizontal sine wave amplitude

  _BubbleData(Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble(),
        size = 3 + rng.nextDouble() * 8,
        speed = 0.3 + rng.nextDouble() * 0.7,
        opacity = 0.04 + rng.nextDouble() * 0.12,
        drift = 0.005 + rng.nextDouble() * 0.02;
}

// --- Custom painter for floating bubbles ---
class _BubblePainter extends CustomPainter {
  final List<_BubbleData> bubbles;
  final double progress;

  _BubblePainter({required this.bubbles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      // Each bubble loops at its own speed
      final t = (progress * b.speed + b.startY) % 1.0;
      final y = size.height * (1.0 - t);
      final x =
          size.width * b.x + sin(t * 2 * pi + b.x * 6) * size.width * b.drift;

      final paint = Paint()
        ..color = AppColors.lightBlue.withValues(alpha: b.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.progress != progress;
}
