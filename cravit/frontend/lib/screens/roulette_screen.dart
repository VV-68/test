import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  List<String> _options = [];
  
  late AnimationController _controller;
  late Animation<double> _animation;
  double _startRotation = 0.0;
  double _endRotation = 0.0;
  bool _isSpinning = false;
  String? _selectedResult;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_options.isEmpty) {
      final state = Provider.of<RoomState>(context);
      final matchedCuisineName = state.matchedCuisine ?? 'Pizza';
      final List<Map<String, dynamic>> restaurants = state.restaurantsByCuisine[matchedCuisineName] ?? [];
      _options = restaurants.map((r) => r['name'] as String).toList();
      if (_options.isEmpty) {
        _options = ['Tony\'s Sourdough Pizzeria', 'Bella Italia Trattoria', 'Slice & Dice Pizza Pub'];
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    final rand = Random();
    // Spin at least 4 full rotations + random angle
    final extraSpins = 4 + rand.nextInt(4);
    final randomAngle = rand.nextDouble() * 2 * pi;
    
    setState(() {
      _isSpinning = true;
      _selectedResult = null;
      _startRotation = _endRotation % (2 * pi);
      _endRotation = _startRotation + (extraSpins * 2 * pi) + randomAngle;
    });

    _animation = Tween<double>(
      begin: _startRotation,
      end: _endRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));

    _controller.reset();
    _controller.forward().then((_) {
      // Calculate landing item
      // Selector is at the top (angle = -pi/2 or 3*pi/2)
      // Wheel spins clockwise, so index = total_options - (landed_angle / segment_angle)
      final segmentAngle = (2 * pi) / _options.length;
      final finalAngle = (_endRotation - (pi / 2)) % (2 * pi);
      final index = (_options.length - (finalAngle / segmentAngle).floor()) % _options.length;

      setState(() {
        _isSpinning = false;
        _selectedResult = _options[index];
      });

      _showWinnerDialog(_options[index]);
    });
  }

  void _showWinnerDialog(String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardObsidian,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.borderGray),
        ),
        title: const Center(
          child: Text(
            '🎯 Decided!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The roulette wheel has spoken:',
              style: TextStyle(color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                result,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                final state = Provider.of<RoomState>(context, listen: false);
                state.setMatchedRestaurantByName(result);
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/final-match');
              },
              child: const Text('Go to Order Selection'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roulette Wheel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Tie-Breaker Spin 🎡',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Can\'t agree? Let the wheel decide.',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                ),
              ),
              
              const Spacer(),

              // Canvas Painted Wheel
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning Wheel Canvas
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value,
                            child: CustomPaint(
                              size: const Size(300, 300),
                              painter: WheelPainter(options: _options),
                            ),
                          );
                        },
                      ),
                      
                      // Central Hub Pin
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardObsidian,
                          border: Border.all(color: AppTheme.textWhite, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.star, color: Colors.amber, size: 18),
                        ),
                      ),

                      // Selection pointer needle at top
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 30,
                          child: CustomPaint(
                            painter: NeedlePainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Spin Trigger CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCoral.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSpinning ? null : _spinWheel,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      _isSpinning ? 'SPINNING...' : 'SPIN WHEEL',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> options;

  WheelPainter({required this.options});

  // Balanced HSL color selection for segments
  final List<Color> colors = [
    const Color(0xFFFF6B4A),
    const Color(0xFFFF4B72),
    const Color(0xFF4FA7FF),
    const Color(0xFF8B5CF6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentAngle = (2 * pi) / options.length;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = AppTheme.borderGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < options.length; i++) {
      paint.color = colors[i % colors.length];
      
      // Draw Slice
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, paint);
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, borderPaint);

      // Draw text label
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Align rotation vector to the middle of the segment slice
      canvas.rotate((i * segmentAngle) + (segmentAngle / 2));
      
      // Text painter layout
      final textSpan = TextSpan(
        text: options[i],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: radius * 0.7);

      // Draw labels radially
      textPainter.paint(
        canvas,
        Offset(radius * 0.25, -textPainter.height / 2),
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppTheme.bgObsidian
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0.0, 0.0)
      ..lineTo(size.width, 0.0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
