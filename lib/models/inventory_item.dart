import 'package:flutter/material.dart';

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.assetPath,
    this.combinesWith,
    this.onCombineSuccess,
  });
  final String id;
  final String name;
  final String assetPath; // z.B. 'assets/images/items/mate.png'
  final String? combinesWith; // ID des Items, mit dem es kombinierbar ist
  final Function(BuildContext context)? onCombineSuccess;
}
