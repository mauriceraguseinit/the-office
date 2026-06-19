import 'dart:ui';

import 'package:flame/components.dart';

import 'office_game.dart';

class InventoryCursor extends PositionComponent with HasGameReference<OfficeGame> {
  Sprite? _cursorSprite;
  String? _currentLoadedPath;

  InventoryCursor() : super(priority: 9999) {
    size = Vector2(32, 32);
    anchor = Anchor.center;
  }

  @override // HIER: Der doppelte `@override` wurde entfernt
  void update(double dt) {
    super.update(dt);

    final selectedItem = game.selectedItem;

    if (selectedItem != null) {
      position = game.mousePosition;

      final filename = selectedItem.assetPath.split('/').last;
      if (_currentLoadedPath != filename) {
        _loadCursorSprite(filename);
      }
    } else {
      _cursorSprite = null;
      _currentLoadedPath = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Wir prüfen, ob IRGENDEIN Overlay aktiv ist (z.B. 'inventory', 'intro', oder Dialog-Meldungen)
    final isAnyOverlayOpen = game.overlays.activeOverlays.isNotEmpty;

    // Nur rendern, wenn ein Sprite existiert UND gerade absolut kein Overlay/Dialog im Weg ist
    if (_cursorSprite != null && game.selectedItem != null && !isAnyOverlayOpen) {
      // TRICK: overridePaint mit FilterQuality.none sorgt für den perfekten, scharfen Pixel-Look in der Welt
      _cursorSprite!.render(canvas, size: size, overridePaint: Paint()..filterQuality = FilterQuality.none);
    }
  }

  Future<void> _loadCursorSprite(String filename) async {
    _currentLoadedPath = filename;
    try {
      _cursorSprite = await game.loadSprite(filename);
    } catch (e) {
      _cursorSprite = null;
    }
  }
}
