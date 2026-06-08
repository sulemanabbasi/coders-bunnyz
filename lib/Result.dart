import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final List results;
  final String gameId;
  final String playerId;

  const ResultScreen({
    super.key,
    required this.results,
    required this.gameId,
    required this.playerId,
  });

  static const PLAYER_IMAGES = {
    1: "assets/players/player1.png",
    2: "assets/players/player2.png",
    3: "assets/players/player3.png",
    4: "assets/players/player4.png",
  };

  static const POSITION_LABELS = {
    1: "🥇 1st",
    2: "🥈 2nd",
    3: "🥉 3rd",
    4: "4th",
  };

  Map<String, dynamic>? getMyResult() {
    try {
      return results.firstWhere(
        (r) => r["playerId"] == playerId || r["PlayerId"] == playerId,
      );
    } catch (_) {
      return null;
    }
  }

  int getPlayerOrder(item) => item["playerOrder"] ?? item["PlayerOrder"] ?? 1;
  int getPosition(item) => item["position"] ?? item["Position"] ?? 0;
  String getRemarks(item) => item["remarks"] ?? item["Remarks"] ?? "";
  int getTotalMoves(item) => item["totalMoves"] ?? item["TotalMoves"] ?? 0;

  String getPlayerName(item) =>
      item["playerName"] ??
      item["PlayerName"] ??
      "Player ${getPlayerOrder(item)}";

  @override
  Widget build(BuildContext context) {
    final myResult = getMyResult();

    final sortedResults = [...results]
      ..sort((a, b) => (getPosition(a)).compareTo(getPosition(b)));

    int getMyPosition() => myResult != null ? getPosition(myResult) : 0;

    Widget buildRow(item) {
      final order = getPlayerOrder(item);
      final pos = getPosition(item);

      final isMe = item["playerId"] == playerId || item["PlayerId"] == playerId;

      final playerImg = PLAYER_IMAGES[order] ?? PLAYER_IMAGES[1]!;

      final posLabel = POSITION_LABELS[pos] ?? "#$pos";

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B245F),
          borderRadius: BorderRadius.circular(12),
          border: isMe ? Border.all(color: Colors.yellow, width: 2) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                posLabel,
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Image.asset(playerImg, width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? "You (${getPlayerName(item)})" : getPlayerName(item),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${getTotalMoves(item)} moves",
                    style: const TextStyle(
                      color: Color(0xFFBFC5FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              getRemarks(item),
              style: const TextStyle(
                color: Color(0xFFA5D6A7),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "Menu");
              },
            ),
          ),

          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF222A94),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF50C9F4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎉 Game Over!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (getMyPosition() == 1)
                    const Text(
                      "🏆 You Won!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (getMyPosition() > 1)
                    Text(
                      "You finished #${getMyPosition()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      "Game Completed!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 16),

                  sortedResults.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedResults.length,
                          itemBuilder: (context, index) {
                            return buildRow(sortedResults[index]);
                          },
                        )
                      : const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No results available",
                            style: TextStyle(color: Color(0xFFBFC5FF)),
                          ),
                        ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "Menu");
                    },
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        color: Color(0xFF222A94),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MultiplayerResultScreen extends StatelessWidget {
  final int gameId;

  const MultiplayerResultScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                "Game Complete!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "All players finished the game",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videogame_asset, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Game ID",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const Spacer(),
                    Text(
                      "$gameId",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1155A4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Back",
                    style: TextStyle(color: Colors.white, fontSize: 18),
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
