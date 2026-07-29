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

class _MobileInventoryButtonState extends State<MobileInventoryButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    widget.game.inventoryGlowNotifier.addListener(_onGlow);
  }

  void _onGlow() {
    if (!mounted) return;
    _glowController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.game.inventoryGlowNotifier.removeListener(_onGlow);
    _glowController.dispose();
    super.dispose();
  }

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
                  top: 32,
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
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (BuildContext context, Widget? child) {
                            return Transform.scale(
                              scale: gameScale * (_isPressed ? 0.9 : 1.0) * _glowAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50),
                              border: Border.all(
                                color: _glowController.isAnimating ? Colors.orange : Colors.white,
                                width: 4,
                              ),
                              boxShadow: _glowController.isAnimating
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.orange.withAlpha((255 * 0.6).toInt()),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: <Widget>[
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
