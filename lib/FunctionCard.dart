import 'package:flutter/material.dart';
import 'package:codersbunny/api/cardApi.dart';

class FunctionCard extends StatefulWidget {
  const FunctionCard({super.key});

  @override
  State<FunctionCard> createState() => _FunctionCardState();
}

class _FunctionCardState extends State<FunctionCard> {
  String? gameId;
  String? playerId;
  String? moveId;

  bool isMultiplayer = false;
  dynamic playerOrder;

  List<dynamic> cards = [];
  List<dynamic> selectedCards = [];

  bool isFunctionSaved = false;
  bool loading = false;

  final Map<String, String> cardImages = {
    "forward": "assets/cards/forward.png",
    "right": "assets/cards/right.png",
    "left": "assets/cards/left.png",
    "jump": "assets/cards/jump.png",
    "loop2": "assets/cards/loop2.jpeg",
    "loop3": "assets/cards/loop3.jpeg",
    "loop4": "assets/cards/loop4.jpeg",
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    gameId = args?['gameId'];
    playerId = args?['playerId'];
    moveId = args?['moveId'];
    isMultiplayer = args?['isMultiplayer'] ?? false;
    playerOrder = args?['playerOrder'];

    fetchCards();
  }

  // =========================
  // HELPERS
  // =========================

  String normalize(String? name) {
    if (name == null) return "";
    return name.toLowerCase().trim();
  }

  dynamic getCardId(dynamic card) {
    return card["cardId"] ?? card["CardId"] ?? card["id"];
  }

  int getCardQty(dynamic card) {
    return card["quantity"] ?? card["Quantity"] ?? 0;
  }

  String getCardName(dynamic card) {
    return card["cardName"] ?? card["CardName"] ?? "";
  }

  // =========================
  // FETCH CARDS
  // =========================

  Future<void> fetchCards() async {
    try {
      final data = await CardApi.showAvailableCards(playerId!, gameId!);

      List<dynamic> normalized = [];

      if (data is List) {
        normalized = data;
      } else if (data["cards"] is List) {
        normalized = data["cards"];
      }

      setState(() {
        cards = normalized;
      });

      checkSavedFunction(normalized);
    } catch (e) {
      debugPrint("Error fetching cards: $e");

      setState(() {
        cards = [];
      });
    }
  }

  // =========================
  // CHECK SAVED FUNCTION
  // =========================

