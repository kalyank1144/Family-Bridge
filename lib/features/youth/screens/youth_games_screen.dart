import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/games_provider.dart';

class YouthGamesScreen extends StatelessWidget {
  const YouthGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GamesProvider()..initMemory(),
      child: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Games', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: const TabBar(tabs: [Tab(text: 'Memory'), Tab(text: 'Trivia')]),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Moves: ${g.moves}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Matches: ${g.matches}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextButton(onPressed: () => context.read<GamesProvider>().initMemory(), child: const Text('Restart')),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: g.cards.length,
                    itemBuilder: (context, i) {
                      final c = g.cards[i];
                      return GestureDetector(
                        onTap: () => context.read<GamesProvider>().flip(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: c.matched || c.revealed ? const Color(0xFF2ED8C3) : Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: Icon(c.revealed || c.matched ? c.icon : Icons.help_outline, color: Colors.white, size: 32),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Score: ${g.triviaScore}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.currentTrivia.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      ...g.currentTrivia.options.asMap().entries.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ElevatedButton(
                              onPressed: () => context.read<GamesProvider>().answerTrivia(e.key),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: const Color(0xFF4DA3FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(e.value),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}