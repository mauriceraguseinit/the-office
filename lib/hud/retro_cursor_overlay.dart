import 'dart:math';

import 'package:flutter/material.dart';
import 'package:the_office/models/inventory_item.dart';

import '../office_game.dart';
import '../utils/config.dart';

class RetroCursorOverlay extends StatelessWidget {
  const RetroCursorOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
          final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
          final double gameScale = min(scaleX, scaleY);

          return Stack(
            children: <Widget>[
              ValueListenableBuilder<Offset>(
                valueListenable: game.mousePositionRawNotifier,
                builder: (BuildContext context, Offset pos, Widget? child) {
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: ListenableBuilder(
                        listenable: game.state,
                        builder: (BuildContext context, Widget? child) {
                          final InventoryItem? selectedItem = game.state.selectedItem;
                          if (selectedItem != null) {
                            return Image.asset(
                              selectedItem.assetPath,
                              width: 48 * gameScale,
                              height: 48 * gameScale,
                              filterQuality: FilterQuality.none,
                            );
                          }

                          final bool isHovering =
                              game.state.highlightedObject != null || game.state.isPlayerHighlighted;
                          return CustomPaint(
                            size: Size(32 * gameScale, 32 * gameScale),
                            painter: _CrosshairPainter(
                              color: isHovering ? Colors.orange : Colors.white,
                              scale: gameScale,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({required this.color, required this.scale});
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double center = size.width / 2;
    final double crossSize = 6.0 * scale;
    final double gap = 4.0 * scale;
    final double thickness = 2.0 * scale;
    final double outline = 1.5 * scale; // Stärke der schwarzen Kontur

    void drawElement(double left, double top, double width, double height) {
      // 1. Kontur (etwas größer)
      canvas.drawRect(
        Rect.fromLTWH(left - outline, top - outline, width + outline * 2, height + outline * 2),
        outlinePaint,
      );
      // 2. Füllung
      canvas.drawRect(Rect.fromLTWH(left, top, width, height), fillPaint);
    }

    // Mitte (Punkt)
    drawElement(center - thickness / 2, center - thickness / 2, thickness, thickness);

    // Oben
    drawElement(center - thickness / 2, center - gap - crossSize, thickness, crossSize);
    // Unten
    drawElement(center - thickness / 2, center + gap, thickness, crossSize);
    // Links
    drawElement(center - gap - crossSize, center - thickness / 2, crossSize, thickness);
    // Rechts
    drawElement(center + gap, center - thickness / 2, crossSize, thickness);
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) => color != oldDelegate.color || scale != oldDelegate.scale;
}
