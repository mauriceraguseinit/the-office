import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../interactiveObjects/interactive_object.dart';

class GameState extends ChangeNotifier {
  List<InventoryItem> ownedItems = <InventoryItem>[];
  InventoryItem? selectedItem;
  InteractiveObject? highlightedObject;
  bool isPlayerHighlighted = false;
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
