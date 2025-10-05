import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'achievements_screen.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/chat/screens/family_chat_screen.dart';
import 'package:family_bridge/features/chat/services/media_service.dart';
import 'package:family_bridge/features/youth/providers/photo_sharing_provider.dart';
import 'package:family_bridge/features/youth/providers/youth_provider.dart';
import 'package:family_bridge/features/youth/widgets/achievement_badge.dart';
import 'package:family_bridge/features/youth/widgets/care_points_display.dart';
import 'package:family_bridge/features/youth/widgets/family_avatar_row.dart';
import 'photo_sharing_screen.dart';
import 'story_recording_screen.dart';
import 'youth_games_screen.dart';

/// Enhanced Youth Dashboard showcasing comprehensive PhotoSharingProvider integration
/// Features: photo sharing, family connection, care points, achievements, gamification
class EnhancedYouthDashboard extends StatefulWidget {
  final String userId;
  final String familyId;

  const EnhancedYouthDashboard({
    super.key,
    required this.userId,
    required this.familyId,
  });

  @override
  State<EnhancedYouthDashboard> createState() => _EnhancedYouthDashboardState();
}

class _EnhancedYouthDashboardState extends State<EnhancedYouthDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPhotoMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeProviders();
    _animationController.forward();
  }

  Future<void> _initializeProviders() async {
    final photoProvider = Provider.of<PhotoSharingProvider>(context, listen: false);
    final youthProvider = Provider.of<YouthProvider>(context, listen: false);
    
    await Future.wait([
      photoProvider.initialize(widget.familyId, widget.userId),
      youthProvider.initialize(),
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer2<PhotoSharingProvider, YouthProvider>(
            builder: (context, photoProvider, youthProvider, child) {
              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(youthProvider),
                      const SizedBox(height: 24),
                      _buildCarePointsSection(youthProvider),
                      const SizedBox(height: 32),
                      _buildQuickPhotoActions(photoProvider),
                      const SizedBox(height: 32),
                      _buildRecentPhotosSection(photoProvider),
                      const SizedBox(height: 32),
                      _buildFamilyConnectionSection(),
                      const SizedBox(height: 32),
                      _buildAchievementsSection(youthProvider),
                      const SizedBox(height: 32),
                      _buildGameifiedActions(youthProvider),
                      const SizedBox(height: 32),
                      _buildUploadProgress(photoProvider),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader(YouthProvider youthProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade400,
            Colors.teal.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Youth Hub',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect, Share, and Care for Family',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Streak: ${youthProvider.currentStreak} days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarePointsSection(YouthProvider youthProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Care Impact',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CarePointsDisplay(
            points: youthProvider.totalPoints,
            level: youthProvider.currentLevel,
            progress: youthProvider.levelProgress,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip(
                'Photos Shared',
                youthProvider.photosSharedCount.toString(),
                Icons.photo,
                Colors.blue,
              ),
              _buildStatChip(
                'Stories Recorded',
                youthProvider.storiesRecordedCount.toString(),
                Icons.mic,
                Colors.green,
              ),
              _buildStatChip(
                'Days Active',
                youthProvider.activeDaysCount.toString(),
                Icons.calendar_today,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPhotoActions(PhotoSharingProvider photoProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share a Moment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Brighten your family\'s day with a photo!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Take Photo',
                  'Snap & Share',
                  Icons.camera_alt,
                  Colors.purple,
                  () => _takePhoto(photoProvider),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'From Gallery',
                  'Pick & Share',
                  Icons.photo_library,
                  Colors.blue,
                  () => _pickFromGallery(photoProvider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => _pickMultiplePhotos(photoProvider),
              icon: const Icon(Icons.burst_mode),
              label: const Text('Share Multiple Photos'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPhotosSection(PhotoSharingProvider photoProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Family Photos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _navigateToPhotoSharing(),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (photoProvider.isLoading && photoProvider.familyPhotos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (photoProvider.familyPhotos.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(Icons.photo_library, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No family photos yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to share a moment!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photoProvider.recentPhotos.take(8).length,
                itemBuilder: (context, index) {
                  final photo = photoProvider.recentPhotos[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photo.publicUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Text(
                                photo.fileName.split('.').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '${photoProvider.familyPhotos.length} total photos',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Text('•', style: TextStyle(color: Colors.grey)),
                Text(
                  '${photoProvider.recentPhotos.length} this month',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
          if (photoProvider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      photoProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyConnectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.purple, size: 28),
              SizedBox(width: 12),
              Text(
                'Family Connection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FamilyAvatarRow(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToFamilyChat,
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('Family Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToStoryRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Record Story'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(YouthProvider youthProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Achievements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _navigateToAchievements,
                icon: const Icon(Icons.emoji_events),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (youthProvider.recentAchievements.isEmpty)
            const Text(
              'Complete actions to unlock achievements!',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: youthProvider.recentAchievements.take(4).map((achievement) {
                return AchievementBadge(
                  title: achievement.title,
                  description: achievement.description,
                  icon: achievement.icon,
                  isUnlocked: achievement.isUnlocked,
                  progress: achievement.progress,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameifiedActions(YouthProvider youthProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activities & Games',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Earn points and level up by helping your family!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildGameCard(
                'Memory Games',
                'Play with grandparents',
                Icons.psychology,
                Colors.indigo,
                () => _navigateToGames(),
              ),
              _buildGameCard(
                'Tech Helper',
                'Assist with devices',
                Icons.phone_android,
                Colors.green,
                () => _navigateToTechHelp(),
              ),
              _buildGameCard(
                'Daily Check-in',
                'Connect with family',
                Icons.check_circle,
                Colors.orange,
                () => _performDailyCheckIn(youthProvider),
              ),
              _buildGameCard(
                'Share Moment',
                'Brighten someone\'s day',
                Icons.favorite,
                Colors.pink,
                () => _takePhoto(Provider.of<PhotoSharingProvider>(context, listen: false)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(PhotoSharingProvider photoProvider) {
    if (!photoProvider.isUploading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Uploading Photo...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: photoProvider.uploadProgress,
            backgroundColor: Colors.blue.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '${(photoProvider.uploadProgress * 100).toInt()}% complete',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<PhotoSharingProvider>(
      builder: (context, photoProvider, child) {
        if (photoProvider.isUploading) {
          return FloatingActionButton(
            onPressed: null,
            backgroundColor: Colors.grey,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: photoProvider.uploadProgress,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        return FloatingActionButton.extended(
          onPressed: () => _showQuickActionDialog(photoProvider),
          label: const Text('Quick Share'),
          icon: const Icon(Icons.add_a_photo),
          backgroundColor: Colors.purple,
        );
      },
    );
  }

  Future<void> _refreshData() async {
    final photoProvider = Provider.of<PhotoSharingProvider>(context, listen: false);
    final youthProvider = Provider.of<YouthProvider>(context, listen: false);
    
    await Future.wait([
      photoProvider.refresh(),
      youthProvider.refresh(),
    ]);
  }

  Future<void> _takePhoto(PhotoSharingProvider photoProvider) async {
    try {
      final imageFile = await photoProvider.pickFromCamera(optimizeForElder: true);
      if (imageFile != null) {
        _showPhotoPreview(imageFile, photoProvider);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery(PhotoSharingProvider photoProvider) async {
    try {
      final imageFile = await photoProvider.pickFromGallery(optimizeForElder: true);
      if (imageFile != null) {
        _showPhotoPreview(imageFile, photoProvider);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick photo: $e');
    }
  }

  Future<void> _pickMultiplePhotos(PhotoSharingProvider photoProvider) async {
    try {
      final imageFiles = await photoProvider.pickMultipleImages(
        limit: 5,
        optimizeForElder: true,
      );
      
      if (imageFiles.isNotEmpty) {
        _showMultiplePhotosDialog(imageFiles, photoProvider);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick photos: $e');
    }
  }

  void _showPhotoPreview(File imageFile, PhotoSharingProvider photoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add an optional caption:'),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'What\'s happening?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                // Store caption for later use
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sharePhoto(imageFile, photoProvider);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showMultiplePhotosDialog(List<File> imageFiles, PhotoSharingProvider photoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share ${imageFiles.length} Photos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('These photos will be optimized for elderly viewing and shared with your family.'),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageFiles.length,
                itemBuilder: (context, index) => Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFiles[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _shareMultiplePhotos(imageFiles, photoProvider);
            },
            child: const Text('Share All'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionDialog(PhotoSharingProvider photoProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture and share a moment'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(photoProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photos'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(photoProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Family Chat'),
              subtitle: const Text('Send a message'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFamilyChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePhoto(File imageFile, PhotoSharingProvider photoProvider) async {
    final success = await photoProvider.sharePhoto(
      imageFile: imageFile,
      caption: 'Shared from Youth Hub',
      optimizeForElders: true,
    );
    
    if (success) {
      _showSuccessSnackBar('✨ Photo shared with family!');
      _awardPoints();
    } else {
      _showErrorSnackBar('Failed to share photo. Please try again.');
    }
  }

  Future<void> _shareMultiplePhotos(List<File> imageFiles, PhotoSharingProvider photoProvider) async {
    final success = await photoProvider.shareMultiplePhotos(
      imageFiles: imageFiles,
      caption: 'Photo collection from Youth Hub',
      optimizeForElders: true,
    );
    
    if (success) {
      _showSuccessSnackBar('🎉 ${imageFiles.length} photos shared with family!');
      _awardPoints(multiplier: imageFiles.length);
    } else {
      _showErrorSnackBar('Failed to share photos. Please try again.');
    }
  }

  void _awardPoints({int multiplier = 1}) {
    final youthProvider = Provider.of<YouthProvider>(context, listen: false);
    youthProvider.awardPoints(10 * multiplier, 'Photo sharing');
  }

  Future<void> _performDailyCheckIn(YouthProvider youthProvider) async {
    final success = await youthProvider.completeDailyCheckIn();
    if (success) {
      _showSuccessSnackBar('Daily check-in completed! +20 points');
    }
  }

  void _navigateToPhotoSharing() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PhotoSharingScreen()),
    );
  }

  void _navigateToFamilyChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FamilyChatScreen()),
    );
  }

  void _navigateToStoryRecording() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StoryRecordingScreen()),
    );
  }

  void _navigateToGames() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const YouthGamesScreen()),
    );
  }

  void _navigateToTechHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TechHelpScreen()),
    );
  }

  void _navigateToAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}