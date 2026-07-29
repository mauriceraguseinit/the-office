import 'dart:math';
import 'package:clipper2/clipper2.dart';
import 'package:flame/extensions.dart';
import '../models/a_star_node.dart';

/// Kapselt die Logik für die Wegfindung, damit sie in einem Isolate ausgeführt werden kann.
class Pathfinder {
  Pathfinder({
    required this.navigationBlockers,
    required this.mapPixelWidth,
    required this.mapPixelHeight,
  });

  final Paths64 navigationBlockers;
  final double mapPixelWidth;
  final double mapPixelHeight;

  static const double nodeSize = 32.0;
  static const int maxSearchRadius = 24;

  /// Hauptmethode zur Pfadsuche (synchron für die Verwendung im Isolate).
  List<Vector2> findPath(Vector2 start, Vector2 end) {
    final int targetX = (end.x / nodeSize).round();
    final int targetY = (end.y / nodeSize).round();

    // Zuerst versuchen wir das normale Ziel.
    final List<Vector2> directPath = _findPathToWalkableTarget(start, end);

    if (directPath.isNotEmpty) {
      return directPath;
    }

    // Das Ziel liegt vermutlich in einem Objekt oder einer Wand.
    for (int radius = 1; radius <= maxSearchRadius; radius++) {
      final List<Vector2> candidates = <Vector2>[];

      for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
          if (max(dx.abs(), dy.abs()) != radius) {
            continue;
          }

          final Vector2 candidate = Vector2(
            (targetX + dx) * nodeSize,
            (targetY + dy) * nodeSize,
          );

          if (isPositionWalkable(candidate)) {
            candidates.add(candidate);
          }
        }
      }

      candidates.sort(
        (Vector2 a, Vector2 b) => a.distanceTo(end).compareTo(b.distanceTo(end)),
      );

      for (final Vector2 candidate in candidates) {
        final List<Vector2> path = _findPathToWalkableTarget(
          start,
          candidate,
        );

        if (path.isNotEmpty) {
          return path;
        }
      }
    }

    return <Vector2>[];
  }

  List<Vector2> _findPathToWalkableTarget(Vector2 start, Vector2 end) {
    final int startX = (start.x / nodeSize).round();
    final int startY = (start.y / nodeSize).round();
    final int endX = (end.x / nodeSize).round();
    final int endY = (end.y / nodeSize).round();

    final AStarNode startNode = AStarNode(startX, startY);
    final AStarNode endNode = AStarNode(endX, endY);

    final Vector2 endWorldPosition = Vector2(
      endX * nodeSize,
      endY * nodeSize,
    );

    if (!isPositionWalkable(endWorldPosition)) {
      return <Vector2>[];
    }

    final List<AStarNode> openSet = <AStarNode>[startNode];
    final Set<AStarNode> closedSet = <AStarNode>{};

    final List<List<int>> directions = <List<int>>[
      <int>[0, 1], <int>[1, 0], <int>[0, -1], <int>[-1, 0],
      <int>[1, 1], <int>[-1, 1], <int>[1, -1], <int>[-1, -1],
    ];

    while (openSet.isNotEmpty) {
      openSet.sort((AStarNode a, AStarNode b) => a.f.compareTo(b.f));
      final AStarNode current = openSet.removeAt(0);
      closedSet.add(current);

      if (current == endNode) {
        final List<Vector2> path = <Vector2>[];
        AStarNode? temp = current;
        while (temp != null) {
          path.add(Vector2(temp.x * nodeSize, temp.y * nodeSize));
          temp = temp.parent;
        }
        return path.reversed.toList();
      }

      for (final List<int> dir in directions) {
        final int neighborX = current.x + dir[0];
        final int neighborY = current.y + dir[1];
        final AStarNode neighbor = AStarNode(neighborX, neighborY, parent: current);

        if (closedSet.contains(neighbor)) continue;

        final Vector2 worldPos = Vector2(neighborX * nodeSize, neighborY * nodeSize);

        if (!isPositionWalkable(worldPos)) {
          continue;
        }

        final Vector2 currentWorldPos = Vector2(
          current.x * nodeSize,
          current.y * nodeSize,
        );

        if (!canWalkBetween(currentWorldPos, worldPos)) {
          continue;
        }

        if (dir[0] != 0 && dir[1] != 0) {
          final Vector2 adjacent1 = Vector2((current.x + dir[0]) * nodeSize, current.y * nodeSize);
          final Vector2 adjacent2 = Vector2(current.x * nodeSize, (current.y + dir[1]) * nodeSize);
          if (!isPositionWalkable(adjacent1) || !isPositionWalkable(adjacent2)) {
            continue;
          }
        }

        final double moveCost = (dir[0] != 0 && dir[1] != 0) ? 1.414 : 1.0;
        final double tentativeG = current.g + moveCost;

        final AStarNode? existingOpen = openSet.where((AStarNode n) => n == neighbor).firstOrNull;

        if (existingOpen == null) {
          neighbor.g = tentativeG;
          neighbor.h = ((neighbor.x - endNode.x).abs() + (neighbor.y - endNode.y).abs()).toDouble();
          openSet.add(neighbor);
        } else if (tentativeG < existingOpen.g) {
          existingOpen.g = tentativeG;
          existingOpen.parent = current;
        }
      }
    }

    return <Vector2>[];
  }

  bool isPositionWalkable(Vector2 feetPosition) {
    if (feetPosition.x < 0 ||
        feetPosition.y < 0 ||
        feetPosition.x > mapPixelWidth ||
        feetPosition.y > mapPixelHeight) {
      return false;
    }

    final Point64 point = Point64(
      feetPosition.x.round(),
      feetPosition.y.round(),
    );

    for (final Path64 blocker in navigationBlockers) {
      if (_isPointInPolygon(point, blocker)) {
        return false;
      }
    }

    return true;
  }

  bool canWalkBetween(Vector2 from, Vector2 to) {
    final Vector2 delta = to - from;
    final int steps = max(1, (delta.length / 4.0).ceil());

    for (int i = 1; i <= steps; i++) {
      final Vector2 samplePoint = from + (delta * (i / steps));
      if (!isPositionWalkable(samplePoint)) {
        return false;
      }
    }
    return true;
  }

  bool _isPointInPolygon(Point64 point, Path64 path) {
    if (path.isEmpty) return false;

    bool inside = false;
    final int nVert = path.length;
    final int testX = point.x;
    final int testY = point.y;

    for (int i = 0, j = nVert - 1; i < nVert; j = i++) {
      final Point64 vi = path[i];
      final Point64 vj = path[j];

      if (((vi.y > testY) != (vj.y > testY)) && (testX < (vj.x - vi.x) * (testY - vi.y) / (vj.y - vi.y) + vi.x)) {
        inside = !inside;
      }
    }
    return inside;
  }
}
