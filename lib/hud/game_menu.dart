import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/office_game.dart';
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/styles.dart';
import 'package:vector_math/vector_math.dart';

import '../l10n/l10n.dart';

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
                      title: S.of(context).menu_button,
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

          return MouseRegion(
            cursor: game.isTouchDevice ? SystemMouseCursors.basic : SystemMouseCursors.none,
            onHover: (PointerHoverEvent event) =>
                game.updateMousePosition(Vector2(event.localPosition.dx, event.localPosition.dy)),
            child: SizedBox(
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
                                S.of(context).menu_title,
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
                                      title: S.of(context).menu_save,
                                      alignment: Alignment.center,
                                      onTap: () {
                                        game.saveGame();
                                        game.overlays.remove('gameMenu');
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    RetroButton(
                                      title: S.of(context).menu_load,
                                      alignment: Alignment.center,
                                      onTap: () {
                                        game.loadGame();
                                        game.overlays.remove('gameMenu');
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    RetroButton(
                                      title: S.of(context).menu_coffey,
                                      alignment: Alignment.center,
                                      onTap: () {
                                        game.overlays.remove('gameMenu');
                                        game.showPlayerMessage(
                                          S.of(context).menu_coffey_text,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    RetroButton(
                                      title: S.of(context).menu_controls,
                                      alignment: Alignment.center,
                                      onTap: () {
                                        game.overlays.remove('gameMenu');
                                        game.showPlayerMessage(
                                          S.of(context).menu_controls_text,
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
            ),
          );
        },
      ),
    );
  }
}
