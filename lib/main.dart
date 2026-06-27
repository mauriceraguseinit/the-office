import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'office_game.dart';

void main() {
  runApp(const TheOfficeApp());
}

class TheOfficeApp extends StatefulWidget {
  const TheOfficeApp({super.key});

  @override
  State<TheOfficeApp> createState() => _TheOfficeAppState();
}

class _TheOfficeAppState extends State<TheOfficeApp> {
  // Wir erstellen das Spiel-Objekt einmalig im State
  final OfficeGame _game = OfficeGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: _game.overlayChangeNotifier, // Reagiert, wenn sich im Spiel was tut
          builder: (context, child) {
            return MouseRegion(
              // TRICK: Wenn ein Item aktiv ist, blenden wir den System-Cursor komplett aus!
              cursor: _game.selectedItem != null ? SystemMouseCursors.none : SystemMouseCursors.basic,
              child: GameWidget(game: _game, overlayBuilderMap: _game.overlayBuilderMap),
            );
          },
        ),
      ),
    );
  }
}
