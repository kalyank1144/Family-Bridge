import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/family_data_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/appointments_provider.dart';
import '../widgets/family_member_card.dart';
import '../widgets/alert_panel.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/activity_timeline.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final familyProvider = context.read<FamilyDataProvider>();
    final alertProvider = context.read<AlertProvider>();
    final appointmentsProvider = context.read<AppointmentsProvider>();
    
    await Future.wait([
      familyProvider.refresh(),
      alertProvider.refresh(),
      appointmentsProvider.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAlertSection(context),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildFamilyMembersSection(context),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildQuickActionsSection(context),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildRecentActivitySection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final unreadCount = alertProvider.unreadCount;
    
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(FeatherIcons.menu, color: AppTheme.textPrimary),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: Text(
        'Family Care Dashboard',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(FeatherIcons.bell, color: AppTheme.textPrimary),
              onPressed: () => context.push('/caregiver/alerts'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAlertSection(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final criticalAlerts = alertProvider.criticalAlerts;
    final highAlerts = alertProvider.highPriorityAlerts;
    
    if (criticalAlerts.isEmpty && highAlerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push('/caregiver/alerts'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        AlertPanel(alerts: [...criticalAlerts, ...highAlerts].take(3).toList()),
      ],
    );
  }

  Widget _buildFamilyMembersSection(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Member Status',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (familyProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (familyProvider.error != null)
          Center(
            child: Text(
              'Error loading family members',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: familyProvider.familyMembers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final member = familyProvider.familyMembers[index];
                return FamilyMemberCard(
                  member: member,
                  onTap: () => context.push('/caregiver/member/${member.id}'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.heart,
                label: 'Health\nMonitoring',
                color: AppTheme.healthGreen,
                onTap: () {
                  final familyProvider = context.read<FamilyDataProvider>();
                  if (familyProvider.familyMembers.isNotEmpty) {
                    context.push('/caregiver/health-monitoring/${familyProvider.familyMembers.first.id}');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.calendar,
                label: 'Appointments',
                color: AppTheme.infoColor,
                onTap: () => context.push('/caregiver/appointments'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.checkSquare,
                label: 'Tasks',
                color: AppTheme.warningColor,
                onTap: () {
                  // Navigate to tasks screen
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.messageSquare,
                label: 'Messages',
                color: AppTheme.primaryColor,
                onTap: () {
                  // Navigate to messages screen
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: ActivityTimeline(
              familyMembers: familyProvider.familyMembers,
              appointments: appointmentsProvider.todayAppointments,
            ),
          ),
        ),
      ],
    );
  }
}