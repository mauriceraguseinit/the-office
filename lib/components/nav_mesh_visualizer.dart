import 'dart:ui';

import 'package:clipper2/clipper2.dart';
import 'package:flame/components.dart';

class NavMeshVisualizer extends PositionComponent {
  NavMeshVisualizer(this.paths) : super(priority: 9999);
  final Paths64 paths;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Paint fillPaint = Paint()
      ..color = const Color(0x3F00FF00)
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Alle Clipper-Konturen gemeinsam füllen.
    // Dadurch werden innere Konturen als Löcher interpretiert.
    final Path combinedPath = Path()..fillType = PathFillType.evenOdd;

    for (final Path64 path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final List<Offset> points = path
          .map(
            (Point64 point) => Offset(
              point.x.toDouble(),
              point.y.toDouble(),
            ),
          )
          .toList();

      combinedPath.addPolygon(points, true);
    }

    // Die komplette begehbare Fläche einmal füllen.
    canvas.drawPath(combinedPath, fillPaint);

    // Ränder weiterhin einzeln zeichnen, damit jede Kante sichtbar bleibt.
    for (final Path64 path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final List<Offset> points = path
          .map(
            (Point64 point) => Offset(
              point.x.toDouble(),
              point.y.toDouble(),
            ),
          )
          .toList();

      final Path outlinePath = Path()..addPolygon(points, true);
      canvas.drawPath(outlinePath, strokePaint);
    }
  }
}
