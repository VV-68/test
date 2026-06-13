import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_state.dart';
import '../theme/app_theme.dart';

class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<RoomState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () {
            state.leaveRoom();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: AppTheme.bgObsidian,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Set the Vibe 🍽️',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Configure preferences for your group swiping session.',
                        style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                      ),
                      const SizedBox(height: 32),

                      // Distance Slider
                      _buildSectionHeader(context, 'Distance Radius', '${state.distanceRadius.toStringAsFixed(1)} km'),
                      const SizedBox(height: 8),
                      Slider(
                        value: state.distanceRadius,
                        min: 1.0,
                        max: 25.0,
                        divisions: 48,
                        onChanged: (val) => state.setDistance(val),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1 km', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                            Text('25 km', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Budget Selector
                      _buildSectionHeader(context, 'Budget Tier', state.budgetOptions[state.budgetIndex]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: List.generate(
                          state.budgetOptions.length,
                          (index) {
                            final isSelected = state.budgetIndex == index;
                            return InkWell(
                              onTap: () => state.setBudget(index),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryCoral
                                      : AppTheme.cardObsidian,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryCoral
                                        : AppTheme.borderGray,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  state.budgetOptions[index],
                                  style: TextStyle(
                                    color: AppTheme.textWhite,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Dietary Requirements Toggle
                      _buildSectionHeader(context, 'Dietary Requirements', '${state.selectedDietaryTags.length} selected'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 10.0,
                        children: state.dietaryOptions.map((tag) {
                          final isSelected = state.selectedDietaryTags.contains(tag);
                          return FilterChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => state.toggleDietaryTag(tag),
                            backgroundColor: AppTheme.cardObsidian,
                            selectedColor: AppTheme.secondaryPink,
                            checkmarkColor: AppTheme.textWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppTheme.secondaryPink : AppTheme.borderGray,
                                width: 1.2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Session Timer
                      _buildSectionHeader(context, 'Swipe Time Limit', '${state.timerMinutes} minutes'),
                      const SizedBox(height: 8),
                      Slider(
                        value: state.timerMinutes.clamp(1, 5).toDouble(),
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        onChanged: (val) => state.setTimerMinutes(val.toInt()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1 min', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                            Text('5 min', style: TextStyle(color: AppTheme.textGray, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Lobby Capacity / Max Participants
                      _buildSectionHeader(context, 'Lobby Capacity', '${state.maxParticipants} players'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildCapacityButton(
                            icon: Icons.remove,
                            onPressed: () {
                              if (state.maxParticipants > 1) {
                                state.setMaxParticipants(state.maxParticipants - 1);
                              }
                            },
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text(
                              '${state.maxParticipants}',
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildCapacityButton(
                            icon: Icons.add,
                            onPressed: () {
                              state.setMaxParticipants(state.maxParticipants + 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Confirm Button Panel
              Padding(
                padding: const EdgeInsets.all(24.0),
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
                    onPressed: () {
                      Navigator.of(context).pushNamed('/lobby');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.isHost ? 'Create Lobby' : 'Apply Filters',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
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

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.primaryCoral,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardObsidian,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primaryCoral),
        onPressed: onPressed,
      ),
    );
  }
}
