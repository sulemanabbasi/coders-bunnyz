import 'package:codersbunny/Result.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:signalr_core/signalr_core.dart';

import 'PreviousMoves.dart';
import 'select-card.dart';
import 'api/game_api.dart';

class GameBoard extends StatefulWidget {
  final int gameId;
  final int playerId;

  const GameBoard({super.key, required this.gameId, required this.playerId});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  static const int boardSize = 9;

  int? diceValue;
  int? moveId;
  int? currentPlayerId;
  int? currentPlayerOrder;

  List players = [];

  HubConnection? connection;
  late AnimationController scaleController;
  void openFunctionCards() {
    if (diceValue == null || moveId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Roll dice first")));
      return;
    }

    if (functionUsedCount >= maxFunctionUses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Function card sirf 5 dafa use ho sakta hai"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCardsScreen(
          gameId: widget.gameId,
          playerId: widget.playerId,
          moveId: moveId!,
          diceValue: 3, // Function me max 3 cards allow
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          functionUsedCount++;
        });
      }

      loadPlayers();
      loadCurrentTurn();
    });
  }

  @override
  void initState() {
    super.initState();

    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 1,
      upperBound: 1.3,
    );

    initSignalR();
    loadPlayers();
    loadCurrentTurn();
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }

  Future<void> loadPlayers() async {
    try {
      final data = await GameService.getPlayerPositions(
        widget.gameId.toString(),
      );

      if (!mounted) return;

      setState(() {
        players = data ?? [];
      });
    } catch (e) {
      debugPrint("Load players error: $e");
    }
  }

  Future<void> loadCurrentTurn() async {
    try {
      final data = await GameService.getCurrentTurn(widget.gameId.toString());

      if (!mounted || data == null) return;

      setState(() {
        currentPlayerId = data["currentPlayerId"];
        currentPlayerOrder = data["currentPlayerOrder"];
      });
    } catch (e) {
      debugPrint("Load current turn error: $e");
    }
  }

  Future<void> initSignalR() async {
    try {
      connection = await GameService.getConnection();

      connection!.off("playersUpdated");
      connection!.off("playerMoved");
      connection!.off("turnChanged");
      connection!.off("diceRolled");
      connection!.off("gameCompleted");
      connection!.off("GameEnded");

      connection!.on("playersUpdated", (data) {
        loadPlayers();
      });

      connection!.on("playerMoved", (data) {
        loadPlayers();
      });

      connection!.on("turnChanged", (data) {
        final d = data is List && data.isNotEmpty ? data.first : null;

        if (d is Map && mounted) {
          setState(() {
            currentPlayerId = int.tryParse(d["currentPlayerId"].toString());
            currentPlayerOrder = int.tryParse(
              d["currentPlayerOrder"].toString(),
            );
            diceValue = null;
            moveId = null;
          });
        }

        loadPlayers();
      });

      connection!.on("diceRolled", (data) {
        final d = data is List && data.isNotEmpty ? data.first : null;

        if (d is Map && mounted) {
          setState(() {
            diceValue = int.tryParse(d["diceValue"].toString());
            moveId = int.tryParse(d["moveId"].toString());
          });
        }
      });

      connection!.on("gameCompleted", (data) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MultiplayerResultScreen(gameId: widget.gameId),
          ),
        );
      });

      connection!.on("GameEnded", (data) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Game ended")));
      });
    } catch (e) {
      debugPrint("SignalR GameBoard Error: $e");
    }
  }

  Future<void> rollDice() async {
    if (currentPlayerId != null && currentPlayerId != widget.playerId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not your turn")));
      return;
    }

    try {
      await scaleController.forward();
      await scaleController.reverse();

      final response = await GameService.rollDice(
        widget.gameId.toString(),
        widget.playerId.toString(),
      );

      if (!mounted || response == null) return;

      setState(() {
        diceValue = response["diceValue"] ?? response["DiceValue"];
        moveId = response["moveId"] ?? response["MoveId"];
      });
    } catch (e) {
      debugPrint("RollDice error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Roll Dice Error: $e")));
      }
    }
  }

  void openCards() {
    if (diceValue == null || moveId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Roll dice first")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCardsScreen(
          gameId: widget.gameId,
          playerId: widget.playerId,
          moveId: moveId!,
          diceValue: diceValue!,
        ),
      ),
    ).then((_) {
      loadPlayers();
      loadCurrentTurn();
    });
  }

  int getPosition(dynamic p) {
    return p["currentPosition"] ??
        p["CurrentPosition"] ??
        p["position"] ??
        p["Position"] ??
        0;
  }

  int getPlayerOrder(dynamic p) {
    return p["playerOrder"] ?? p["PlayerOrder"] ?? 1;
  }

  int functionUsedCount = 0;
  static const int maxFunctionUses = 5;

  String getDirection(dynamic p) {
    return (p["direction"] ?? p["Direction"] ?? "right").toString();
  }

  String getPlayerAssetByOrder(int order) {
    final safeOrder = ((order - 1) % 4) + 1;
    return "assets/players/player$safeOrder.png";
  }

  double getRotation(String direction) {
    switch (direction.toLowerCase()) {
      case "right":
        return pi / 2;
      case "down":
        return pi;
      case "left":
        return -pi / 2;
      default:
        return 0;
    }
  }

  Widget getPlayerWidget(dynamic p) {
    final order = getPlayerOrder(p);
    final direction = getDirection(p);

    return Transform.rotate(
      angle: getRotation(direction),
      child: Image.asset(
        getPlayerAssetByOrder(order),
        width: 34,
        height: 34,
        fit: BoxFit.contain,
      ),
    );
  }

  Color getCellColor(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    if (row == 0) return col.isEven ? Colors.purple : Colors.purpleAccent;
    if (row == 8) return col.isEven ? Colors.green : Colors.greenAccent;
    if (col == 0) return row.isEven ? Colors.blue : Colors.blueAccent;
    if (col == 8) return row.isEven ? Colors.red : Colors.redAccent;

    return (row + col).isEven ? Colors.white : Colors.grey.shade300;
  }

  String getCenterDestinationAsset() {
    return "assets/destinations/school.png";
  }

  String getDestinationAssetBySlot(int slot) {
    switch (slot) {
      case 1:
        return "assets/destinations/park.png";
      case 2:
        return "assets/destinations/zoo.png";
      case 3:
        return "assets/destinations/school.png";
      case 4:
        return "assets/destinations/carnival.png";
      default:
        return "assets/destinations/school.png";
    }
  }

  Widget destinationImage(int slot) {
    return Image.asset(getDestinationAssetBySlot(slot), fit: BoxFit.contain);
  }

  Widget getCellAsset(int index) {
    // CENTER FIXED DESTINATION
    if (index == 40) {
      return Image.asset(getCenterDestinationAsset(), fit: BoxFit.contain);
    }

    // TOP PURPLE BORDER - 4 DESTINATIONS
    if (index == 1) return destinationImage(1);
    if (index == 3) return destinationImage(2);
    if (index == 5) return destinationImage(3);
    if (index == 7) return destinationImage(4);

    // RIGHT RED BORDER - 4 DESTINATIONS
    if (index == 17) return destinationImage(1);
    if (index == 35) return destinationImage(2);
    if (index == 53) return destinationImage(3);
    if (index == 71) return destinationImage(4);

    // BOTTOM GREEN BORDER - 4 DESTINATIONS
    if (index == 73) return destinationImage(1);
    if (index == 75) return destinationImage(2);
    if (index == 77) return destinationImage(3);
    if (index == 79) return destinationImage(4);

    // LEFT BLUE BORDER - 4 DESTINATIONS
    if (index == 9) return destinationImage(1);
    if (index == 27) return destinationImage(2);
    if (index == 45) return destinationImage(3);
    if (index == 63) return destinationImage(4);

    // 4 CARROTS ALWAYS SHOW
    if (index == 24) {
      return Image.asset("assets/items/greencarrot.jpg", fit: BoxFit.contain);
    }

    if (index == 60) {
      return Image.asset("assets/items/redcarrot.jpg", fit: BoxFit.contain);
    }

    if (index == 56) {
      return Image.asset("assets/items/purplecarrot.jpg", fit: BoxFit.contain);
    }

    if (index == 20) {
      return Image.asset("assets/items/bluecarrot.jpg", fit: BoxFit.contain);
    }

    // HURDLES
    if (index == 30 || index == 32) {
      return Image.asset("assets/hurdles/fence.png", fit: BoxFit.contain);
    }

    if (index == 48 || index == 50) {
      return Image.asset("assets/hurdles/puddle.png", fit: BoxFit.contain);
    }

    return const SizedBox();
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
        child: Column(
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Game Board",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      loadPlayers();
                      loadCurrentTurn();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.indigo.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentPlayerId == widget.playerId
                    ? "⏳ Your Turn"
                    : "⏳ Waiting for Player ${currentPlayerOrder ?? '-'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemBuilder: (context, index) {
                    final cellPlayers = players
                        .where((p) => getPosition(p) == index)
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: getCellColor(index),
                        border: Border.all(color: Colors.white10, width: 0.4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          getCellAsset(index),
                          ...cellPlayers.map((p) => getPlayerWidget(p)),
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
                  child: diceValue == null
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
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  bottomButton(
                    image: "assets/icons/bug.png",
                    title: "Bug",
                    onTap: () {},
                  ),
                  bottomButton(
                    image: "assets/icons/function.png",
                    title: "Function\n$functionUsedCount/5",
                    onTap: openFunctionCards,
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
