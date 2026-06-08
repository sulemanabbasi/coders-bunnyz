import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Lobby.dart';

class CreateRoomScreen extends StatelessWidget {
  final String roomCode;
  final int gameId;
  final int playerId;
  final bool isHost;
  final List<dynamic> players;

  const CreateRoomScreen({
    super.key,
    required this.roomCode,
    required this.gameId,
    required this.playerId,
    required this.isHost,
    required this.players,
  });

  void copyRoomCode(BuildContext context) {
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Room code not available")));
      return;
    }

    Clipboard.setData(ClipboardData(text: roomCode));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Room ID copied")));
  }

  void goToLobby(BuildContext context) {
    if (roomCode.isEmpty || gameId == 0 || playerId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing game data")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          roomCode: roomCode,
          gameId: gameId,
          playerId: playerId,
          isHost: isHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),

            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Game Created",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Room ID",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          roomCode.isNotEmpty ? roomCode : "Loading...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(width: 10),

                        IconButton(
                          onPressed: () => copyRoomCode(context),
                          icon: const Icon(Icons.copy, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Share this Room ID with your friends",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Players: ${players.length}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => goToLobby(context),
                        child: const Text(
                          "Go to Lobby",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}
