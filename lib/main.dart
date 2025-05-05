import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainMenuScreen(),
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ханойские башни'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.4),
              theme.colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text('Начать игру', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.people, size: 28),
                  label: const Text('Авторы', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthorsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: theme.colorScheme.secondaryContainer.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthorsScreen extends StatelessWidget {
  const AuthorsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> authors = [
      {
        'name': 'Кондратюк Павел Андреевич',
        'role': 'Программист',
        'icon': Icons.code,
        'color': Colors.blue,
      },
      {
        'name': 'Кусков Александр Романович',
        'role': 'Создание презентации и предложение идей',
        'icon': Icons.lightbulb,
        'color': Colors.green,
      },
      {
        'name': 'Кучеренко Георгий Алексеевич',
        'role': 'Программист',
        'icon': Icons.code,
        'color': Colors.purple,
      },
      {
        'name': 'Гречушников Максим Александрович',
        'role': 'Дизайн',
        'icon': Icons.palette,
        'color': Colors.orange,
      },
      {
        'name': 'Чвалюк Иван Геннадьевич',
        'role': 'Студент, программист, сборка приложения',
        'icon': Icons.school,
        'color': Colors.teal,
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: authors.map((author) {
                return Card(
                  elevation: 6,
                  shadowColor: author['color']!.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: author['color']!.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: author['color']!.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        author['icon'],
                        color: author['color'],
                        size: 28,
                      ),
                    ),
                    title: Text(
                      author['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        author['role']!,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    tileColor: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
