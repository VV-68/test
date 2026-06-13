import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class FinalMatchScreen extends StatelessWidget {
  const FinalMatchScreen({super.key});

  void _launchOrderApp(BuildContext context, String appName, String restaurantName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deep-linking to $appName for "$restaurantName"... 🚀'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final restaurant = state.matchedRestaurant ??
        {
          'name': 'Tony\'s Sourdough Pizzeria',
          'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
          'rating': 4.8,
          'reviewsCount': 240,
          'distance': '1.1 km',
          'deliveryTime': '20-25 mins',
          'price': r'$$',
          'desc': 'Tony\'s uses a 48-hour fermented sourdough starter to make light, crispy Neapolitan pizzas cooked in a wood-fired oven.',
        };

    final restaurantName = restaurant['name'] as String;

    return Scaffold(
      body: Container(
        color: AppTheme.bgObsidian,
        child: Stack(
          children: [
            // Glowing backdrop glow
            Positioned(
              top: -50,
              left: 50,
              right: 50,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryCoral.withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 54)),
                          const SizedBox(height: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
                            child: const Text(
                              'WE HAVE A WINNER!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your squad has matched on a restaurant.',
                            style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Winner Restaurant Card
                    Card(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.network(
                              restaurant['image'] as String,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: AppTheme.cardObsidianLight,
                                child: Icon(Icons.restaurant, size: 64, color: AppTheme.textGray),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          restaurantName,
                                          style: TextStyle(
                                            color: AppTheme.textWhite,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${restaurant['rating']}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        restaurant['price'] as String,
                                        style: const TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: AppTheme.textGray)),
                                      const SizedBox(width: 8),
                                      Text(
                                        restaurant['distance'] as String,
                                        style: TextStyle(color: AppTheme.textGray),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: AppTheme.textGray)),
                                      const SizedBox(width: 8),
                                      Text(
                                        restaurant['deliveryTime'] as String,
                                        style: TextStyle(color: AppTheme.textGray),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    restaurant['desc'] as String,
                                    style: TextStyle(color: AppTheme.textGray, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Booking / Action Buttons
                    ElevatedButton.icon(
                      onPressed: () => _launchOrderApp(context, 'Swiggy', restaurantName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5200), // Swiggy Orange
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: const Icon(Icons.delivery_dining, color: Colors.white),
                      label: const Text('Order on Swiggy', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: () => _launchOrderApp(context, 'Zomato', restaurantName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCB202D), // Zomato Red
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                      label: const Text('Order on Zomato', style: TextStyle(fontSize: 16)),
                    ),
                    
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.borderGray),
                    const SizedBox(height: 24),

                    // Who Pays game launcher
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/who-pays');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryCoral,
                        side: const BorderSide(color: AppTheme.primaryCoral, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.wallet, color: AppTheme.primaryCoral),
                      label: const Text(
                        'Who Pays? Play Mini-Game',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Back home
                    TextButton(
                      onPressed: () {
                        state.resetSwipingState();
                        Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                      },
                      child: Text(
                        'Back to Home',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                      ),
                    ),
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
