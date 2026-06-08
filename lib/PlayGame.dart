import 'package:flutter/material.dart';

import 'CreateRoom.dart';
import 'joinroom.dart';
import 'api/game_api.dart';

class PlayGame extends StatefulWidget {
  const PlayGame({super.key});

  @override
  State<PlayGame> createState() => _PlayGameState();
}

class _PlayGameState extends State<PlayGame> {
  final TextEditingController playerNameController = TextEditingController();

  bool loading = false;

  // =====================
  // 🎮 CREATE GAME
  // =====================
  Future<void> handleCreateGame() async {
    final name = playerNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    try {
      setState(() => loading = true);

      final res = await GameService.createGame(name);

      debugPrint("CreateGame Response: $res");

      if (res == null) {
        throw Exception("Null response from API");
      }

      // ✅ RESPONSE VALUES
      final gameId = res["gameId"];
      final roomCode = res["roomCode"];

      final players = res["players"] ?? [];

      final playerId = players.isNotEmpty ? players[0]["playerId"] : null;

      final isHost = res["isHost"] ?? true;

      // ✅ VALIDATION
      if (gameId == null || roomCode == null || playerId == null) {
        throw Exception("Invalid API response");
      }

      // ✅ NAVIGATE
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateRoomScreen(
            gameId: gameId,
            roomCode: roomCode,
            playerId: playerId,
            players: players,
            isHost: isHost,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Create Game Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to create game: $e")));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: SafeArea(
        child: Stack(
          children: [
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

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,

                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Play with Friends",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: playerNameController,
                        maxLength: 20,
                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Enter your name",

                          hintStyle: const TextStyle(color: Colors.grey),

                          counterText: "",

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: Colors.white),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,

                            padding: const EdgeInsets.all(14),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          onPressed: loading ? null : handleCreateGame,

                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Create Game",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,

                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),

                            padding: const EdgeInsets.all(14),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinRoomScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            "Join Game",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
