import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class MatchTransitionScreen extends StatefulWidget {
  const MatchTransitionScreen({super.key});

  @override
  State<MatchTransitionScreen> createState() => _MatchTransitionScreenState();
}

class _MatchTransitionScreenState extends State<MatchTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final List<Particle> _particles = [];
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {
          _updateParticles();
        });
      });

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _animController.forward();
    _generateParticles();

    // Auto navigate after 3.0 seconds to give user time to enjoy the match screen
    _navigationTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/swipe-restaurants');
      }
    });
  }

  void _generateParticles() {
    final rand = Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(Particle(
        x: 0.0,
        y: 0.0,
        vx: (rand.nextDouble() - 0.5) * 12,
        vy: (rand.nextDouble() - 0.7) * 14 - 4,
        color: rand.nextBool() ? AppTheme.primaryCoral : AppTheme.secondaryPink,
        size: rand.nextDouble() * 6 + 4,
      ));
    }
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.35; // Gravity
      p.size = max(0.0, p.size - 0.05); // Shrink
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final cuisineName = state.matchedCuisine ?? 'Food';
    final cuisineImage = state.cuisines.firstWhere(
      (c) => c['name'] == cuisineName,
      orElse: () => {'image': 'assets/images/pizza_cuisine.png'},
    )['image'] as String;

    final partners = state.players.where((p) => p['isYou'] == false).toList();
    final String partnerName = partners.isNotEmpty ? partners.first['name'].split(' ').first : 'Partner';

    final subtitleText = partners.isNotEmpty
        ? 'You and $partnerName both want...'
        : 'You matched...';

    return Scaffold(
      body: Container(
        color: AppTheme.bgObsidian,
        child: Stack(
          children: [
            // 1. Zoomed, blurred background backdrop
            Positioned.fill(
              child: Image.asset(
                cuisineImage,
                fit: BoxFit.cover,
              ),
            ),

            // 2. Dark glassmorphic blur overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ),

            // 3. Floating Confetti particles custom painted
            Positioned.fill(
              child: CustomPaint(
                painter: ParticlePainter(_particles),
              ),
            ),

            // 4. Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Tinder-style Match Title
                    Text(
                      "It's a Match!",
                      style: GoogleFonts.greatVibes(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.normal,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Match Subtitle
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 1),

                    // Matched Item Hero Card (Zoomed, fitting the screen)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.45,
                        decoration: BoxDecoration(
                          color: AppTheme.cardObsidian,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryCoral.withOpacity(0.4),
                              blurRadius: 35,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Stack(
                            children: [
                              Image.asset(
                                cuisineImage,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.85),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 28,
                                left: 24,
                                right: 24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cuisineName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A perfect culinary match!',
                                      style: TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading Specific Restaurants
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCoral),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading specific restaurants...',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Position coordinates offset to screen center for explosion origin
    final center = Offset(size.width / 2, size.height * 0.5);

    for (var p in particles) {
      if (p.size <= 0.0) continue;
      paint.color = p.color;
      canvas.drawCircle(Offset(center.dx + p.x, center.dy + p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
