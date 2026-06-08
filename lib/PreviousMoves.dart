import 'package:flutter/material.dart';
import 'package:codersbunny/api/cardApi.dart';

class PreviousMovesScreen extends StatefulWidget {
  final String playerId;
  final String gameId;

  const PreviousMovesScreen({
    super.key,
    required this.playerId,
    required this.gameId,
  });

  @override
  State<PreviousMovesScreen> createState() => _PreviousMovesScreenState();
}

class _PreviousMovesScreenState extends State<PreviousMovesScreen> {
  List<dynamic> moves = [];
  bool loading = true;

  final Map<String, String> CARD_IMAGES = {
    "forward": "assets/cards/forward.png",
    "right": "assets/cards/right.png",
    "left": "assets/cards/left.png",
    "jump": "assets/cards/jump.png",
    "loop2": "assets/cards/loop2.jpeg",
    "loop3": "assets/cards/loop3.jpeg",
    "loop4": "assets/cards/loop4.jpeg",
  };

  @override
  void initState() {
    super.initState();
    fetchPreviousMoves();
  }

  // =========================
  // FETCH MOVES (FIXED)
  // =========================
  Future<void> fetchPreviousMoves() async {
    setState(() => loading = true);

    try {
      final response = await CardApi.getPreviousMoves(
        widget.playerId,
        widget.gameId,
      );

      List<dynamic> data = [];

      if (response is List) {
        data = response;
      } else if (response is Map && response["data"] is List) {
        data = response["data"];
      }

      setState(() {
        moves = data.reversed.toList();
      });
    } catch (e) {
      debugPrint("Error fetching moves: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // =========================
  // UI CARD RENDER
  // =========================
  Widget buildMoveItem(int index, dynamic item) {
    final diceValue = item["diceValue"] ?? item["DiceValue"] ?? "-";
    final cards = item["cards"] ?? item["Cards"] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Turn #${index + 1}",
            style: const TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          Text(
            "🎲 Dice Value: $diceValue",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            children: (cards is List && cards.isNotEmpty)
                ? cards.map<Widget>((cardObj) {
                    final cardName =
                        (cardObj["cardName"] ?? cardObj["CardName"] ?? "")
                            .toString()
                            .toLowerCase()
                            .trim();

                    final imagePath = CARD_IMAGES[cardName];

                    return imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 60,
                            height: 80,
                            fit: BoxFit.contain,
                          )
                        : Container(
                            width: 60,
                            height: 80,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cardName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                          );
                  }).toList()
                : [
                    const Text(
                      "No Card Used",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Previous Moves",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : moves.isEmpty
                      ? const Center(
                          child: Text(
                            "No moves yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: moves.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: buildMoveItem(index, moves[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
