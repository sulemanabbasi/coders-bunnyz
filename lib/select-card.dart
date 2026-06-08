import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String BASE_URL = "http://192.168.1.18:8082/api";

class SelectCardsScreen extends StatefulWidget {
  final int gameId;
  final int playerId;
  final int moveId;
  final int diceValue;

  const SelectCardsScreen({
    super.key,
    required this.gameId,
    required this.playerId,
    required this.moveId,
    required this.diceValue,
  });

  @override
  State<SelectCardsScreen> createState() => _SelectCardsScreenState();
}

class _SelectCardsScreenState extends State<SelectCardsScreen> {
  List<dynamic> cards = [];
  List<dynamic> selectedCards = [];
  bool loading = false;

  final Map<String, String> cardImages = {
    "forward": "assets/cards/forward.png",
    "right": "assets/cards/right.png",
    "left": "assets/cards/left.png",
    "jump": "assets/cards/jump.png",
    "loop2": "assets/cards/loop2.jpeg",
    "loop3": "assets/cards/loop3.jpeg",
    "loop4": "assets/cards/loop4.jpeg",
    "function": "assets/icons/function.png",
  };

  @override
  void initState() {
    super.initState();
    fetchCards();
  }

  bool isLoopCard(String name) {
    final n = name.toLowerCase().trim();
    return n == "loop2" || n == "loop3" || n == "loop4";
  }

  Future<void> fetchCards() async {
    try {
      final res = await http.get(
        Uri.parse(
          "$BASE_URL/Card/ShowAvailableCards?playerId=${widget.playerId}&gameId=${widget.gameId}",
        ),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      setState(() {
        cards = data is List ? data : [];
      });
    } catch (e) {
      debugPrint("Cards Error: $e");
    }
  }

  void selectCard(dynamic card) {
    int qty = card["Quantity"] ?? card["quantity"] ?? 0;

    final cardName = (card["CardName"] ?? card["cardName"] ?? "").toString();

    if (selectedCards.length >= widget.diceValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Max ${widget.diceValue} cards allowed")),
      );
      return;
    }

    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No cards left")));
      return;
    }

    if (isLoopCard(cardName) && selectedCards.length == widget.diceValue - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loop ke baad card required")),
      );
      return;
    }

    setState(() {
      selectedCards.add(card);
      card["Quantity"] = qty - 1;
    });
  }

  void removeCard(int index) {
    setState(() {
      final card = selectedCards[index];
      card["Quantity"] = (card["Quantity"] ?? card["quantity"] ?? 0) + 1;
      selectedCards.removeAt(index);
    });
  }

  bool validateLoopRules() {
    for (int i = 0; i < selectedCards.length; i++) {
      final name =
          (selectedCards[i]["CardName"] ?? selectedCards[i]["cardName"] ?? "")
              .toString();

      if (isLoopCard(name) && i == selectedCards.length - 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loop ke baad cards required")),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> handleMove() async {
    if (selectedCards.length != widget.diceValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select exactly ${widget.diceValue} cards")),
      );
      return;
    }

    if (!validateLoopRules()) return;

    setState(() {
      loading = true;
    });

    try {
      final List<int> cardIds = selectedCards
          .map<int>((c) => c["CardId"] ?? c["cardId"])
          .toList();

      final useCardsRes = await http.post(
        Uri.parse("$BASE_URL/Card/UseCards"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"moveId": widget.moveId, "cardIds": cardIds}),
      );

      if (useCardsRes.statusCode != 200) {
        throw Exception("Use cards failed: ${useCardsRes.body}");
      }

      final moveRes = await http.post(
        Uri.parse("$BASE_URL/Game/MovePlayer?moveId=${widget.moveId}"),
      );

      if (moveRes.statusCode != 200) {
        throw Exception("Move failed: ${moveRes.body}");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Move Completed")));

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Move Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Move Failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getCardImage(String name) {
    return cardImages[name.toLowerCase().trim()] ?? "assets/cards/forward.png";
  }

  String getCardName(dynamic card) {
    return (card["CardName"] ?? card["cardName"] ?? "").toString();
  }

  int getCardQuantity(dynamic card) {
    return card["Quantity"] ?? card["quantity"] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Select Cards (${selectedCards.length}/${widget.diceValue})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final cardName = getCardName(card);
                  final qty = getCardQuantity(card);

                  return GestureDetector(
                    onTap: () => selectCard(card),
                    child: Container(
                      decoration: BoxDecoration(
                        color: qty <= 0 ? Colors.grey : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isLoopCard(cardName)
                              ? Colors.orange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$qty",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            getCardImage(cardName),
                            width: 42,
                            height: 58,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              height: 120,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: selectedCards.isEmpty
                  ? const Center(
                      child: Text(
                        "Selected cards will show here",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedCards.length,
                      itemBuilder: (context, index) {
                        final card = selectedCards[index];
                        final cardName = getCardName(card);

                        return GestureDetector(
                          onTap: () => removeCard(index),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isLoopCard(cardName)
                                  ? Colors.orange.shade100
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Image.asset(
                                    getCardImage(cardName),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : handleMove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "MOVE (${selectedCards.length}/${widget.diceValue})",
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
