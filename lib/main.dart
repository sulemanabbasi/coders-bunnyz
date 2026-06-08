import 'package:codersbunny/Loading.dart';
import 'package:flutter/material.dart';

import 'menu.dart';
import 'playgame.dart';
import 'learngame.dart';
import 'joinroom.dart';
import 'setting.dart';
import 'CreateRoom.dart';
import 'lobby.dart';
import 'gameboard.dart';
import 'sologame.dart';
import 'functioncard.dart';
import 'previousmoves.dart';
import 'select-card.dart';
import 'result.dart';
import 'resumegame.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const LoadingScreen(),

      // simple routes ONLY (no required params here)
      routes: {
        '/menu': (context) => const MenuScreen(),
        '/playGame': (context) => const PlayGame(),
        '/learnGame': (context) => const LearnGame(),
        '/setting': (context) => const SettingScreen(),
        '/joinGame': (context) => const JoinRoomScreen(),
        '/resumeGame': (context) => const ResumeGame(),
      },

      // 🔥 ALL PARAMETER SCREENS HERE
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map?;

        switch (settings.name) {
          case '/createRoom':
            return MaterialPageRoute(
              builder: (_) => CreateRoomScreen(
                roomCode: args?["roomCode"] ?? "",
                gameId: args?["gameId"] ?? 0,
                playerId: args?["playerId"] ?? 0,
                isHost: args?["isHost"] ?? false,
                players: args?["players"] ?? false,
              ),
            );

          case '/lobby':
            return MaterialPageRoute(
              builder: (_) => LobbyScreen(
                roomCode: args?["roomCode"] ?? "",
                gameId: args?["gameId"] ?? 0,
                playerId: args?["playerId"] ?? 0,
                isHost: args?["isHost"] ?? false,
              ),
            );

          case '/game':
            return MaterialPageRoute(
              builder: (_) => GameBoard(
                gameId: args?["gameId"] ?? 0,
                playerId: args?["playerId"] ?? 0,
              ),
            );

          case '/testGame':
            return MaterialPageRoute(
              builder: (_) => SoloGameBoard(
                gameId: args?["gameId"] ?? 0,
                playerId: args?["playerId"] ?? 0,
              ),
            );

          case '/functionCard':
            return MaterialPageRoute(builder: (_) => FunctionCard());

          case '/previousMoves':
            return MaterialPageRoute(
              builder: (_) => PreviousMovesScreen(
                playerId: args?["playerId"] ?? "",
                gameId: args?["gameId"] ?? "",
              ),
            );

          case '/selectCard':
            return MaterialPageRoute(
              builder: (_) => SelectCardsScreen(
                gameId: args?["gameId"] ?? 0,
                playerId: args?["playerId"] ?? 0,
                moveId: args?["moveId"] ?? 0,
                diceValue: args?["diceValue"] ?? 0,
              ),
            );

          case '/result':
            return MaterialPageRoute(
              builder: (_) => ResultScreen(
                results: args?["results"] ?? [],
                gameId: args?["gameId"] ?? "",
                playerId: args?["playerId"] ?? "",
              ),
            );
        }

        return null;
      },
    );
  }
}
