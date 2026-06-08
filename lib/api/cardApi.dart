import 'dart:convert';

import 'apiclient.dart';

class CardApi {
  /* ===============================
     🔹 Show Available Cards
  ============================== */

  static Future<dynamic> showAvailableCards(
    String playerId,
    String gameId,
  ) async {
    return await ApiClient.request(
      "Card/ShowAvailableCards?playerId=$playerId&gameId=$gameId",
      method: "GET",
    );
  }

  /* ===============================
     🔹 Use Cards
  ============================== */

  static Future<dynamic> useCards(String moveId, List<dynamic> cardIds) async {
    return await ApiClient.request(
      "Card/UseCards",
      method: "POST",
      body: jsonEncode({"moveId": moveId, "cardIds": cardIds}),
    );
  }

  /* ===============================
     🔹 Move Player
  ============================== */

  static Future<dynamic> movePlayer(String moveId) async {
    return await ApiClient.request(
      "Game/MovePlayer?moveId=$moveId",
      method: "POST",
    );
  }

  /* ===============================
     🔹 Get Player Positions
  ============================== */

  static Future<dynamic> getPlayerPositions(String gameId) async {
    return await ApiClient.request(
      "Game/GetPlayerPositions?gameId=$gameId",
      method: "GET",
    );
  }

  /* ===============================
     🔹 Previous Moves
  ============================== */

  static Future<dynamic> getPreviousMoves(
    String playerId,
    String gameId,
  ) async {
    final response = await ApiClient.request(
      "Card/GetPreviousMoves?playerId=$playerId&gameId=$gameId",
      method: "GET",
    );

    print("Previous Moves API Response: $response");

    return response;
  }

  /* ===============================
     🔹 Use Function
  ============================== */

  static Future<dynamic> useFunctionApi(
    String gameId,
    String playerId,
    List<dynamic>? cardIds,
  ) async {
    try {
      return await ApiClient.request(
        "Card/UseFunction",
        method: "POST",
        body: jsonEncode({
          "GameId": gameId,
          "PlayerId": playerId,
          "CardIds": cardIds,
        }),
      );
    } catch (error) {
      final msg = error.toString();

      if (msg.contains("Function saved") ||
          msg.contains("Function applied") ||
          msg.contains("JSON") ||
          msg.contains("Unexpected")) {
        print("Function API plain text response — ignoring parse error");

        return {"success": true};
      }

      rethrow;
    }
  }

  /* ===============================
     🔹 Get Function
  ============================== */

  static Future<dynamic> getFunctionApi(String gameId, String playerId) async {
    return await ApiClient.request(
      "Card/GetFunction?gameId=$gameId&playerId=$playerId",
      method: "GET",
    );
  }
}
