import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SnakeGame());
}

class SnakeGame extends StatelessWidget {
  const SnakeGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  static const int rowCount = 20;
  static const int colCount = 20;
  static const Duration tickRate = Duration(milliseconds: 200);
  List<Offset> snake = [const Offset(10, 10)];
  Offset food = const Offset(5, 5);
  String direction = 'right';
  int score = 0;
  int maxScore = 0;
  Timer? gameLoop;

  @override
  void initState() {
    super.initState();
    loadMaxScore();
    startGame();
  }

  void startGame() {
    gameLoop = Timer.periodic(tickRate, (timer) {
      setState(() {
        moveSnake();
      });
    });
  }

  void moveSnake() {
    Offset newHead = snake.first;
    switch (direction) {
      case 'up':
        newHead = Offset(newHead.dx, newHead.dy - 1);
        break;
      case 'down':
        newHead = Offset(newHead.dx, newHead.dy + 1);
        break;
      case 'left':
        newHead = Offset(newHead.dx - 1, newHead.dy);
        break;
      case 'right':
        newHead = Offset(newHead.dx + 1, newHead.dy);
        break;
    }

    if (newHead.dx < 0 || newHead.dy < 0 || newHead.dx >= colCount || newHead.dy >= rowCount || snake.contains(newHead)) {
      gameLoop?.cancel();
      showGameOverDialog();
      return;
    }

    snake.insert(0, newHead);
    if (newHead == food) {
      score++;
      generateNewFood();
      checkAndSaveMaxScore();
    } else {
      snake.removeLast();
    }
  }

  void generateNewFood() {
    final random = Random();
    food = Offset(random.nextInt(colCount).toDouble(), random.nextInt(rowCount).toDouble());
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your Score: $score\nTry again!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              restartGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    setState(() {
      snake = [const Offset(10, 10)];
      direction = 'right';
      score = 0;
      generateNewFood();
      startGame();
    });
  }

  void saveMaxScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxScore', score);
  }

  Future<int> loadMaxScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      maxScore = prefs.getInt('maxScore') ?? 0;
    });
    return maxScore;
  }

  void checkAndSaveMaxScore() async {
    if (score > maxScore) {
      saveMaxScore(score);
      setState(() {
        maxScore = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  GridView.builder(
                    itemCount: rowCount * colCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: colCount),
                    itemBuilder: (context, index) {
                      int x = index % colCount;
                      int y = index ~/ colCount;
                      Offset position = Offset(x.toDouble(), y.toDouble());
                      Color color = const Color.fromARGB(255, 15, 248, 112);
                      if (snake.contains(position)) {
                        color = Colors.green;
                      } else if (position == food) {
                        color = Colors.red;
                      }
                      return Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 50,
            bottom: 100,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() { if (direction != 'down') direction = 'up'; }),
                  child: const Icon(Icons.arrow_upward),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() { if (direction != 'right') direction = 'left'; }),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => setState(() { if (direction != 'left') direction = 'right'; }),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => setState(() { if (direction != 'up') direction = 'down'; }),
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
