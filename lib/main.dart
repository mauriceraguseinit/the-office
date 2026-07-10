import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/utils/config.dart';

import 'hud/character_editor.dart';
import 'hud/inventory_overlay.dart';
import 'hud/retro_button.dart';
import 'hud/speech_bubble.dart';
import 'intro/intro_game.dart';
import 'office_game.dart';

enum Scenes {
  editor,
  intro,
  game,
}

void main() {
  runApp(const TheOfficeApp());
}

class TheOfficeApp extends StatefulWidget {
  const TheOfficeApp({super.key});

  @override
  State<TheOfficeApp> createState() => _TheOfficeAppState();
}

class _TheOfficeAppState extends State<TheOfficeApp> {
  // Das eigentliche Hauptspiel
  final OfficeGame _game = OfficeGame();

  // Instanz für das Intro-Spiel
  late final IntroGame _introGame;

  Scenes _showScene = Scenes.editor;

  @override
  void initState() {
    super.initState();
    _introGame = IntroGame(
      onIntroComplete: () {
        setState(() => _showScene = Scenes.game);
      },
    );
  }

  Map<String, OverlayWidgetBuilder<OfficeGame>>? overlayBuilderMap = <String, OverlayWidgetBuilder<OfficeGame>>{
    'inventory': (BuildContext context, OfficeGame game) => InventoryOverlay(game: game),
    'intro': (BuildContext context, OfficeGame game) => RetroSpeechBubble(
      actions: <RetroAction>[RetroAction(title: 'Starten', onTap: () => game.overlays.remove('intro'))],
      text:
          'Willkommen im Büro.\n\nHeute wird es wieder sehr heiß!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
      onClose: () => game.overlays.remove('intro'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: switch (_showScene) {
          Scenes.editor => CharacterEditor(onFinished: () => setState(() => _showScene = Scenes.intro)),

          Scenes.intro => GameWidget<IntroGame>(
            game: _introGame,
            initialActiveOverlays: const <String>['button'],
            overlayBuilderMap: <String, OverlayWidgetBuilder<IntroGame>>{
              'button': (BuildContext context, IntroGame introGame) {
                // Virtuelle Auflösung des Intros abgreifen

                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Berechne den aktuellen Skalierungsfaktor des Bildschirmfensters
                    final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
                    final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
                    final double gameScale = math.min(scaleX, scaleY);

                    // Positioniert den Button absolut stabil am unteren Rand des skalierten Viewports
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        // Auch das Padding schrumpft/wächst passend mit
                        padding: EdgeInsets.all(32 * gameScale),
                        child: Transform.scale(
                          scale: gameScale,
                          alignment: Alignment.bottomCenter,
                          child: RetroButton(
                            title: 'Überspringen',
                            onTap: () => setState(() => _showScene = Scenes.game),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            },
          ),

          Scenes.game => ListenableBuilder(
            listenable: _game.overlayChangeNotifier,
            builder: (BuildContext context, Widget? child) {
              return MouseRegion(
                cursor: _game.selectedItem != null ? SystemMouseCursors.none : SystemMouseCursors.basic,
                child: GameWidget<OfficeGame>(game: _game, overlayBuilderMap: overlayBuilderMap),
              );
            },
          ),
        },
      ),
    );
  }
}
