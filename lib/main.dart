import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/speech_bubble.dart';
import 'package:the_office/tobi.dart';
import 'package:the_office/trigger_zone.dart';

import 'desk_daniel.dart';
import 'inventory_overlay.dart';
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
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  ...Tobi.dialogs,
                  ...DeskDaniel.dialogs,
                  ...TriggerZone.dialogs,

                  'inventory': (context, OfficeGame game) => InventoryOverlay(game: game),
                  'intro': (context, OfficeGame game) => RetroSpeechBubble(
                    actions: [RetroAction(title: 'Starten', onTap: () => game.overlays.remove('intro'))],
                    text:
                        'Willkommen im Büro.\n\nHente wird es wieder sehr heiß!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
                    onClose: () => game.overlays.remove('intro'),
                  ),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
