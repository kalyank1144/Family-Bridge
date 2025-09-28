import 'package:flutter/material.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/admin/subscription_management/services/admin_subscription_service.dart';

class AdminActionsScreen extends StatefulWidget {
  const AdminActionsScreen({super.key});

  @override
  State<AdminActionsScreen> createState() => _AdminActionsScreenState();
}

class _AdminActionsScreenState extends State<AdminActionsScreen> {
  final _svc = AdminSubscriptionService.instance;
  final _userIdCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '7');
  final _discountCodeCtrl = TextEditingController(text: 'WELCOME10');
  final _discountPctCtrl = TextEditingController(text: '10');
  final _amountCentsCtrl = TextEditingController(text: '999');
  final _messageCtrl = TextEditingController(text: 'Unlock unlimited family storage and premium features.');
  bool _loading = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _daysCtrl.dispose();
    _discountCodeCtrl.dispose();
    _discountPctCtrl.dispose();
    _amountCentsCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() fn) async {
    setState(() => _loading = true);
    try {
      await fn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action completed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Actions'), centerTitle: true),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('User', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(controller: _userIdCtrl, decoration: const InputDecoration(labelText: 'User ID', border: OutlineInputBorder())),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Extend Trial', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Extra days', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: () => _guard(() => _svc.extendTrial(userId: _userIdCtrl.text, extraDays: int.tryParse(_daysCtrl.text) ?? 0)), child: const Text('Extend')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Apply Discount', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _discountCodeCtrl, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _discountPctCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Percent', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: () => _guard(() => _svc.applyDiscount(userId: _userIdCtrl.text, code: _discountCodeCtrl.text, percent: int.tryParse(_discountPctCtrl.text) ?? 0)), child: const Text('Apply')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Send Upgrade Reminder', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(controller: _messageCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  Row(children: [
                    ElevatedButton(onPressed: () => _guard(() => _svc.sendUpgradeReminder(userId: _userIdCtrl.text, channel: 'email', message: _messageCtrl.text)), child: const Text('Email')),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => _guard(() => _svc.sendUpgradeReminder(userId: _userIdCtrl.text, channel: 'push', message: _messageCtrl.text)), child: const Text('Push')),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => _guard(() => _svc.sendUpgradeReminder(userId: _userIdCtrl.text, channel: 'sms', message: _messageCtrl.text)), child: const Text('SMS')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Refund', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _amountCentsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (cents)', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: () => _guard(() => _svc.issueRefund(userId: _userIdCtrl.text, cents: int.tryParse(_amountCentsCtrl.text) ?? 0)), child: const Text('Refund')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bulk Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    OutlinedButton(onPressed: () => _guard(() => _svc.bulkAction(filter: {'stage': 'final_week'}, action: 'send_final_week_reminders')), child: const Text('Final-week reminders')),
                    OutlinedButton(onPressed: () => _guard(() => _svc.bulkAction(filter: {'conversion_prob_over': 0.7}, action: 'offer_annual_discount', data: {'percent': 20})), child: const Text('Annual 20% offer')),
                    OutlinedButton(onPressed: () => _guard(() => _svc.bulkAction(filter: {'inactive_days': 7}, action: 're_engagement_push')), child: const Text('Re-engage inactive')),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
