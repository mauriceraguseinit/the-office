import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../inventory_cursor.dart';
import '../managers/game_state.dart';
import '../managers/service_locator.dart';
import '../models/inventory_item.dart';
import '../office_game.dart';
import '../utils/config.dart';
import '../utils/styles.dart';
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
      textRenderer: GameStyles.infoRenderer,
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
      textRenderer: GameStyles.interactionRenderer,
    );
    add(interactionNameText);

    // 3. Status Text (PC-Lock Info)
    statusText = TextComponent<TextRenderer>(
      text: '',
      position: Vector2(20, 20),
      textRenderer: GameStyles.statusRenderer,
    );
    //add(statusText..priority = 1000);

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

  @override
  void onMount() {
    super.onMount();
    sl<GameState>().addListener(_onStateChanged);
    _onStateChanged(); // Initial update
  }

  @override
  void onRemove() {
    sl<GameState>().removeListener(_onStateChanged);
    super.onRemove();
  }

  void _onStateChanged() {
    final GameState state = sl<GameState>();

    // Update Status Text
    statusText.text = state.isDeskLocked
        ? 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)'
        : 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)';

    // Update Interaction Hint
    interactionNameText.text = _buildInteractionHint(state);
  }

  String _buildInteractionHint(GameState state) {
    final String objectName = state.isPlayerHighlighted
        ? 'Hendrik'
        : (state.highlightedObject?.displayName.trim() ?? '');
    final InventoryItem? item = state.selectedItem;

    // Inventar offen: nur Objektname (oder leer), kein Benutze-Text.
    if (game.overlays.isActive('inventory')) {
      return objectName;
    }

    if (item == null) return objectName;

    final String itemName = item.name.toUpperCase();
    if (objectName.isEmpty) return 'BENUTZE $itemName MIT...';
    return 'BENUTZE $itemName MIT ${objectName.toUpperCase()}';
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
}
