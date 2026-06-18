import 'dart:ui';

import 'package:flame/components.dart';

import 'main.dart'; // Import für dein OfficeGame

class InventoryCursor extends PositionComponent with HasGameReference<OfficeGame> {
  // Wir verwalten das Sprite als interne Variable, nicht über die Vererbung
  Sprite? _cursorSprite;
  String? _currentLoadedPath;

  InventoryCursor() : super(priority: 9999) {
    // Wir setzen die Größe direkt im Konstruktor fest
    size = Vector2(32, 32);
    anchor = Anchor.center;
  }

  @override
  @override
  void update(double dt) {
    super.update(dt);

    final selectedItem = game.selectedItem;

    if (selectedItem != null) {
      // Nimmt jetzt die korrekten Bildschirm-Koordinaten aus dem Spiel
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

  // Manuelles Zeichnen: Flame stürzt hier niemals ab, selbst wenn _cursorSprite null ist!
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Nur rendern, wenn ein Sprite existiert UND kein Flutter-Overlay aktiv ist
    if (_cursorSprite != null && game.selectedItem != null && game.overlays.isActive('inventory') == false) {
      _cursorSprite!.render(canvas, size: size);
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
