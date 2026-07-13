import 'package:flutter/foundation.dart';

import '../interactiveObjects/interactive_object.dart';
import '../models/inventory_item.dart';

class GameState extends ChangeNotifier {
  List<InventoryItem> ownedItems = <InventoryItem>[];
  InventoryItem? selectedItem;
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
}
