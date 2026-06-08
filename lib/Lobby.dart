import 'package:codersbunny/gameboard.dart';
import 'package:flutter/material.dart';
import 'api/game_api.dart';
import 'package:signalr_core/signalr_core.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final int gameId;
  final int playerId;
  final bool isHost;
  final List? initialPlayers;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.gameId,
    required this.playerId,
    required this.isHost,
    this.initialPlayers,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  List players = [];
  bool loading = false;
  bool joined = false;
  bool navigated = false;

  HubConnection? connection;

  @override
  void initState() {
    super.initState();
    players = widget.initialPlayers ?? [];
    initSignalR();
  }

  Future<void> initSignalR() async {
    try {
      connection = await GameService.getConnection();

      connection!.off("playersUpdated");
      connection!.off("PlayerJoined");
      connection!.off("gameStarted");

      connection!.on("playersUpdated", (data) {
        if (!mounted) return;

        final list = data is List && data.isNotEmpty && data.first is List
            ? data.first as List
            : data is List
            ? data
            : [];

        setState(() {
          players = list;
        });
      });

      connection!.on("PlayerJoined", (data) {
        debugPrint("PlayerJoined event: $data");
      });

      connection!.on("gameStarted", (data) {
        debugPrint("gameStarted event: $data");

        final d = data is List && data.isNotEmpty ? data.first : null;

        final int newGameId = d is Map && d["gameId"] != null
            ? int.tryParse(d["gameId"].toString()) ?? widget.gameId
            : widget.gameId;

        goToGame(newGameId);
      });

      if (!joined) {
        await connection!.invoke("JoinRoom", args: [widget.roomCode]);
        joined = true;
        debugPrint("Joined SignalR room: ${widget.roomCode}");
      }
    } catch (e) {
      debugPrint("Lobby Error: $e");
    }
  }

  void goToGame(int gameId) {
    if (!mounted || navigated) return;

    navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameBoard(gameId: gameId, playerId: widget.playerId),
      ),
    );
  }

  Future<void> startGame() async {
    try {
      setState(() => loading = true);

      final response = await GameService.startGame(widget.roomCode);

      debugPrint("StartGame response: $response");

      final int newGameId = response != null && response["gameId"] != null
          ? int.tryParse(response["gameId"].toString()) ?? widget.gameId
          : widget.gameId;

      goToGame(newGameId);
    } catch (e) {
      debugPrint("Start Game Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Start Game Error: $e")));
      }
    } finally {
      if (mounted && !navigated) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    // Important: yahan connection stop mat karo.
    // GameBoard ko same SignalR connection chahiye hoti hai.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                Column(
                  children: [
                    const Text(
                      "Lobby",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Room: ${widget.roomCode}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 30),

            Expanded(
              child: players.isEmpty
                  ? const Center(
                      child: Text(
                        "Waiting for players...",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      itemCount: players.length,
                      itemBuilder: (_, i) {
                        final p = players[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17138A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/players/player1.png",
                                width: 34,
                                height: 34,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                p["name"]?.toString() ?? "Player",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: widget.isHost
                  ? ElevatedButton(
                      onPressed: loading ? null : startGame,
                      child: Text(loading ? "Starting..." : "Start Game"),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17138A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "⏳ Waiting for host to start...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
