import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:signalr_core/signalr_core.dart';

class GameService {
  // =====================
  // 🔗 BASE URL
  // =====================

  static const String baseUrl = "http://192.168.1.18:8082/api/";
  static const String hubUrl = "http://192.168.1.18:8082/gameHub";

  // =====================
  // 🌐 API CLIENT
  // =====================

  static Future<dynamic> _post(String endpoint, {Map? body}) async {
    final uri = Uri.parse(baseUrl + endpoint);

    print("POST => $uri");
    print("BODY => $body");

    final response = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 20));

    print("STATUS => ${response.statusCode}");
    print("RESPONSE => ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : "Error ${response.statusCode}",
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  static Future<dynamic> _get(String endpoint) async {
    final uri = Uri.parse(baseUrl + endpoint);

    print("GET => $uri");

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    print("STATUS => ${response.statusCode}");
    print("RESPONSE => ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : "Error ${response.statusCode}",
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  // =====================
  // 🎮 GAME APIs
  // =====================

  static Future createGame(String playerName) async {
    return await _post(
      "Game/CreateGame?playerName=${Uri.encodeComponent(playerName)}",
    );
  }

  static Future startGame(String roomCode) async {
    return await _post(
      "Game/StartGame?roomCode=${Uri.encodeComponent(roomCode)}",
    );
  }

  static Future soloGame(
    String difficulty,
    String gameStatus,
    List<String> playerIds,
  ) async {
    final players = playerIds
        .map((e) => "playerIds=${Uri.encodeComponent(e)}")
        .join("&");

    return await _post(
      "Game/SoloGame?difficulty=${Uri.encodeComponent(difficulty)}&gameStatus=${Uri.encodeComponent(gameStatus)}&$players",
    );
  }

  static Future getCurrentTurn(String gameId) async {
    return await _get(
      "Game/GetCurrentTurn?gameId=${Uri.encodeComponent(gameId)}",
    );
  }

  static Future rollDice(String gameId, String playerId) async {
    return await _post(
      "Game/RollDice",
      body: {"gameId": gameId, "playerId": playerId},
    );
  }

  static Future movePlayer(String moveId) async {
    return await _post("Game/MovePlayer?moveId=${Uri.encodeComponent(moveId)}");
  }

  static Future undoMove(String gameId, String playerId) async {
    return await _post(
      "Game/UndoLastMove?gameId=${Uri.encodeComponent(gameId)}&playerId=${Uri.encodeComponent(playerId)}",
    );
  }

  static Future getPlayerPositions(String gameId) async {
    return await _get(
      "Game/GetPlayerPositions?gameId=${Uri.encodeComponent(gameId)}",
    );
  }

  static Future pauseGame(String gameId) async {
    return await _post("Game/PauseGame?gameId=${Uri.encodeComponent(gameId)}");
  }

  static Future endGame(String gameId, String playerId) async {
    return await _post(
      "Game/EndGame?gameId=${Uri.encodeComponent(gameId)}&playerId=${Uri.encodeComponent(playerId)}",
    );
  }

  static Future resumeGame(String gameId) async {
    return await _post("Game/ResumeGame?gameId=${Uri.encodeComponent(gameId)}");
  }

  static Future getPausedGames() async {
    return await _get("Game/GetPausedGames");
  }

  static Future restartGame(String gameId) async {
    return await _post(
      "Game/RestartGame?gameId=${Uri.encodeComponent(gameId)}",
    );
  }

  static Future joinRoom(String roomCode, String playerName) async {
    return await _post(
      "Game/JoinGame",
      body: {"roomCode": roomCode, "playerName": playerName},
    );
  }

  // =====================
  // ⚡ SIGNALR
  // =====================

  static HubConnection? _connection;

  static Future<HubConnection> getConnection() async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.connected) {
      return _connection!;
    }

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            transport: HttpTransportType.webSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.serverTimeoutInMilliseconds = 60000;
    _connection!.keepAliveIntervalInMilliseconds = 15000;

    await _connection!.start();

    print("✅ SignalR Connected");

    return _connection!;
  }

  static Future stopConnection() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;

      print("🛑 SignalR Disconnected");
    }
  }
}
