import 'package:codersbunny/sologame.dart';
import 'package:flutter/material.dart';
import 'api/game_api.dart';

import 'ResumeGame.dart';
import 'PlayGame.dart';
import 'LearnGame.dart';
import 'Setting.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<void> handleSoloGame() async {
    try {
      print("SOLO BUTTON PRESSED");

      final response = await GameService.soloGame("Easy", "Running", ["1"]);

      print("SOLO RESPONSE => $response");

      final gameId = response["gameId"] ?? response["GameId"];
      const playerId = 1;

      if (gameId == null) {
        throw Exception("GameId missing");
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SoloGameBoard(
            gameId: int.parse(gameId.toString()),
            playerId: playerId,
          ),
        ),
      );
    } catch (e) {
      print("Solo Game Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Solo Game Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 15,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingScreen()),
                  );
                },
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/bunny2.png',
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 80,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Select Your Mode",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 30),

                    buildButton(
                      icon: Icons.refresh,
                      text: "Resume Game",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResumeGame()),
                        );
                      },
                    ),

                    buildButton(
                      icon: Icons.people_outline,
                      text: "Play with Friends",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlayGame()),
                        );
                      },
                    ),

                    buildButton(
                      icon: Icons.person,
                      text: "Play Solo",
                      onTap: handleSoloGame,
                    ),

                    buildButton(
                      icon: Icons.school_outlined,
                      text: "Learn Coder Bunnyz",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LearnGame()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F6DFF),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
