import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class WhoPaysScreen extends StatefulWidget {
  const WhoPaysScreen({super.key});

  @override
  State<WhoPaysScreen> createState() => _WhoPaysScreenState();
}

class _WhoPaysScreenState extends State<WhoPaysScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _startRotation = 0.0;
  double _endRotation = 0.0;
  bool _isSpinning = false;
  String? _payerWinner;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinToDecide(List<Map<String, dynamic>> playersList) {
    if (_isSpinning || playersList.isEmpty) return;

    final rand = Random();
    final extraSpins = 4 + rand.nextInt(4);
    final randomAngle = rand.nextDouble() * 2 * pi;

    setState(() {
      _isSpinning = true;
      _payerWinner = null;
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
      // Calculate landing index
      final segmentAngle = (2 * pi) / playersList.length;
      final finalAngle = (_endRotation - (pi / 2)) % (2 * pi);
      final index = (playersList.length - (finalAngle / segmentAngle).floor()) % playersList.length;

      setState(() {
        _isSpinning = false;
        _payerWinner = playersList[index]['name'] as String;
      });

      _showPayerDialog(_payerWinner!);
    });
  }

  void _showPayerDialog(String winner) {
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
            '💸 Wallet Alert!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner == 'You' || winner == 'You (Host)'
                  ? 'Oh no! Today\'s feast is on you.'
                  : 'Jackpot! You eat for free today.',
              style: TextStyle(color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                winner,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              winner == 'You' || winner == 'You (Host)'
                  ? 'Time to pull out the credit card... 💳'
                  : 'Sarah is paying! 😋',
              style: TextStyle(color: AppTheme.textGray, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Okay, Deal!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    
    // Ensure we have players, if empty fallback to You & Sarah
    final List<Map<String, dynamic>> playersList = state.players.isNotEmpty
        ? state.players
        : [
            {'name': 'You', 'avatarUrl': 'https://api.dicebear.com/7.x/bottts/svg?seed=you'},
            {'name': 'Sarah', 'avatarUrl': 'https://api.dicebear.com/7.x/bottts/svg?seed=Sarah'},
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Pays?'),
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
                  'The Bill Roulette 💸',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Whose wallet is getting lighter today?',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                ),
              ),
              
              const Spacer(),

              // Custom Painter Player Wheel
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
                              painter: PayerWheelPainter(players: playersList),
                            ),
                          );
                        },
                      ),
                      
                      // Central Pin
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardObsidian,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.credit_card, color: Colors.amber, size: 18),
                        ),
                      ),

                      // Selection Pointer Arrow at top
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 30,
                          child: CustomPaint(
                            painter: PayerNeedlePainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Spin Action Button
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
                    onPressed: _isSpinning ? null : () => _spinToDecide(playersList),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      _isSpinning ? 'SPINNING...' : 'SPIN TO DECIDE',
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

class PayerWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> players;

  PayerWheelPainter({required this.players});

  final List<Color> colors = [
    const Color(0xFFFF6B4A),
    const Color(0xFFFF4B72),
    const Color(0xFF4FA7FF),
    const Color(0xFF10B981),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (players.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentAngle = (2 * pi) / players.length;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = AppTheme.borderGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < players.length; i++) {
      paint.color = colors[i % colors.length];

      // Draw Slice Segment
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, paint);
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, borderPaint);

      // Draw player name text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * segmentAngle) + (segmentAngle / 2));

      final textSpan = TextSpan(
        text: players[i]['name'] as String? ?? 'Friend',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: radius * 0.7);

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

class PayerNeedlePainter extends CustomPainter {
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
