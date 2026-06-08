import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'PreviousMoves.dart';
import 'package:codersbunny/api/cardApi.dart';
import 'package:codersbunny/api/apiclient.dart';

class SoloGameBoard extends StatefulWidget {
  final int gameId;
  final int playerId;

  const SoloGameBoard({
    super.key,
    required this.gameId,
    required this.playerId,
  });

  @override
  State<SoloGameBoard> createState() => _SoloGameBoardState();
}

class _SoloGameBoardState extends State<SoloGameBoard>
    with SingleTickerProviderStateMixin {
  static const int boardSize = 9;

  int diceValue = 0;
  int? currentMoveId;

  bool isMoving = false;
  bool loading = true;
  bool hasEatenCarrot = false;
  bool hasRolledDice = false;
  bool hasPlayedCards = true;
  bool bugUsed = false;

  int bunnyPosition = 64;
  String bunnyDirection = "up";

  final int carrotPosition = 60;
  final int destinationPosition = 40;

  String selectedPlayerAsset = "assets/players/player1.png";
  String selectedDestination = "assets/destinations/school.png";

  final Map<int, String> borderDestinationImages = {
    // TOP / Purple side
    1: "assets/destinations/school.png",
    3: "assets/destinations/park.png",
    5: "assets/destinations/zoo.png",
    7: "assets/destinations/carnival.png",

    // RIGHT / Red side
    17: "assets/destinations/carnival.png",
    35: "assets/destinations/school.png",
    53: "assets/destinations/park.png",
    71: "assets/destinations/zoo.png",

    // BOTTOM / Green side
    73: "assets/destinations/school.png",
    75: "assets/destinations/carnival.png",
    77: "assets/destinations/park.png",
    79: "assets/destinations/zoo.png",

    // LEFT / Blue side
    9: "assets/destinations/park.png",
    27: "assets/destinations/zoo.png",
    45: "assets/destinations/school.png",
    63: "assets/destinations/carnival.png",
  };

  final Map<int, Color> carrotCellColors = {
    24: Colors.green,
    60: Colors.red,
    56: Colors.purple,
    20: Colors.blue,
  };

  final List<int> carrotPositions = [24, 60, 56, 20];
  late AnimationController scaleController;

  List<Map<String, dynamic>> availableCards = [];

  final Map<String, String> cardImages = {
    "forward": "assets/cards/forward.png",
    "left": "assets/cards/left.png",
    "right": "assets/cards/right.png",
    "jump": "assets/cards/jump.png",
    "loop2": "assets/cards/loop2.jpeg",
    "loop3": "assets/cards/loop3.jpeg",
    "loop4": "assets/cards/loop4.jpeg",
    "function": "assets/icons/function.png",
  };

  Future<dynamic> rollDiceApi() async {
    return await ApiClient.request(
      "Game/RollDice",
      method: "POST",
      body: {"gameId": widget.gameId, "playerId": widget.playerId},
    );
  }

  Future<void> pauseGameApi() async {
    try {
      await ApiClient.request(
        "Game/PauseGame?gameId=${widget.gameId}",
        method: "POST",
      );
    } catch (_) {}
  }

  Future<void> loadSelectedPlayer() async {
    final prefs = await SharedPreferences.getInstance();

    final index = prefs.getInt("selectedAvatar") ?? 0;

    // selected destination
    final destination =
        prefs.getString("selectedDestination") ??
        "assets/destinations/school.png";

    if (!mounted) return;

    setState(() {
      selectedPlayerAsset = "assets/players/player${index + 1}.png";
      selectedDestination = destination;
    });
  }

  Future<void> saveLocalCarrotState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      "solo_carrot_${widget.gameId}_${widget.playerId}",
      hasEatenCarrot,
    );
  }

  Future<void> loadLocalCarrotState() async {
    final prefs = await SharedPreferences.getInstance();
    hasEatenCarrot =
        prefs.getBool("solo_carrot_${widget.gameId}_${widget.playerId}") ??
        false;
  }

  Future<void> clearLocalCarrotState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("solo_carrot_${widget.gameId}_${widget.playerId}");
  }

  Future<void> loadBoardFromDb() async {
    try {
      await loadLocalCarrotState();

      final positions = await CardApi.getPlayerPositions(
        widget.gameId.toString(),
      );

      if (positions is List) {
        final player = positions.firstWhere(
          (p) =>
              p["playerId"] == widget.playerId ||
              p["PlayerId"] == widget.playerId,
          orElse: () => null,
        );

        if (player != null) {
          bunnyPosition =
              player["currentPosition"] ??
              player["CurrentPosition"] ??
              bunnyPosition;

          bunnyDirection =
              (player["direction"] ?? player["Direction"] ?? bunnyDirection)
                  .toString()
                  .toLowerCase();

          final carrot = player["hasEatenCarrot"] ?? player["HasEatenCarrot"];

          if (carrot != null) {
            hasEatenCarrot = carrot == true;
          }
        }
      }

      await loadAvailableCards();
    } catch (e) {
      debugPrint("Load solo DB state error: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loadAvailableCards() async {
    try {
      final response = await CardApi.showAvailableCards(
        widget.playerId.toString(),
        widget.gameId.toString(),
      );

      if (response is List) {
        availableCards = response.map<Map<String, dynamic>>((card) {
          final name = (card["cardName"] ?? card["CardName"] ?? "").toString();
          final lower = name.toLowerCase().trim();

          return {
            "cardId": card["cardId"] ?? card["CardId"],
            "name": name,
            "image": cardImages[lower] ?? "assets/cards/forward.png",
            "quantity": card["quantity"] ?? card["Quantity"] ?? 0,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Load cards error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 1,
      upperBound: 1.25,
    );

    loadSelectedPlayer();
    loadBoardFromDb();
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }

  Future<void> rollDice() async {
    if (isMoving || loading) return;

    if (!hasPlayedCards) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pehle selected cards play karo")),
      );
      return;
    }

    try {
      await scaleController.forward();
      await scaleController.reverse();

      final response = await rollDiceApi();

      final moveId = response["moveId"] ?? response["MoveId"];
      final dice = response["diceValue"] ?? response["DiceValue"];

      if (moveId == null || dice == null) {
        throw Exception("MoveId ya DiceValue API se nahi aayi");
      }

      setState(() {
        currentMoveId = int.parse(moveId.toString());
        diceValue = int.parse(dice.toString());
        hasRolledDice = true;
        hasPlayedCards = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Dice error: $e")));
    }
  }

  Future<void> openCards() async {
    if (!hasRolledDice || diceValue == 0 || currentMoveId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pehle dice roll karo")));
      return;
    }

    await loadAvailableCards();

    final selectedCards = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => SoloSelectCardScreen(
          maxSelection: diceValue,
          cards: availableCards,
        ),
      ),
    );

    if (selectedCards == null || selectedCards.length != diceValue) return;

    await playCards(selectedCards);
  }

  Future<void> playCards(List<Map<String, dynamic>> selectedCards) async {
    if (currentMoveId == null) return;

    setState(() => isMoving = true);

    try {
      final cardIds = selectedCards
          .map((c) => c["cardId"])
          .where((id) => id != null)
          .toList();

      await CardApi.useCards(currentMoveId.toString(), cardIds);

      final moveResponse = await CardApi.movePlayer(currentMoveId.toString());

      final newPosition =
          moveResponse["newPosition"] ??
          moveResponse["NewPosition"] ??
          moveResponse["toX"] ??
          moveResponse["ToX"];

      final direction = moveResponse["direction"] ?? moveResponse["Direction"];

      final carrot =
          moveResponse["hasEatenCarrot"] ?? moveResponse["HasEatenCarrot"];

      final status =
          moveResponse["gameStatus"] ?? moveResponse["GameStatus"] ?? "";

      if (newPosition != null) {
        bunnyPosition = int.parse(newPosition.toString());
      }

      if (direction != null) {
        bunnyDirection = direction.toString().toLowerCase();
      }

      if (carrot != null) {
        hasEatenCarrot = carrot == true;
        await saveLocalCarrotState();
      }

      await loadAvailableCards();

      if (status.toString().toLowerCase() == "completed" ||
          bunnyPosition == destinationPosition) {
        await clearLocalCarrotState();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SoloResultScreen(
              gameId: widget.gameId,
              playerId: widget.playerId,
              totalMoves:
                  moveResponse["totalMoves"] ?? moveResponse["TotalMoves"] ?? 0,
              finishPosition:
                  moveResponse["finishPosition"] ??
                  moveResponse["FinishPosition"] ??
                  1,
              playerAsset: selectedPlayerAsset,
            ),
          ),
        );
        return;
      }

      setState(() {
        diceValue = 0;
        currentMoveId = null;
        hasRolledDice = false;
        hasPlayedCards = true;
        isMoving = false;
      });
    } catch (e) {
      setState(() => isMoving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Move error: $e")));
    }
  }

  Future<void> useBugUndo() async {
    if (bugUsed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bug already used")));
      return;
    }

    try {
      await ApiClient.request(
        "Game/UndoLastMove?gameId=${widget.gameId}&playerId=${widget.playerId}",
        method: "POST",
      );

      await loadBoardFromDb();

      setState(() {
        bugUsed = true;
        diceValue = 0;
        currentMoveId = null;
        hasRolledDice = false;
        hasPlayedCards = true;
        isMoving = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Undo error: $e")));
    }
  }

  Future<void> restartGame() async {
    try {
      await ApiClient.request(
        "Game/RestartGame?gameId=${widget.gameId}",
        method: "POST",
      );
      await clearLocalCarrotState();

      setState(() {
        bunnyPosition = 64;
        bunnyDirection = "up";
        diceValue = 0;
        currentMoveId = null;
        isMoving = false;
        hasEatenCarrot = false;
        hasRolledDice = false;
        hasPlayedCards = true;
        bugUsed = false;
      });

      await loadBoardFromDb();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Restart error: $e")));
    }
  }

  double getRotation() {
    if (bunnyDirection == "right") return pi / 2;
    if (bunnyDirection == "down") return pi;
    if (bunnyDirection == "left") return -pi / 2;
    return 0;
  }

  Color getCellColor(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    if (!hasEatenCarrot && carrotCellColors.containsKey(index)) {
      return carrotCellColors[index]!;
    }

    if (row == 0) return col.isEven ? Colors.purple : Colors.purpleAccent;
    if (row == 8) return col.isEven ? Colors.green : Colors.greenAccent;
    if (col == 0) return row.isEven ? Colors.blue : Colors.blueAccent;
    if (col == 8) return row.isEven ? Colors.red : Colors.redAccent;

    return (row + col).isEven ? Colors.white : Colors.grey.shade300;
  }

  Widget getCellAsset(int index) {
    if (index == destinationPosition) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(selectedDestination, fit: BoxFit.contain),
      );
    }

    if (borderDestinationImages.containsKey(index)) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(
          borderDestinationImages[index]!,
          fit: BoxFit.contain,
        ),
      );
    }

    if (!hasEatenCarrot && carrotPositions.contains(index)) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset("assets/items/carrot.png", fit: BoxFit.contain),
      );
    }

    if (index == 30 || index == 32) {
      return Image.asset("assets/hurdles/fence.png", fit: BoxFit.contain);
    }

    if (index == 48 || index == 50) {
      return Image.asset("assets/hurdles/puddle.png", fit: BoxFit.contain);
    }

    return const SizedBox();
  }

  Widget bunnyWidget() {
    return Transform.rotate(
      angle: getRotation(),
      child: Image.asset(
        selectedPlayerAsset,
        width: 38,
        height: 38,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget bottomButton({
    required String image,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFF4EA7B6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double boardPx = MediaQuery.of(context).size.width * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                children: [
                  Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1155A4),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await pauseGameApi();
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Solo Game",
                          style: TextStyle(color: Colors.white, fontSize: 28),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: restartGame,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMoving ? "Bunny Moving..." : "⏳ Player 1's Turn",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: boardPx,
                    height: boardPx,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 81,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9,
                            ),
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: getCellColor(index),
                              border: Border.all(
                                color: Colors.white10,
                                width: 0.4,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                getCellAsset(index),
                                if (bunnyPosition == index) bunnyWidget(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: rollDice,
                    child: ScaleTransition(
                      scale: scaleController,
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: diceValue == 0
                            ? Image.asset("assets/icons/dice.png")
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "$diceValue",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 18,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        bottomButton(
                          image: "assets/icons/bug.png",
                          title: "Bug",
                          onTap: useBugUndo,
                        ),
                        bottomButton(
                          image: "assets/icons/function.png",
                          title: "Function",
                          onTap: openCards,
                        ),
                        bottomButton(
                          image: "assets/icons/moves.png",
                          title: "Previous\nMoves",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PreviousMovesScreen(
                                  playerId: widget.playerId.toString(),
                                  gameId: widget.gameId.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                        bottomButton(
                          image: "assets/icons/card.png",
                          title: "Select Card",
                          onTap: openCards,
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

class SoloSelectCardScreen extends StatefulWidget {
  final int maxSelection;
  final List<Map<String, dynamic>> cards;

  const SoloSelectCardScreen({
    super.key,
    required this.maxSelection,
    required this.cards,
  });

  @override
  State<SoloSelectCardScreen> createState() => _SoloSelectCardScreenState();
}

class _SoloSelectCardScreenState extends State<SoloSelectCardScreen> {
  final List<Map<String, dynamic>> selectedCards = [];
  late List<Map<String, dynamic>> tempCards;

  @override
  void initState() {
    super.initState();
    tempCards = widget.cards.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void selectCard(Map<String, dynamic> card) {
    if (selectedCards.length >= widget.maxSelection) return;

    final quantity = int.tryParse(card["quantity"].toString()) ?? 0;
    if (quantity <= 0) return;

    setState(() {
      selectedCards.add(Map<String, dynamic>.from(card));
      card["quantity"] = quantity - 1;
    });
  }

  void removeSelectedCard(int index) {
    final removed = selectedCards[index];

    setState(() {
      selectedCards.removeAt(index);

      final original = tempCards.firstWhere(
        (c) => c["cardId"] == removed["cardId"],
      );

      final q = int.tryParse(original["quantity"].toString()) ?? 0;
      original["quantity"] = q + 1;
    });
  }

  void submitCards() {
    if (selectedCards.length != widget.maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Select exactly ${widget.maxSelection} card(s)"),
        ),
      );
      return;
    }

    Navigator.pop(context, selectedCards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1155A4),
        title: Text("Select ${widget.maxSelection} Card(s)"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            "Selected: ${selectedCards.length}/${widget.maxSelection}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: selectedCards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => removeSelectedCard(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}. ${selectedCards[index]["name"]}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: tempCards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final card = tempCards[index];
                final name = card["name"].toString();
                final image = card["image"].toString();
                final remaining =
                    int.tryParse(card["quantity"].toString()) ?? 0;

                return GestureDetector(
                  onTap: remaining <= 0 ? null : () => selectCard(card),
                  child: Container(
                    decoration: BoxDecoration(
                      color: remaining <= 0 ? Colors.grey : Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(image, height: 85),
                        const SizedBox(height: 8),
                        Text(name, style: const TextStyle(color: Colors.white)),
                        Text(
                          "Left: $remaining",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitCards,
                child: const Text("OK"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoloResultScreen extends StatelessWidget {
  final int gameId;
  final int playerId;
  final dynamic totalMoves;
  final dynamic finishPosition;
  final String playerAsset;

  const SoloResultScreen({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.totalMoves,
    required this.finishPosition,
    required this.playerAsset,
  });

  Widget resultBox(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
                "Bunny reached destination successfully",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 25),
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Image.asset(playerAsset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 28),
              resultBox("Game ID", "$gameId", Icons.videogame_asset),
              resultBox("Player ID", "$playerId", Icons.person),
              resultBox("Total Moves", "$totalMoves", Icons.directions_run),
              resultBox(
                "Finish Position",
                "$finishPosition",
                Icons.emoji_events,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
