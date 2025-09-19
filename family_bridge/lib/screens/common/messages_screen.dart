import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../middleware/security_middleware.dart';
import '../../data/repositories/messages_repository.dart';

class MessagesScreen extends StatefulWidget {
  final String channelId;
  const MessagesScreen({super.key, required this.channelId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  late final MessagesRepository _repo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _repo = MessagesRepository(Supabase.instance.client);
  }

  Future<void> _send() async {
    final ctx = SecurityContext.of(context)!;
    final text = ctx.securityMiddleware.sanitizeInput({'m': _controller.text})['m'];
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    await ctx.securityMiddleware.secureApiCall(
      user: ctx.currentUser,
      resource: 'messages',
      action: 'create',
      apiCall: () async {
        await _repo.send(widget.channelId, ctx.currentUser.id, text);
        return true;
      },
    );
    _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = SecurityContext.of(context)!;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.watchChannel(widget.channelId, ctx.currentUser.id),
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? const [];
              return ListView.builder(
                reverse: true,
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  return ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(m['sender_id'] ?? ''),
                    subtitle: Text(m['content'] ?? ''),
                    trailing: Text(
                      m['created_at'] != null
                          ? TimeOfDay.fromDateTime(DateTime.parse(m['created_at'])).format(context)
                          : '',
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
