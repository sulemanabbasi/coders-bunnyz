import 'package:signalr_core/signalr_core.dart';

class GameConnection {
  static const String hubUrl = "http://192.168.1.11:8082/gameHub";

  static HubConnection? _connection;

  static Future<HubConnection> getConnection() async {
    if (_connection == null) {
      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      await _connection!.start();
      print("✅ SignalR Connected");
    }

    return _connection!;
  }

  static Future<void> stopConnection() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      print("🛑 SignalR Disconnected");
    }
  }
}
