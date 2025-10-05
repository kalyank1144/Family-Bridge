import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/services/care_coordination_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';

class CarePlanScreen extends StatefulWidget {
  const CarePlanScreen({super.key});

  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _careService = CareCoordinationService();
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final familyProvider = context.read<FamilyDataProvider>();
    if (familyProvider.familyMembers.isNotEmpty) {
      _selectedMemberId = familyProvider.familyMembers.first.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _careService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final members = familyProvider.familyMembers;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Care Plans & Tasks'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Care Plans'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCarePlansTab(context, members),
          _buildTasksTab(context, members),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(FeatherIcons.plus),
        label: Text(_tabController.index == 0 ? 'New Plan' : 'New Task'),
      ),
    );
  }

  Widget _buildCarePlansTab(BuildContext context, List members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _memberSelector(context, members),
          const SizedBox(height: AppTheme.spacingLg),
          if (_selectedMemberId != null) ...[
            Text('Care Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            ..._careService.getCarePlans(_selectedMemberId!).map((plan) => _planCard(context, plan)).toList(),
            if (_careService.getCarePlans(_selectedMemberId!).isEmpty)
              _emptyState(context, 'No care plans created', 'Create your first care plan to organize member care'),
          ],
        ],
      ),
    );
  }

  Widget _buildTasksTab(BuildContext context, List members) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _memberSelector(context, members),
          const SizedBox(height: AppTheme.spacingLg),
          if (_selectedMemberId != null) ...[
            Text('Active Tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            StreamBuilder<List<CareTask>>(
              stream: _careService.taskStream,
              builder: (context, snapshot) {
                final tasks = _careService.getTasksForMember(_selectedMemberId!);
                if (tasks.isEmpty) {
                  return _emptyState(context, 'No tasks assigned', 'Create tasks to coordinate care activities');
                }
                return Column(
                  children: tasks.map((task) => _taskCard(context, task)).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberSelector(BuildContext context, List members) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Family Member', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              children: members.map<Widget>((member) {
                final selected = member.id == _selectedMemberId;
                return ChoiceChip(
                  label: Text(member.name),
                  selected: selected,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _selectedMemberId = member.id;
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: selected ? AppTheme.primaryColor : AppTheme.textPrimary),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(BuildContext context, CarePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: const Icon(FeatherIcons.clipboard, color: AppTheme.primaryColor),
        ),
        title: Text(plan.title),
        subtitle: Text('Created ${_formatDate(plan.createdAt)} • Version ${plan.version}'),
        trailing: const Icon(FeatherIcons.chevronRight),
        onTap: () => _showPlanDetails(context, plan),
      ),
    );
  }

  Widget _taskCard(BuildContext context, CareTask task) {
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !task.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (val) => _careService.toggleComplete(task.id),
          activeColor: AppTheme.successColor,
        ),
        title: Text(
          task.title,
          style: task.completed 
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary)
              : null,
        ),
        subtitle: Text(
          'Due ${_formatDate(task.dueDate)}',
          style: TextStyle(
            color: isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isOverdue 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Overdue', style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : const Icon(FeatherIcons.chevronRight),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(FeatherIcons.clipboard, size: 48, color: AppTheme.textTertiary),
            const SizedBox(height: AppTheme.spacingMd),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textTertiary)),
            const SizedBox(height: AppTheme.spacingSm),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tabController.index == 0 ? 'Create Care Plan' : 'Create Task'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: _tabController.index == 0 ? 'Plan Title' : 'Task Title',
            hintText: _tabController.index == 0 ? 'e.g., Weekly Medication Review' : 'e.g., Check blood pressure',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty && _selectedMemberId != null) {
                if (_tabController.index == 0) {
                  _careService.createPlan(memberId: _selectedMemberId!, title: titleController.text.trim());
                } else {
                  _careService.addTask(memberId: _selectedMemberId!, title: titleController.text.trim());
                }
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlanDetails(BuildContext context, CarePlan plan) {
    // Show plan details - placeholder for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan details for "${plan.title}" would open here')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}