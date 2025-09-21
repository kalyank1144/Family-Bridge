import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/elder_provider.dart';
import '../models/medication_model.dart';
import '../widgets/large_action_button.dart';
import '../widgets/medication_photo_card.dart';
import '../widgets/voice_navigation_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/voice_checkin_widget.dart';
import 'medication_reminder_screen.dart';
import 'daily_checkin_screen.dart';
import 'emergency_contacts_screen.dart';
import '../../chat/screens/family_chat_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/voice_service.dart';

/// Enhanced Elder Dashboard that showcases comprehensive ElderProvider integration
/// Features: medication management, daily check-ins, family communication, health tracking
class EnhancedElderDashboard extends StatefulWidget {
  final String userId;

  const EnhancedElderDashboard({
    super.key,
    required this.userId,
  });

  @override
  State<EnhancedElderDashboard> createState() => _EnhancedElderDashboardState();
}

class _EnhancedElderDashboardState extends State<EnhancedElderDashboard> {
  bool _isVoiceEnabled = true;
  bool _highContrastMode = false;
  late VoiceService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = Provider.of<VoiceService>(context, listen: false);
    _initializeElderProvider();
  }

  Future<void> _initializeElderProvider() async {
    final elderProvider = Provider.of<ElderProvider>(context, listen: false);
    await elderProvider.initialize(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            if (elderProvider.isLoading && elderProvider.medications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 6),
                    SizedBox(height: 24),
                    Text(
                      'Loading your health information...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: elderProvider.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, elderProvider),
                    const SizedBox(height: 24),
                    _buildQuickStats(context, elderProvider),
                    const SizedBox(height: 32),
                    _buildTodaysMedications(context, elderProvider),
                    const SizedBox(height: 32),
                    _buildMainActions(context, elderProvider),
                    const SizedBox(height: 32),
                    _buildHealthStatus(context, elderProvider),
                    const SizedBox(height: 32),
                    _buildFamilyConnection(context),
                    const SizedBox(height: 32),
                    _buildWeatherAndSettings(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _isVoiceEnabled
          ? FloatingActionButton.large(
              onPressed: _handleVoiceCommand,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.mic,
                size: 32,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, ElderProvider elderProvider) {
    final now = DateTime.now();
    final greeting = _getTimeBasedGreeting();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showSettings(),
                icon: const Icon(
                  Icons.settings,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (elderProvider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      elderProvider.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
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

  Widget _buildQuickStats(BuildContext context, ElderProvider elderProvider) {
    final overdueCount = elderProvider.overdueReminders.length;
    final pendingCount = elderProvider.pendingReminders.length;
    final complianceRate = elderProvider.complianceStats?.overallComplianceRate ?? 0.0;

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
            'Today\'s Health Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Medications Due',
                  pendingCount.toString(),
                  Icons.medication,
                  pendingCount > 0 ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Overdue',
                  overdueCount.toString(),
                  Icons.warning,
                  overdueCount > 0 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Compliance',
                  '${(complianceRate * 100).toInt()}%',
                  Icons.check_circle,
                  complianceRate >= 0.8 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMedications(BuildContext context, ElderProvider elderProvider) {
    final todayReminders = elderProvider.todaysReminders;
    final pendingReminders = elderProvider.pendingReminders;

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
                'Today\'s Medications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _navigateToMedicationReminders(),
                icon: const Icon(Icons.view_list),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayReminders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All medications taken for today!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...pendingReminders.take(3).map((reminder) => 
              _buildMedicationCard(context, reminder, elderProvider)),
            if (pendingReminders.length > 3) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _navigateToMedicationReminders(),
                  child: Text('View ${pendingReminders.length - 3} more medications'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, MedicationReminder reminder, ElderProvider elderProvider) {
    final medication = elderProvider.getMedicationById(reminder.medicationId);
    if (medication == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reminder.isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.isOverdue ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: reminder.isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: reminder.isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.medicationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.dosage} • ${DateFormat.jm().format(reminder.scheduledTime)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                if (reminder.isOverdue) ...[
                  const SizedBox(height: 4),
                  Text(
                    'OVERDUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _takeMedication(context, reminder, elderProvider),
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Take'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _snoozeMedication(context, reminder, elderProvider),
                child: const Text('Snooze 15m'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(BuildContext context, ElderProvider elderProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: LargeActionButton(
                title: 'Daily Check-in',
                subtitle: elderProvider.isDailyCheckInComplete 
                    ? '✅ Completed' 
                    : 'Share how you feel',
                icon: Icons.favorite,
                color: elderProvider.isDailyCheckInComplete 
                    ? Colors.green 
                    : AppTheme.primaryColor,
                onPressed: () => _navigateToDailyCheckin(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LargeActionButton(
                title: 'Emergency',
                subtitle: 'Call for help',
                icon: Icons.emergency,
                color: Colors.red,
                onPressed: () => _navigateToEmergencyContacts(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LargeActionButton(
                title: 'Family Chat',
                subtitle: 'Stay connected',
                icon: Icons.chat,
                color: Colors.purple,
                onPressed: () => _navigateToFamilyChat(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LargeActionButton(
                title: 'Medications',
                subtitle: 'Manage prescriptions',
                icon: Icons.medication,
                color: Colors.blue,
                onPressed: () => _navigateToMedicationReminders(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthStatus(BuildContext context, ElderProvider elderProvider) {
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
            'Health Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (elderProvider.currentMood != null) ...[
            Row(
              children: [
                const Icon(Icons.mood, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Current mood: ${elderProvider.currentMood}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (elderProvider.complianceStats != null) ...[
            _buildComplianceIndicator(elderProvider.complianceStats!),
          ] else ...[
            const Text(
              'Complete your first medication to see compliance stats',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceIndicator(MedicationComplianceStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('7-day compliance', style: TextStyle(fontSize: 16)),
            Text(
              '${(stats.overallComplianceRate * 100).toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stats.overallComplianceRate >= 0.8 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stats.overallComplianceRate,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            stats.overallComplianceRate >= 0.8 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Taken: ${stats.totalTaken}', style: const TextStyle(fontSize: 14)),
            Text('Missed: ${stats.totalMissed}', style: const TextStyle(fontSize: 14)),
            Text('Total: ${stats.totalScheduled}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildFamilyConnection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
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
              Icon(Icons.family_restroom, color: Colors.purple, size: 28),
              SizedBox(width: 12),
              Text(
                'Family Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Stay close with your loved ones',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToFamilyChat(),
            icon: const Icon(Icons.chat_bubble),
            label: const Text('Open Family Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAndSettings(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: WeatherWidget()),
      ],
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _takeMedication(BuildContext context, MedicationReminder reminder, ElderProvider elderProvider) async {
    final success = await elderProvider.recordMedicationTaken(
      reminderId: reminder.id,
      notes: 'Taken via dashboard',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${reminder.medicationName} marked as taken'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _snoozeMedication(BuildContext context, MedicationReminder reminder, ElderProvider elderProvider) async {
    final success = await elderProvider.snoozeMedicationReminder(
      reminderId: reminder.id,
      snoozeDuration: const Duration(minutes: 15),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ ${reminder.medicationName} snoozed for 15 minutes'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToMedicationReminders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MedicationReminderScreen(),
      ),
    );
  }

  void _navigateToDailyCheckin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyCheckinScreen(),
      ),
    );
  }

  void _navigateToEmergencyContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsScreen(),
      ),
    );
  }

  void _navigateToFamilyChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FamilyChatScreen(),
      ),
    );
  }

  Future<void> _handleVoiceCommand() async {
    // Implement voice command handling
    if (_isVoiceEnabled) {
      await _voiceService.startListening();
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Voice Navigation'),
              subtitle: const Text('Enable voice commands'),
              value: _isVoiceEnabled,
              onChanged: (value) {
                setState(() {
                  _isVoiceEnabled = value;
                });
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              subtitle: const Text('Improve text visibility'),
              value: _highContrastMode,
              onChanged: (value) {
                setState(() {
                  _highContrastMode = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}