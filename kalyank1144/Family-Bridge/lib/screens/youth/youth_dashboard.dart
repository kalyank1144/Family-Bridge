import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../common/messages_screen.dart';
import '../../middleware/security_middleware.dart';
import '../../data/repositories/tasks_repository.dart';

class YouthDashboard extends StatefulWidget {
  const YouthDashboard({super.key});

  @override
  State<YouthDashboard> createState() => _YouthDashboardState();
}

class _YouthDashboardState extends State<YouthDashboard> {
  int _tab = 0;
  late final TasksRepository _tasksRepo;
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tasksRepo = TasksRepository(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Youth Home')),
      body: _buildTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.library_books), label: 'Stories'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _tasksTab();
      case 1:
        return _storiesTab();
      case 2:
        return const MessagesScreen(channelId: 'youth');
      default:
        return const SizedBox();
    }
  }

  Widget _tasksTab() {
    final ctx = SecurityContext.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text("Today's Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _tasksRepo.watchMyTasks(ctx.currentUser.id),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            return Column(
              children: [
                for (final t in items)
                  CheckboxListTile(
                    value: (t['done'] ?? false) as bool,
                    onChanged: (v) async {
                      await ctx.securityMiddleware.secureApiCall(
                        user: ctx.currentUser,
                        resource: 'tasks',
                        action: 'update',
                        apiCall: () async {
                          await _tasksRepo.toggle(t['id'] as String, v ?? false);
                          return true;
                        },
                      );
                    },
                    title: Text(t['title'] ?? ''),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          hintText: 'Add a task',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final text = _taskController.text.trim();
                        if (text.isEmpty) return;
                        await ctx.securityMiddleware.secureApiCall(
                          user: ctx.currentUser,
                          resource: 'tasks',
                          action: 'create',
                          apiCall: () async {
                            await _tasksRepo.add(ctx.currentUser.id, text);
                            return true;
                          },
                        );
                        _taskController.clear();
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _storiesTab() {
    final stories = [
      {'title': 'Healthy Eating', 'desc': 'Learn about fruits and veggies'},
      {'title': 'Exercise Fun', 'desc': 'Move with friends'},
      {'title': 'Sleep Time', 'desc': 'Why sleep matters'},
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final s = stories[i];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, color: Colors.deepPurple),
                  const Spacer(),
                  Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(s['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