  Future<void> checkSavedFunction(List<dynamic> loadedCards) async {
    try {
      final saved = await CardApi.getFunctionApi(gameId!, playerId!);

      if (saved != null && saved.length > 0) {
        setState(() {
          isFunctionSaved = true;

          selectedCards = saved
              .map((id) {
                try {
                  return loadedCards.firstWhere((c) => getCardId(c) == id);
                } catch (e) {
                  return null;
                }
              })
              .where((e) => e != null)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("No saved function: $e");
    }
  }

  // =========================
  // SELECT CARD
  // =========================

  void handleSelectCard(dynamic card) {
    if (isFunctionSaved) {
      showMessage("Locked", "Function already saved.");
      return;
    }

    if (selectedCards.length >= 3) {
      showMessage("Limit Reached", "Maximum 3 cards allowed");
      return;
    }

    if (getCardQty(card) <= 0) {
      showMessage("No Quantity", "No cards left");
      return;
    }

    final id = getCardId(card);

    setState(() {
      cards = cards.map((c) {
        if (getCardId(c) == id) {
          final qty = getCardQty(c) - 1;

          return {...c, "quantity": qty, "Quantity": qty};
        }

        return c;
      }).toList();

      selectedCards.add(card);
    });
  }

  // =========================
  // REMOVE CARD
  // =========================

  void handleRemoveCard(dynamic cardId, int index) {
    if (isFunctionSaved) return;

    setState(() {
      cards = cards.map((c) {
        if (getCardId(c) == cardId) {
          final qty = getCardQty(c) + 1;

          return {...c, "quantity": qty, "Quantity": qty};
        }

        return c;
      }).toList();

      selectedCards.removeAt(index);
    });
  }

  // =========================
  // SAVE / USE FUNCTION
  // =========================

  Future<void> handleFunction() async {
    try {
      setState(() {
        loading = true;
      });

      // SAVE FUNCTION

      if (!isFunctionSaved) {
        if (selectedCards.isEmpty) {
          showMessage("Error", "Select cards first");
          return;
        }

        final cardIds = selectedCards.map((c) => getCardId(c)).toList();

        await CardApi.useFunctionApi(gameId!, playerId!, cardIds);

        setState(() {
          isFunctionSaved = true;
        });

        showMessage("Success", "Function Saved Successfully");

        return;
      }

      // USE FUNCTION

      if (moveId == null) {
        showMessage("Error", "Roll dice first");
        return;
      }

      await CardApi.useFunctionApi(gameId!, playerId!, null);

      final moveResponse = await CardApi.movePlayer(moveId!);

      // GAME COMPLETED

      if (moveResponse["gameStatus"] == "Completed") {
        Navigator.pushReplacementNamed(
          context,
          "/result",
          arguments: {
            "results": moveResponse["results"],
            "gameId": gameId,
            "playerId": playerId,
          },
        );

        return;
      }

      // PLAYER FINISHED

      if (moveResponse["gameStatus"] == "PlayerFinished") {
        showMessage(
          "Finished",
          "You finished #${moveResponse["finishPosition"]}",
        );

        Navigator.pushNamed(
          context,
          isMultiplayer ? "/game" : "/testGame",
          arguments: {
            "gameId": gameId,
            "playerId": playerId,
            "playerOrder": playerOrder,
            "updatedPosition": moveResponse["newPosition"],
            "updatedDirection": moveResponse["direction"] ?? "up",
            "isFinished": true,
          },
        );

        return;
      }

      // BLOCKED

      bool isBlocked =
          moveResponse["message"] == "Blocked" ||
          moveResponse["Message"] == "Blocked" ||
          moveResponse["blockedByHurdle"] == true ||
          moveResponse["BlockedByHurdle"] == true;

      if (isBlocked) {
        showMessage("Blocked", "There's a hurdle ahead.");

        Navigator.pushNamed(
          context,
          isMultiplayer ? "/game" : "/testGame",
          arguments: {
            "gameId": gameId,
            "playerId": playerId,
            "playerOrder": playerOrder,
            "updatedPosition":
                moveResponse["NewPosition"] ?? moveResponse["newPosition"],
            "updatedDirection":
                moveResponse["Direction"] ?? moveResponse["direction"] ?? "up",
          },
        );

        return;
      }

      // NORMAL MOVE

      Navigator.pushNamed(
        context,
        isMultiplayer ? "/game" : "/testGame",
        arguments: {
          "gameId": gameId,
          "playerId": playerId,
          "playerOrder": playerOrder,
          "updatedPosition": moveResponse["NewPosition"],
          "updatedDirection": moveResponse["Direction"],
        },
      );
    } catch (e) {
      debugPrint("Function Error: $e");

      showMessage("Error", e.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // =========================
  // ALERT
  // =========================

  void showMessage(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
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
        child: Column(
          children: [
            // BACK BUTTON
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isFunctionSaved ? "Your Saved Function" : "Build Your Function",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // CARDS GRID
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final card = cards[index];

                  return GestureDetector(
                    onTap: () => handleSelectCard(card),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Image.asset(
                              cardImages[normalize(getCardName(card))] ??
                                  cardImages["forward"]!,
                              height: 60,
                            ),
                          ),

                          Positioned(
                            top: 5,
                            left: 5,
                            child: Text(
                              getCardQty(card).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // SELECTED CARDS
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCards.length,
                itemBuilder: (_, index) {
                  final card = selectedCards[index];

                  return GestureDetector(
                    onTap: () => handleRemoveCard(getCardId(card), index),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Image.asset(
                          cardImages[normalize(getCardName(card))] ??
                              cardImages["forward"]!,
                          height: 50,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : handleFunction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    loading
                        ? "Please wait..."
                        : isFunctionSaved
                        ? "USE FUNCTION"
                        : "SAVE FUNCTION",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
