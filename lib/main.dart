import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_office/utils/config.dart';
// ignore: depend_on_referenced_packages, avoid_web_libraries_in_flutter
import 'package:the_office/utils/web_helper.dart' as web_helper;

import 'hud/character_editor.dart';
import 'hud/inventory_overlay.dart';
import 'hud/retro_button.dart';
import 'hud/speech_bubble.dart';
import 'intro/intro_game.dart';
import 'managers/service_locator.dart';
import 'office_game.dart';

enum Scenes {
  editor,
  intro,
  game,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
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
  final OfficeGame _game = OfficeGame();
  late final IntroGame _introGame;
  Scenes _showScene = Scenes.editor;

  // Tracken, ob wir im Web aktuell im Vollbildmodus sind
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _introGame = IntroGame(
      onIntroComplete: () {
        setState(() => _showScene = Scenes.game);
      },
    );
  }

  // Die native Browser-Logik synchron umschalten
  void _toggleFullscreen() {
    web_helper.toggleFullscreen(setFullscreen);
  }

  void setFullscreen(bool isFullscreen) {
    setState(() => _isFullscreen = isFullscreen);
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
        // Wir nutzen einen Stack, damit der Fullscreen-Knopf IMMER oben rechts drüber liegt
        body: Stack(
          children: <Widget>[
            // Das eigentliche Spiel/Szenen-Wechsel
            Positioned.fill(
              child: switch (_showScene) {
                Scenes.editor => CharacterEditor(
                  onFinished: () => setState(() => _showScene = Scenes.intro),
                ),

                Scenes.intro => GameWidget<IntroGame>(
                  game: _introGame,
                  initialActiveOverlays: const <String>['button'],
                  overlayBuilderMap: <String, OverlayWidgetBuilder<IntroGame>>{
                    'button': (BuildContext context, IntroGame introGame) {
                      return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
                          final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
                          final double gameScale = math.min(scaleX, scaleY);

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
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
                    final bool showItemCursor = !_game.isTouchDevice && _game.selectedItem != null;
                    return MouseRegion(
                      cursor: showItemCursor ? SystemMouseCursors.none : SystemMouseCursors.basic,
                      child: GameWidget<OfficeGame>(game: _game, overlayBuilderMap: overlayBuilderMap),
                    );
                  },
                ),
              },
            ),

            // DER FULLSCREEN TOGGLE BUTTON (Nur im Web sichtbar)
            if (kIsWeb)
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                      icon: Icon(
                        _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFullscreen,
                      tooltip: _isFullscreen ? 'Vollbild beenden' : 'Vollbild aktivieren',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
