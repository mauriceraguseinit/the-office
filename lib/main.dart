import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'hud/character_editor.dart';
import 'hud/inventory_overlay.dart';
import 'hud/speech_bubble.dart';
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
  Map<String, OverlayWidgetBuilder<OfficeGame>>? overlayBuilderMap = <String, OverlayWidgetBuilder<OfficeGame>>{
    'inventory': (BuildContext context, OfficeGame game) => InventoryOverlay(game: game),
    'intro': (BuildContext context, OfficeGame game) => RetroSpeechBubble(
      actions: <RetroAction>[RetroAction(title: 'Starten', onTap: () => game.overlays.remove('intro'))],
      text:
          'Willkommen im Büro.\n\nHeute wird es wieder sehr heiß!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
      onClose: () => game.overlays.remove('intro'),
    ),
  };

  // Wir erstellen das Spiel-Objekt einmalig im State
  final OfficeGame _game = OfficeGame();
  bool _showEditor = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _showEditor
            ? CharacterEditor(onFinished: () => setState(() => _showEditor = false))
            : ListenableBuilder(
                listenable: _game.overlayChangeNotifier, // Reagiert, wenn sich im Spiel was tut
                builder: (BuildContext context, Widget? child) {
                  return MouseRegion(
                    // TRICK: Wenn ein Item aktiv ist, blenden wir den System-Cursor komplett aus!
                    cursor: _game.selectedItem != null ? SystemMouseCursors.none : SystemMouseCursors.basic,
                    child: GameWidget<OfficeGame>(game: _game, overlayBuilderMap: overlayBuilderMap),
                  );
                },
              ),
      ),
    );
  }
}
