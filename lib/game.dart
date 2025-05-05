import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const towers = ['Левая', 'Центральная', 'Правая'];
const minDisks = 3, maxDisks = 8;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _Game();
}

class _Game extends State<GameScreen> with TickerProviderStateMixin {
  int disks = 5, moves = 0, minMoves = 0;
  late List<List<int>> towers = [List.generate(disks, (i) => disks - i), [], []];
  int? selected, _dialogDisks, hintFrom, hintTo;
  final moveHistory = <Move>[];
  bool won = false;
  late AnimationController _hintAnimationController;
  late Animation<Color?> _hintColorAnimation;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  Set<String> unlockedAchievements = {};
  Set<String> completedChallenges = {};
  late List<Achievement> achievements;
  late List<Challenge> challenges;

  double get w => MediaQuery.of(context).size.width;
  double get base => min(w * 0.15, 120);
  double get minW => base * 0.4;
  double get h => 180;
  double get dh => min((h - 40) / (disks + 1), 28);

  void reset() => setState(() {
        towers = [List.generate(disks, (i) => disks - i), [], []];
        selected = null;
        moves = 0;
        won = false;
        minMoves = (1 << disks) - 1;
        moveHistory.clear();
        hintFrom = null;
        hintTo = null;

        _elapsed = Duration.zero;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            _elapsed += const Duration(milliseconds: 100);
          });
        });
      });

  bool valid(f, t) => !towers[f].isEmpty &&
      (towers[t].isEmpty || towers[f].last < (towers[t].lastOrNull ?? 0));

  void move(f, t) {
    if (!valid(f, t)) return;
    setState(() {
      final d = towers[f].removeLast();
      towers[t].add(d);
      moves++;
      moveHistory.add(Move(f, t, d));

      final wasWon = won;
      won = towers[2].length == disks;

      if (!wasWon && won) {
        _timer?.cancel();
        checkAchievements();
        checkChallenges();
      }

      hintFrom = null;
      hintTo = null;
    });
  }

  void undo() => setState(() {
        if (moveHistory.isNotEmpty) {
          final m = moveHistory.removeLast();
          final d = towers[m.toTower].removeLast();
          towers[m.fromTower].add(d);
          moves--;
          final wasWon = won;
          won = towers[2].length == disks;
          hintFrom = null;
          hintTo = null;
          if (wasWon && !won) {
            _timer?.cancel();
            _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
              setState(() {
                _elapsed += const Duration(milliseconds: 100);
              });
            });
          }
        }
      });

  void checkAchievements() {
    for (var achievement in achievements) {
      if (achievement.condition(disks, moves, _elapsed) &&
          !unlockedAchievements.contains(achievement.title)) {
        unlockedAchievements.add(achievement.title);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Достижение разблокировано: ${achievement.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void checkChallenges() {
    for (var challenge in challenges) {
      if (challenge.condition(disks, moves, _elapsed) &&
          !completedChallenges.contains(challenge.title)) {
        completedChallenges.add(challenge.title);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Испытание выполнено: ${challenge.title}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  List<(int, int)> getOptimalSolution() {
    List<(int, int)> solution = [];
    void hanoi(int n, int source, int target, int auxiliary) {
      if (n > 0) {
        hanoi(n - 1, source, auxiliary, target);
        solution.add((source, target));
        hanoi(n - 1, auxiliary, target, source);
      }
    }
    hanoi(disks, 0, 2, 1);
    return solution;
  }

  (int, int)? getHint() {
    if (won) return null;
    final optimalMoves = getOptimalSolution();
    if (moveHistory.isEmpty) {
      return optimalMoves.isNotEmpty ? optimalMoves[0] : null;
    }
    final lastMove = moveHistory.last;
    final lastMoveTuple = (lastMove.fromTower, lastMove.toTower);
    int index = optimalMoves.indexOf(lastMoveTuple);
    if (index >= 0 && index < optimalMoves.length - 1) {
      return optimalMoves[index + 1];
    }
    for (var move in optimalMoves) {
      if (valid(move.$1, move.$2)) {
        return move;
      }
    }
    return null;
  }

  void showHint() {
    final hint = getHint();
    if (hint != null) {
      setState(() {
        hintFrom = hint.$1;
        hintTo = hint.$2;
      });
      _hintAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _hintColorAnimation = ColorTween(
        begin: Colors.yellow.withOpacity(0.6),
        end: Colors.yellow.withOpacity(1.0),
      ).animate(CurvedAnimation(
        parent: _hintAnimationController,
        curve: Curves.linear,
      ));
      _hintAnimationController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            hintFrom = null;
            hintTo = null;
          });
          _hintAnimationController.stop();
          _hintAnimationController.dispose();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    reset();
    _initializeAchievements();
  }

  void _initializeAchievements() {
    achievements = [
      Achievement(
        'Мастер Ханоя I',
        'Решите 3 диска за минимальное количество ходов (7)',
        (d, m, t) => d == 3 && m == 7,
      ),
      Achievement(
        'Мастер Ханоя II',
        'Решите 5 дисков за минимальное количество ходов (31)',
        (d, m, t) => d == 5 && m == 31,
      ),
    ];

    challenges = [
      Challenge(
        'Скоростной решатель',
        'Решите 4 диска за 2 минуты',
        (d, m, t) => d == 4 && t.inMinutes < 2,
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_hintAnimationController.isAnimating) {
      _hintAnimationController.stop();
    }
    try {
      if (_hintAnimationController.status != AnimationStatus.dismissed) {
        _hintAnimationController.dispose();
      }
    } catch (e) {}
    super.dispose();
  }

  String formatTime(Duration d) {
    int minutes = d.inMinutes;
    int seconds = d.inSeconds % 60;
    int tenths = (d.inMilliseconds / 100).floor() % 10;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bw = base + 20;
    final sw = min(200.0, w * 0.3);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ханойские башни', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: colorScheme.primary,
        actions: [
          if (moveHistory.isNotEmpty)
            IconButton(
                icon: Icon(Icons.history, color: Colors.white),
                onPressed: () => showHistory(context)),
          IconButton(
              icon: Icon(Icons.lightbulb, color: Colors.yellowAccent),
              onPressed: won ? null : showHint),
          IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () => showSettings(context)),
          IconButton(
              icon: Icon(Icons.refresh, color: Colors.white), onPressed: reset),
          if (moveHistory.isNotEmpty)
            IconButton(
                icon: Icon(Icons.undo, color: Colors.white), onPressed: undo),
          IconButton(
              icon: Icon(Icons.star, color: Colors.white),
              onPressed: () => _showAchievements(context)),
          IconButton(
              icon: Icon(Icons.flag, color: Colors.white),
              onPressed: () => _showChallenges(context)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: sw,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  border: Border(
                    right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stat('Ходы', '$moves',
                            moves > minMoves ? Colors.orange : Colors.green),
                        Stat('Минимально', '$minMoves', Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stat('Время', formatTime(_elapsed), Colors.blueAccent),
                    if (won)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Победа!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Правила',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '1. Один диск за ход\n2. Нельзя класть больший на меньший',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      3,
                      (i) => GestureDetector(
                        onTap: () => tap(i),
                        child: Builder(
                          builder: (context) {
                            bool isHintFrom = hintFrom == i;
                            bool isHintTo = hintTo == i;
                            bool isHintActive = isHintFrom || isHintTo;
                            bool isSelected = selected == i;
                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: bw,
                                  height: h + 20,
                                  decoration: BoxDecoration(
                                    border: isHintActive
                                        ? Border.all(
                                            color: Colors.yellowAccent,
                                            width: 3,
                                          )
                                        : isSelected
                                            ? Border.all(
                                                color: Colors.blue.withOpacity(0.7),
                                                width: 2,
                                              )
                                            : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          width: 10,
                                          height: h,
                                          decoration: BoxDecoration(
                                            color: Colors.brown.withOpacity(0.8),
                                            borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          width: bw * 0.8,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.brown.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      ...towers[i].asMap().entries.map((e) =>
                                          Positioned(
                                            bottom: 10 + e.key * (dh + 2),
                                            child: Container(
                                              width: minW +
                                                  (base - minW) * (e.value / disks),
                                              height: dh,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colorScheme.primary.withOpacity(0.9),
                                                    colorScheme.secondary.withOpacity(0.7),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 3,
                                                    spreadRadius: 0.5,
                                                  )
                                                ],
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                if (isHintActive)
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _hintColorAnimation,
                                      builder: (_, __) {
                                        final color = _hintColorAnimation.value ??
                                            Colors.yellow;
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: color.withOpacity(0.8),
                                              width: 3,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSettings(BuildContext context) => showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (_, s) => AlertDialog(
            title: const Text('Настройки'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Количество дисков:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: disks > minDisks
                          ? () {
                              s(() => disks--);
                              reset();
                            }
                          : null,
                    ),
                    Text('$disks'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: disks < maxDisks
                          ? () {
                              s(() => disks++);
                              reset();
                            }
                          : null,
                    ),
                  ],
                ),
                const Text(
                  'Совет: Нажмите на башню для выбора, затем на другую башню для перемещения диска.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  reset();
                },
                child: const Text('Применить'),
              ),
            ],
          ),
        ),
      );

  void showHistory(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('История ходов (Всего: ${moveHistory.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: moveHistory.isEmpty
                ? const Text('Нет ходов', textAlign: TextAlign.center)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: moveHistory.length,
                    itemBuilder: (_, i) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.primaries[
                                moveHistory[i].disk % Colors.primaries.length],
                            child: Text(
                              '${moveHistory[i].disk}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(moveHistory[i].toReadableString()),
                          trailing: Text(
                            '#${i + 1}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );

  void _showAchievements(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Достижения'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              var achievement = achievements[index];
              bool unlocked = unlockedAchievements.contains(achievement.title);
              return ListTile(
                title: Text(achievement.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.description),
                    if (unlocked)
                      Text('Разблокировано', style: TextStyle(color: Colors.green)),
                  ],
                ),
                leading: Icon(
                  unlocked ? Icons.star : Icons.star_border,
                  color: unlocked ? Colors.yellow : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showChallenges(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Испытания'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              var challenge = challenges[index];
              bool completed = completedChallenges.contains(challenge.title);
              return ListTile(
                title: Text(challenge.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.description),
                    if (completed)
                      Text('Выполнено', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                leading: Icon(
                  completed ? Icons.flag : Icons.flag_outlined,
                  color: completed ? Colors.blue : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void tap(int t) => setState(() {
        if (won) return;
        if (selected == null) {
          if (towers[t].isNotEmpty) selected = t;
        } else {
          if (t != selected) move(selected!, t);
          selected = null;
        }
      });
}

class Achievement {
  final String title;
  final String description;
  final bool Function(int disks, int moves, Duration time) condition;

  Achievement(this.title, this.description, this.condition);
}

class Challenge {
  final String title;
  final String description;
  final bool Function(int disks, int moves, Duration time) condition;

  Challenge(this.title, this.description, this.condition);
}

class Move {
  final int fromTower, toTower, disk;
  Move(this.fromTower, this.toTower, this.disk);

  String toReadableString() =>
      'Диск $disk перемещен с ${towers[fromTower]} на ${towers[toTower]}';
}

class Stat extends StatelessWidget {
  final String title, value;
  final Color color;

  const Stat(this.title, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      );
}