import 'dart:math';

import 'package:flutter/material.dart';

import '../office_game.dart';
import '../utils/assets.dart';
import '../utils/config.dart';

class MobileInventoryButton extends StatefulWidget {
  const MobileInventoryButton({super.key, required this.game});
  final OfficeGame game;

  @override
  State<MobileInventoryButton> createState() => _MobileInventoryButtonState();
}

class _MobileInventoryButtonState extends State<MobileInventoryButton> {
  bool _isPressed = false;

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
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      type: MaterialType.transparency,
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          widget.game.openInventory();
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: Transform.scale(
                          scale: gameScale * (_isPressed ? 0.9 : 1.0),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Stack(
                              children: <Widget>[
                                // Die "abgeknabberten" Pixel-Ecken simulieren
                                Positioned(
                                  top: -2,
                                  left: -2,
                                  child: Container(width: 6, height: 6, color: Colors.transparent),
                                ),

                                Center(
                                  child: Image.asset(
                                    'assets/images/${GameImages.backpack}',
                                    width: 45,
                                    height: 45,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
