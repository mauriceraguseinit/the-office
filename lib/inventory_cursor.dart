import 'dart:ui';

import 'package:flame/components.dart';
import 'package:the_office/models/inventory_item.dart';

import 'office_game.dart';

class InventoryCursor extends PositionComponent with HasGameReference<OfficeGame> {
  InventoryCursor() : super(priority: 9999) {
    size = Vector2(32, 32);
    anchor = Anchor.center;
  }

  Sprite? _cursorSprite;
  String? _currentLoadedPath;

  @override
  void update(double dt) {
    super.update(dt);

    final InventoryItem? selectedItem = game.selectedItem;

    if (selectedItem != null) {
      position = game.mousePosition;

      final String filename = selectedItem.assetPath.split('/').last;
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

    final bool isAnyOverlayOpen = game.overlays.activeOverlays.isNotEmpty;

    if (_cursorSprite != null && game.selectedItem != null && !isAnyOverlayOpen) {
      // FilterQuality.none sorgt für den scharfen, unverpixelten Retro-Look beim Skalieren des Sprites
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
