import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/minigames/tetris/tetris_game.dart';
import 'package:the_office/office_game.dart';
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/styles.dart';

class TetrisOverlay extends StatefulWidget {
  const TetrisOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  State<TetrisOverlay> createState() => _TetrisOverlayState();
}

class _TetrisOverlayState extends State<TetrisOverlay> {
  late MergeConflictTetris _tetrisGame;

  @override
  void initState() {
    super.initState();
    _tetrisGame = MergeConflictTetris();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Skalierung wie im restlichen Spiel berechnen
        final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
        final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
        final double gameScale = min(scaleX, scaleY);

        // Basis-Maße des Fensters
        const double baseWidth = 600.0;
        const double baseHeight = 750.0;

        return Center(
          child: SizedBox(
            width: baseWidth * gameScale,
            height: baseHeight * gameScale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: baseWidth,
                height: baseHeight,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  border: Border.all(color: Colors.blueAccent, width: 4),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    // Window Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'TERMINAL - MERGE CONFLICT TETRIS',
                          style: GameStyles.buttonStyle.copyWith(color: Colors.blueAccent, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () => widget.game.overlays.remove('tetris'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            color: Colors.redAccent,
                            child: const Text(
                              'X',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.blueAccent),
                    const SizedBox(height: 10),

                    // Game Area
                    Expanded(
                      child: ClipRect(
                        child: GameWidget<MergeConflictTetris>(
                          game: _tetrisGame,
                          autofocus: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Footer / Instructions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _instructionText('ARROWS/WASD: MOVE'),
                        _instructionText('UP/W: ROTATE'),
                        _instructionText('SPACE: DROP'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RetroButton(
                      title: 'CLOSE IDE',
                      onTap: () => widget.game.overlays.remove('tetris'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _instructionText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
    );
  }
}
