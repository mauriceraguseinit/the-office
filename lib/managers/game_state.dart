import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../interactiveObjects/interactive_object.dart';
import '../interactiveObjects/inventory_item_catalogue.dart';
import '../models/inventory_item.dart';

class GameState extends ChangeNotifier {
  List<InventoryItem> ownedItems = <InventoryItem>[];
  InventoryItem? selectedItem;
  Vector2? playerPosition;
  InteractiveObject? _highlightedObject;
  InteractiveObject? get highlightedObject => _highlightedObject;
  set highlightedObject(InteractiveObject? value) {
    if (_highlightedObject == value) return;
    _highlightedObject = value;
    notifyListeners();
  }

  bool _isPlayerHighlighted = false;
  bool get isPlayerHighlighted => _isPlayerHighlighted;
  set isPlayerHighlighted(bool value) {
    if (_isPlayerHighlighted == value) return;
    _isPlayerHighlighted = value;
    notifyListeners();
  }

  bool isDeskLocked = false;
  String playerMessage = '';

  void selectItem(InventoryItem? item) {
    selectedItem = item;
    notifyListeners();
  }

  void resetSelection() {
    selectedItem = null;
    notifyListeners();
  }

  void toggleDeskLock() {
    isDeskLocked = !isDeskLocked;
    notifyListeners();
  }

  void setPlayerMessage(String message) {
    playerMessage = message;
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownedItems': ownedItems.map((InventoryItem item) => item.id).toList(),
      'isDeskLocked': isDeskLocked,
      'playerPosition': playerPosition != null ? <String, double>{'x': playerPosition!.x, 'y': playerPosition!.y} : null,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    if (json['ownedItems'] != null) {
      ownedItems = (json['ownedItems'] as List<dynamic>).map((dynamic id) {
        return InventoryItemCatalogue.itemForId(InventoryItemCatalogue.itemTypeForId(id as String)!);
      }).toList();
    }
    isDeskLocked = json['isDeskLocked'] as bool? ?? false;
    if (json['playerPosition'] != null) {
      final Map<String, dynamic> pos = json['playerPosition'] as Map<String, dynamic>;
      playerPosition = Vector2(pos['x'] as double, pos['y'] as double);
    }
    notifyListeners();
  }
}
