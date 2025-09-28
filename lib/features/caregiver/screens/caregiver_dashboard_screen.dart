import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/mixins/hipaa_compliance_mixin.dart';
import 'package:family_bridge/core/services/access_control_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/alert.dart';
import 'package:family_bridge/features/caregiver/providers/alert_provider.dart';
import 'package:family_bridge/features/caregiver/providers/appointments_provider.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';
import 'package:family_bridge/features/caregiver/widgets/activity_timeline.dart';
import 'package:family_bridge/features/caregiver/widgets/alert_panel.dart';
import 'package:family_bridge/features/caregiver/widgets/family_member_overview_card.dart';
import 'package:family_bridge/features/caregiver/widgets/quick_action_button.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> with HipaaComplianceMixin {
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
      title: Row(
        children: [
          Text(
            'Family Care Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(width: 12),
          buildComplianceStatusIndicator(),
        ],
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
        if (hasPermission(Permission.manageCompliance)) ...[
          IconButton(
            icon: const Icon(FeatherIcons.shield, color: AppTheme.textPrimary),
            onPressed: () => context.push('/admin'),
            tooltip: 'HIPAA Compliance',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAlertSection(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = alertProvider.alerts;

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final critical = alerts.where((a) => a.priority == AlertPriority.critical).length;
    final high = alerts.where((a) => a.priority == AlertPriority.high).length;
    final medium = alerts.where((a) => a.priority == AlertPriority.medium).length;
    final low = alerts.where((a) => a.priority == AlertPriority.low).length;

    final ordered = [
      ...alerts.where((a) => a.priority == AlertPriority.critical),
      ...alerts.where((a) => a.priority == AlertPriority.high),
      ...alerts.where((a) => a.priority == AlertPriority.medium),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Priority Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push('/caregiver/alerts'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _alertChip(context, 'Critical', critical, AppTheme.healthRed),
            _alertChip(context, 'High', high, const Color(0xFFFC8C03)),
            _alertChip(context, 'Medium', medium, AppTheme.warningColor),
            _alertChip(context, 'Low', low, AppTheme.infoColor),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        AlertPanel(alerts: ordered.take(3).toList()),
      ],
    );
  }

  Widget _buildFamilyMembersSection(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Members',
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
        else ...[
          ...familyProvider.familyMembers.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: FamilyMemberOverviewCard(
                  member: member,
                  onViewDetails: () => context.push('/caregiver/member/${member.id}'),
                  onMonitor: () => context.push('/caregiver/health-monitoring/${member.id}'),
                ),
              )),
        ],
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
                icon: FeatherIcons.activity,
                label: 'Advanced\nMonitoring',
                color: AppTheme.healthGreen,
                onTap: () => context.push('/caregiver/advanced-monitoring'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.clipboard,
                label: 'Care\nPlans',
                color: AppTheme.warningColor,
                onTap: () => context.push('/caregiver/care-plan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.fileText,
                label: 'Reports',
                color: AppTheme.infoColor,
                onTap: () => context.push('/caregiver/professional-reports'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: FeatherIcons.calendar,
                label: 'Appointments',
                color: AppTheme.primaryColor,
                onTap: () => context.push('/caregiver/appointments'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _alertChip(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          Text('$count', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
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