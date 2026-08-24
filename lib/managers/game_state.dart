import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../interactiveObjects/interactive_object.dart';
import '../interactiveObjects/inventory_item_catalogue.dart';
import '../models/inventory_item.dart';

enum Flags {
  plantHasMate,
  plantHasWaterMate,
  fullBladder,
  tobiGone,
  fishCanGone,
  notebookOnDesk,
}

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
  bool isMusicEnabled = true;

  final Set<String> _flags = <String>{};
  final Map<String, dynamic> _variables = <String, dynamic>{};

  bool hasFlag(String flag) => _flags.contains(flag);

  void setFlag(String flag, {bool value = true}) {
    if (value) {
      if (_flags.add(flag)) notifyListeners();
    } else {
      if (_flags.remove(flag)) notifyListeners();
    }
  }

  void removeFlag(String flag) => setFlag(flag, value: false);

  dynamic getVariable(String key) => _variables[key];

  void setVariable(String key, dynamic value) {
    if (_variables[key] == value) return;
    _variables[key] = value;
    notifyListeners();
  }

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

  void toggleMusic() {
    isMusicEnabled = !isMusicEnabled;
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownedItems': ownedItems.map((InventoryItem item) => item.id).toList(),
      'isDeskLocked': isDeskLocked,
      'isMusicEnabled': isMusicEnabled,
      'playerPosition': playerPosition != null
          ? <String, double>{'x': playerPosition!.x, 'y': playerPosition!.y}
          : null,
      'flags': _flags.toList(),
      'variables': _variables,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    if (json['ownedItems'] != null) {
      ownedItems = (json['ownedItems'] as List<dynamic>).map((dynamic id) {
        return InventoryItemCatalogue.itemForId(InventoryItemCatalogue.itemTypeForId(id as String)!);
      }).toList();
    }
    isDeskLocked = json['isDeskLocked'] as bool? ?? false;
    isMusicEnabled = json['isMusicEnabled'] as bool? ?? true;
    if (json['playerPosition'] != null) {
      final Map<String, dynamic> pos = json['playerPosition'] as Map<String, dynamic>;
      playerPosition = Vector2(pos['x'] as double, pos['y'] as double);
    }

    if (json['flags'] != null) {
      _flags.clear();
      _flags.addAll((json['flags'] as List<dynamic>).cast<String>());
    }

    if (json['variables'] != null) {
      _variables.clear();
      _variables.addAll(json['variables'] as Map<String, dynamic>);
    }
    notifyListeners();
  }
}
