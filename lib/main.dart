import 'dart:math' as math;

import 'package:flame/game.dart';
// Ganz oben zu deinen Imports hinzufügen
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_office/utils/config.dart';
// ignore: depend_on_referenced_packages, avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
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
          'Willkommen im Büro.\n\nHeute wird es durch den Regen schwül und warm!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
      onClose: () => game.overlays.remove('intro'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: switch (_showScene) {
          Scenes.editor => CharacterEditor(
            onFinished: () {
              // WENN es im Browser läuft, starte den Fullscreen-Modus
              if (kIsWeb) {
                try {
                  web.document.documentElement?.requestFullscreen();

                  // Orientierung auf Landscape sperren
                  web.window.screen.orientation.lock('landscape');
                } catch (e) {
                  debugPrint('Vollbild wurde vom Browser blockiert oder nicht unterstützt: $e');
                }
              }

              // Danach normal weiter zur Intro-Szene
              setState(() => _showScene = Scenes.intro);
            },
          ),

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
