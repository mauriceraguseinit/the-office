import 'dart:math';

import 'package:flutter/material.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/utils/config.dart';

import '../l10n/l10n.dart';

class StartMenu extends StatelessWidget {
  const StartMenu({
    super.key,
    required this.onContinue,
    required this.onNewGame,
  });

  final VoidCallback onContinue;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
          final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
          final double gameScale = min(scaleX, scaleY);

          const double baseWidth = 450.0;
          const double baseHeight = 350.0;

          return Center(
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
                        border: Border.all(color: Colors.orange, width: 6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            'THE OFFICE',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            S.of(context).welcome_back_title,
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 14,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 250,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                RetroButton(
                                  title: S.of(context).continue_button_label,
                                  alignment: Alignment.center,
                                  onTap: onContinue,
                                ),
                                const SizedBox(height: 16),
                                RetroButton(
                                  title: S.of(context).new_game_button_label,
                                  alignment: Alignment.center,
                                  onTap: onNewGame,
                                ),
                              ],
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
