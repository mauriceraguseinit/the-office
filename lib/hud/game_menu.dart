import 'dart:math';

import 'package:flutter/material.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/office_game.dart';
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/styles.dart';

class GameMenuButton extends StatelessWidget {
  const GameMenuButton({super.key, required this.game});
  final OfficeGame game;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
        final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
        final double gameScale = min(scaleX, scaleY);

        return Center(
          child: SizedBox(
            width: GameConfig.resolution.width * gameScale,
            height: GameConfig.resolution.height * gameScale,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 16,
                  left: 16,
                  child: Transform.scale(
                    scale: gameScale,
                    alignment: Alignment.topLeft,
                    child: RetroButton(
                      title: 'MENÜ',
                      onTap: () {
                        game.openGameMenu();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GameMenuOverlay extends StatelessWidget {
  const GameMenuOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
          final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
          final double gameScale = min(scaleX, scaleY);

          const double baseWidth = 350.0;
          const double baseHeight = 350.0;

          return SizedBox(
            width: baseWidth * gameScale,
            height: baseHeight * gameScale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: baseWidth,
                height: baseHeight,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 6),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'HAUPTMENÜ',
                              style: GameStyles.inventoryTitleStyle,
                            ),
                            const Divider(color: Color(0xFF1E1E1E), thickness: 4),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 240,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  RetroButton(
                                    title: 'Speichern',
                                    alignment: Alignment.center,
                                    onTap: () {
                                      game.saveGame();
                                      game.overlays.remove('gameMenu');
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  RetroButton(
                                    title: 'Laden',
                                    alignment: Alignment.center,
                                    onTap: () {
                                      game.loadGame();
                                      game.overlays.remove('gameMenu');
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  RetroButton(
                                    title: 'Kaffee kochen',
                                    alignment: Alignment.center,
                                    onTap: () {
                                      game.overlays.remove('gameMenu');
                                      game.showPlayerMessage(
                                        '[b]Hendrik:[/b]\n\n'
                                        'Ich hab auf [color=red]KAFFEE[/color] gedrückt, aber es kam nur eine Fehlermeldung: [i]Error 418: I\'m a teapot.[/i]\n\n'
                                        'Typisch IT...',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  RetroButton(
                                    title: 'Steuerung',
                                    alignment: Alignment.center,
                                    onTap: () {
                                      game.overlays.remove('gameMenu');
                                      game.showPlayerMessage(
                                        'BEWEGUNG: WASD / Touch (Gedrückthalten)\nAKTION: Taste E\nINVENTAR: Taste I',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => game.overlays.remove('gameMenu'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
                              ),
                              child: Text(
                                'X',
                                style: GameStyles.buttonStyle.copyWith(
                                  color: const Color(0xFFF5F5F5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
