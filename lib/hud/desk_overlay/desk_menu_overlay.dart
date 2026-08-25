import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:the_office/office_game.dart';
import 'package:the_office/utils/config.dart';

import '../../utils/styles.dart';

class DeskMenuOverlay extends StatefulWidget {
  const DeskMenuOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  State<DeskMenuOverlay> createState() => _DeskMenuOverlayState();
}

class _DeskMenuOverlayState extends State<DeskMenuOverlay> {
  late final DeskMenuGame _deskGame;

  @override
  void initState() {
    super.initState();
    _deskGame = DeskMenuGame(mainGame: widget.game);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          GameWidget<DeskMenuGame>(game: _deskGame),
          Positioned(
            top: 20,
            left: 20,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 40),
                onPressed: () => widget.game.overlays.remove('desk_menu'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeskMenuGame extends FlameGame<World> with HasGameReference<OfficeGame>, MouseMovementDetector, TapCallbacks {
  DeskMenuGame({required this.mainGame});
  final OfficeGame mainGame;

  late TiledComponent<FlameGame<World>> deskMap;
  String? hoveredObjectName;
  late TextComponent label;

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(GameConfig.resolution.width, GameConfig.resolution.height),
    );

    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    camera.viewfinder.zoom = 1.0;

    deskMap = await TiledComponent.load(
      'desk_overlay.tmx',
      Vector2(1280, 720),
    );
    world.add(deskMap);

    final ObjectGroup? clickableLayer = deskMap.tileMap.getLayer<ObjectGroup>('clickable');
    if (clickableLayer != null) {
      for (final TiledObject obj in clickableLayer.objects) {
        if (obj.isPolygon) {
          final List<Vector2> points = obj.polygon.map((Point p) => Vector2(p.x, p.y)).toList();

          final _ClickableRegion regionComp = _ClickableRegion(
            points: points,
            name: obj.name,
            position: Vector2(obj.x, obj.y),
            onPressed: () {
              if (obj.name == 'Merge Requests') {
                mainGame.openOverlay('tetris', closeOthers: false);
              }
            },
            onHoverChanged: (bool isHovered) {
              hoveredObjectName = isHovered ? obj.name : (hoveredObjectName == obj.name ? null : hoveredObjectName);
            },
          );

          world.add(regionComp);
        }
      }
    }

    // Label als HUD Element hinzufügen
    label = TextComponent(
      text: '',
      position: Vector2(GameConfig.resolution.width / 2, GameConfig.resolution.height - 80),
      anchor: Anchor.center,
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: GameStyles.mainFont,
          shadows: <Shadow>[
            Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
          ],
        ),
      ),
    );

    // Dem Viewport hinzufügen für HUD-Effekt
    camera.viewport.add(label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    label.text = hoveredObjectName ?? '';
  }
}

class _ClickableRegion extends PositionComponent with HoverCallbacks, TapCallbacks {
  _ClickableRegion({
    required List<Vector2> points,
    required this.name,
    required Vector2 position,
    required this.onPressed,
    required this.onHoverChanged,
  }) : super(position: position, priority: 10) {
    double minX = points.first.x, maxX = points.first.x;
    double minY = points.first.y, maxY = points.first.y;
    for (final Vector2 p in points) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
    }
    size = Vector2(maxX - minX, maxY - minY);

    visual = PolygonComponent(
      points,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    add(visual);
  }

  late final PolygonComponent visual;
  final String name;
  final VoidCallback onPressed;
  final Function(bool) onHoverChanged;

  @override
  bool containsPoint(Vector2 point) {
    return visual.containsPoint(point - position);
  }

  @override
  void onHoverEnter() {
    onHoverChanged(true);
    visual.paint.color = Colors.yellowAccent.withValues(alpha: 0.3);
    visual.paint.style = PaintingStyle.fill;
  }

  @override
  void onHoverExit() {
    onHoverChanged(false);
    visual.paint.color = Colors.transparent;
    visual.paint.style = PaintingStyle.stroke;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }
}
