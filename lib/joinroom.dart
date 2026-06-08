import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api/game_api.dart';

// ⚠️ Replace if needed
const String BASE_URL = "http://192.168.1.18:8082/api";

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  bool _loading = false;
  String _error = "";

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final roomId = _roomIdController.text.trim();

    if (roomId.isEmpty) {
      setState(() => _error = "Please enter a Room ID");
      return;
    }

    setState(() {
      _error = "";
      _loading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse("${GameService.baseUrl}Room/JoinRoom"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"RoomCode": roomId}),
          )
          .timeout(const Duration(seconds: 10));

      // 🔍 DEBUG (IMPORTANT)
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // ✅ HANDLE BOTH camelCase & PascalCase
        final gameId = data["gameId"] ?? data["GameId"] ?? "";
        final roomCode = data["roomCode"] ?? data["RoomCode"] ?? "";
        final playerId = data["playerId"] ?? data["PlayerId"] ?? "";

        if (gameId.toString().isEmpty) {
          setState(() => _error = "Invalid server response");
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("roomId", roomCode.toString());
        await prefs.setString("gameId", gameId.toString());
        await prefs.setString("playerId", playerId.toString());
        await prefs.setString("isHost", "false");

        if (!mounted) return;

        // ✅ SAFE NAVIGATION
        Navigator.pushNamed(context, "/lobby");
      } else {
        String msg = "Join failed";

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is String) {
            msg = decoded;
          } else if (decoded is Map) {
            msg = decoded["message"] ?? decoded["Message"] ?? msg;
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            msg = response.body;
          }
        }

        setState(() => _error = msg);
      }
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        _error = "Server not reachable";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF1A2AA8), Color(0xFF0B145A), Color(0xFF050B2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Join Game",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _roomIdController,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Enter Room ID",
                      hintStyle: const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (_error.isNotEmpty)
                    Text(_error, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleJoin,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Join Lobby"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
