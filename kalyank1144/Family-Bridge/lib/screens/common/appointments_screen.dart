import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../middleware/security_middleware.dart';
import '../../data/repositories/appointments_repository.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late final AppointmentsRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = AppointmentsRepository(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = SecurityContext.of(context)!;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.watchMyAppointments(ctx.currentUser.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(a['title'] ?? ''),
                subtitle: Text('${a['location'] ?? ''} • ${a['time'] ?? ''}'),
                trailing: FilledButton(
                  onPressed: () async {
                    await ctx.securityMiddleware.secureApiCall(
                      user: ctx.currentUser,
                      resource: 'appointments',
                      action: 'read',
                      apiCall: () async => true,
                    );
                  },
                  child: const Text('Details'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
