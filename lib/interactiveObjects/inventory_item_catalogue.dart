import 'package:flutter/cupertino.dart';

import '../models/inventory_item.dart';

enum InventoryItemType {
  mate,
  mateEmpty,
  mateWater,
}

class InventoryItemCatalogue {
  static InventoryItemType? itemTypeForId(String inventoryItem) {
    final List<String> values = InventoryItemType.values
        .map(
          (InventoryItemType e) => e.toString(),
        )
        .toList();
    if (values.contains(inventoryItem)) {
      return InventoryItemType.values.toList()[values.indexOf(inventoryItem)];
    }
    debugPrint('Iventory Type unknown');
    return null;
  }

  static InventoryItem itemForId(InventoryItemType inventoryItemType) {
    switch (inventoryItemType) {
      case InventoryItemType.mate:
        return InventoryItem(
          id: InventoryItemType.mate.toString(),
          name: 'Mate',
          assetPath: 'assets/images/mate_full.png',
        );
      case InventoryItemType.mateEmpty:
        return InventoryItem(
          id: InventoryItemType.mateEmpty.toString(),
          name: 'leere Mate',
          assetPath: 'assets/images/mate_empty.png',
        );
      case InventoryItemType.mateWater:
        return InventoryItem(
          id: InventoryItemType.mateWater.toString(),
          name: 'Klowasser-Mate',
          assetPath: 'assets/images/mate_water.png',
        );
    }
  }
}
