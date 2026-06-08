import 'package:codersbunny/api/apiclient.dart';
import 'package:codersbunny/sologame.dart';
import 'package:flutter/material.dart';

import 'api/game_api.dart';

class ResumeGame extends StatefulWidget {
  const ResumeGame({super.key});

  @override
  State<ResumeGame> createState() => _ResumeGameState();
}

class _ResumeGameState extends State<ResumeGame> {
  List games = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPausedGames();
  }

  // =====================
  // 📥 LOAD PAUSED GAMES (FIXED)
  // =====================
  Future<void> loadPausedGames() async {
    try {
      final data = await GameService.getPausedGames();

      setState(() {
        games = (data is List) ? data : [];
      });
    } catch (error) {
      debugPrint("Error loading paused games: $error");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // =====================
  // ▶️ RESUME GAME (FIXED)
  // =====================
  Future<void> handleResumeGame(dynamic game) async {
    try {
      final gameId = game["gameId"];
      final playerId = game["playerId"] ?? 1;

      await ApiClient.request("Game/ResumeGame?gameId=$gameId", method: "POST");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SoloGameBoard(
            gameId: int.parse(gameId.toString()),
            playerId: int.parse(playerId.toString()),
          ),
        ),
      );
    } catch (error) {
      debugPrint("Resume Game Error: $error");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to resume game: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),

      body: SafeArea(
        child: Stack(
          children: [
            // BACK BUTTON
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 100, left: 20, right: 20),

              child: Column(
                children: [
                  const Text(
                    "Paused Games",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LOADING
                  if (loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  // EMPTY
                  else if (games.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No Paused Games Found",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  // LIST
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];

                          return GestureDetector(
                            onTap: () => handleResumeGame(game),

                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Center(
                                child: Text(
                                  "Room Code: ${game["roomCode"] ?? 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
