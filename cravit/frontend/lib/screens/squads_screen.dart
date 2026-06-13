import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class SquadsScreen extends StatelessWidget {
  const SquadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);
    final squads = state.squads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Squads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Food Wrapped Card
                _buildWrappedCard(context),
                
                const SizedBox(height: 36),

                // Squads Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Squads',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Create Squad flow coming soon! 👥')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardObsidian,
                        foregroundColor: AppTheme.primaryCoral,
                        side: BorderSide(color: AppTheme.borderGray),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Squad List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: squads.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final squad = squads[index];
                    return _buildSquadCard(context, squad);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedCard(BuildContext context) {
    // Custom painted or container-based bar chart
    final List<Map<String, dynamic>> favoriteFoods = [
      {'name': 'Pizza 🍕', 'pct': 0.8, 'color': AppTheme.primaryCoral},
      {'name': 'Burgers 🍔', 'pct': 0.65, 'color': AppTheme.secondaryPink},
      {'name': 'Sushi 🍣', 'pct': 0.4, 'color': AppTheme.starBlue},
      {'name': 'Pasta 🍝', 'pct': 0.3, 'color': Colors.amber},
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppTheme.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCoral.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Ambient design circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🌟 WRAPPED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Squad Food Wrapped',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Your shared culinary history at a glance.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Analytics Row
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('3,240', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          Text('Swipes Made', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('114', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          Text('Total Matches', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('8:00 PM', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          Text('Prime Time', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  const Text(
                    'Top Swiped Cuisines',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 14),

                  // Custom Horizontal Bars
                  Column(
                    children: favoriteFoods.map((item) {
                      final pct = item['pct'] as double;
                      final name = item['name'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(pct * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Bar holder
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: pct,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadCard(BuildContext context, Map<String, dynamic> squad) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Squad Avatar Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(squad['avatarColor'] as int).withOpacity(0.15),
              ),
              child: Center(
                child: Icon(
                  Icons.group,
                  color: Color(squad['avatarColor'] as int),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    squad['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${squad['members']} members',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: AppTheme.textGray)),
                      const SizedBox(width: 8),
                      Text(
                        '${squad['matches']} matches',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Cuisine Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardObsidianLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Column(
                children: [
                   Text(
                    'FAVORITE',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    squad['topCuisine'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
