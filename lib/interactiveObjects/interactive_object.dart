import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import '../office_game.dart';
import '../trigger_zone.dart';

abstract class InteractiveObject extends SpriteComponent
    with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  InteractiveObject({
    required super.position,
    required Sprite super.sprite,
    super.size,
    this.priorityOffset = 0,
  });

  Map<String, Widget Function(BuildContext, Game)> get dialogs;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    for (String key in dialogs.keys) {
      game.overlays.addEntry(key, dialogs[key]!);
    }

    // Y-Sorting + Layer-Offset zusammenrechnen
    priority = (y + height / 2).toInt() + priorityOffset;

    debugMode = false;
    anchor = Anchor.centerRight;
  }

  final int priorityOffset;

  @override
  void onTapDown(TapDownEvent event);
}
