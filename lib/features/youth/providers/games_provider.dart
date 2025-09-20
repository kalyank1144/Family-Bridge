import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/gamification_service.dart';

class GamesProvider extends ChangeNotifier {
  final GamificationService _gamification = GamificationService();

  List<_CardItem> _cards = [];
  bool _lock = false;
  _CardItem? _first;
  int _moves = 0;
  int _matches = 0;

  int _triviaIndex = 0;
  int _triviaScore = 0;

  List<_Trivia> _trivia = [
    _Trivia('Where did Grandma grow up?', ['Boston', 'Chicago', 'Dallas', 'Miami'], 1),
    _Trivia('What is Grandpa\'s favorite hobby?', ['Fishing', 'Painting', 'Gardening', 'Chess'], 0),
    _Trivia('What year did Mom and Dad meet?', ['2005', '2008', '2010', '2012'], 2),
  ];

  List<_CardItem> get cards => _cards;
  int get moves => _moves;
  int get matches => _matches;

  _Trivia get currentTrivia => _trivia[_triviaIndex % _trivia.length];
  int get triviaScore => _triviaScore;

  void initMemory() {
    final icons = [Icons.star, Icons.favorite, Icons.cake, Icons.home, Icons.pets, Icons.camera];
    final list = [...icons, ...icons].map((e) => _CardItem(icon: e)).toList();
    list.shuffle(Random());
    _cards = list;
    _moves = 0;
    _matches = 0;
    _first = null;
    _lock = false;
    notifyListeners();
  }

  Future<void> flip(int index) async {
    if (_lock || _cards[index].matched || _cards[index].revealed) return;
    _cards[index] = _cards[index].copyWith(revealed: true);
    notifyListeners();
    if (_first == null) {
      _first = _cards[index].copyWith(index: index);
      return;
    }
    _moves++;
    _lock = true;
    final prev = _first!;
    if (_cards[index].icon == prev.icon) {
      _cards[index] = _cards[index].copyWith(matched: true);
      _cards[prev.index!] = _cards[prev.index!].copyWith(matched: true);
      _matches++;
      await _gamification.addPoints(10);
      if (_matches == _cards.length ~/ 2) {
        await _gamification.unlockAchievement('memory_master');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _cards[index] = _cards[index].copyWith(revealed: false);
      _cards[prev.index!] = _cards[prev.index!].copyWith(revealed: false);
    }
    _first = null;
    _lock = false;
    notifyListeners();
  }

  void resetTrivia() {
    _triviaIndex = 0;
    _triviaScore = 0;
    notifyListeners();
  }

  Future<void> answerTrivia(int choice) async {
    final q = currentTrivia;
    if (choice == q.correct) {
      _triviaScore += 10;
      await _gamification.addPoints(10);
      if (_triviaIndex == _trivia.length - 1) {
        await _gamification.unlockAchievement('family_trivia');
      }
    }
    _triviaIndex = (_triviaIndex + 1) % _trivia.length;
    notifyListeners();
  }

  void nextTrivia() {
    _triviaIndex = (_triviaIndex + 1) % _trivia.length;
    notifyListeners();
  }
}

class _CardItem {
  final IconData icon;
  final bool revealed;
  final bool matched;
  final int? index;
  _CardItem({required this.icon, this.revealed = false, this.matched = false, this.index});
  _CardItem copyWith({IconData? icon, bool? revealed, bool? matched, int? index}) => _CardItem(icon: icon ?? this.icon, revealed: revealed ?? this.revealed, matched: matched ?? this.matched, index: index ?? this.index);
}

class _Trivia {
  final String question;
  final List<String> options;
  final int correct;
  _Trivia(this.question, this.options, this.correct);
}