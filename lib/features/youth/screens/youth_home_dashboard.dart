import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../chat/screens/family_chat_screen.dart';
import '../providers/youth_provider.dart';
import '../widgets/care_points_display.dart';
import '../widgets/family_avatar_row.dart';
import '../widgets/youth_action_card.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/leaderboard_widget.dart';
import 'story_recording_screen.dart';
import 'photo_sharing_screen.dart';
import 'youth_games_screen.dart';

class YouthHomeDashboard extends StatelessWidget {
  const YouthHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => YouthProvider()..initialize(),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<YouthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Youth Engagement', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarePointsDisplay(points: p.points),
            const SizedBox(height: 20),
            const Text('Family Online', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FamilyAvatarRow(family: p.family),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                YouthActionCard(
                  title: 'Record Story',
                  icon: Icons.mic,
                  colors: const [Color(0xFFFF8A00), Color(0xFFFF5E62)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryRecordingScreen())),
                ),
                YouthActionCard(
                  title: 'Share Photos',
                  icon: Icons.camera_alt,
                  colors: const [Color(0xFF4DA3FF), Color(0xFF6EC2FF)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoSharingScreen())),
                ),
                YouthActionCard(
                  title: 'Play Games',
                  icon: Icons.sports_esports,
                  colors: const [Color(0xFF2ED8C3), Color(0xFF20C1AD)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YouthGamesScreen())),
                ),
                YouthActionCard(
                  title: 'Tech Help',
                  icon: Icons.build_circle,
                  colors: const [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyChatScreen(familyId: 'demo-family-123', userId: 'youth-demo', userType: 'youth'))),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Recent Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => AchievementBadge(achievement: p.achievements[index]),
              ),
            ),
            const SizedBox(height: 20),
            LeaderboardWidget(entries: p.leaderboard),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}