import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../inventory_cursor.dart';
import '../office_game.dart';
import '../utils/config.dart';
import 'clickable_minimap.dart';
import 'mobile_inventory_button.dart';

class OfficeHud extends PositionComponent with HasGameReference<OfficeGame> {
  late TextComponent<TextRenderer> interactionNameText;
  late TextComponent<TextRenderer> statusText;
  late ClickableMinimap minimap;

  @override
  Future<void> onLoad() async {
    // 1. Info Text
    final TextComponent<TextPaint> infoText = TextComponent<TextPaint>(
      text: 'BEWEGUNG: WASD / Touch (Gedrückthalten)\nAKTION: Taste E\nINVENTAR: Taste I',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontFamily: 'PressStart2P',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0)],
        ),
      ),
    );
    add(infoText..priority = 1000);

    // 2. Interaction Hint
    interactionNameText = TextComponent<TextRenderer>(
      text: '',
      position: Vector2(
        GameConfig.resolution.width / 2,
        GameConfig.resolution.height - 140,
      ),
      anchor: Anchor.center,
      priority: 1001,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Color(0xFFFFFFAA),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    add(interactionNameText);

    // 3. Status Text (PC-Lock Info)
    statusText = TextComponent<TextRenderer>(
      text: 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0)],
        ),
      ),
    );
    //  add(statusText..priority = 1000);

    // 4. Inventory Cursor
    add(InventoryCursor()..priority = 1000);

    // 5. Mobile Inventory Button
    final MobileInventoryButton mobileBagButton = MobileInventoryButton(
      position: Vector2(GameConfig.resolution.width / 2, GameConfig.resolution.height - 80),
      onPressed: () {
        game.openInventory();
      },
    );
    add(mobileBagButton..priority = 1000);
  }

  void setupMinimap(CameraComponent minimapCamera, VoidCallback onMinimapPressed) {
    minimap = ClickableMinimap(
      minimapCamera: minimapCamera,
      size: Vector2(200, 200),
      position: Vector2(
        GameConfig.resolution.width - 220,
        GameConfig.resolution.height - 220,
      ),
      onMinimapPressed: onMinimapPressed,
    );
    minimap.priority = 1000;
    add(minimap);
  }

  void updateInteractionHint(String text) {
    interactionNameText.text = text;
  }

  void updateStatusText(String text) {
    statusText.text = text;
  }
}
