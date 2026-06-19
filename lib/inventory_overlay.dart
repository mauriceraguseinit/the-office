import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'inventory_item.dart';
import 'office_game.dart'; // Importiere dein Hauptspiel für den Zugriff auf OfficeGame

class InventoryOverlay extends StatefulWidget {
  final OfficeGame game;
  const InventoryOverlay({super.key, required this.game});

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  String _hoverText = "";

  @override // Der doppelte `@override` wurde hier entfernt!
  Widget build(BuildContext context) {
    final items = widget.game.ownedItems;
    final selectedItem = widget.game.selectedItem;

    return MouseRegion(
      onHover: (event) {
        widget.game.mousePosition = Vector2(event.position.dx, event.position.dy);
        setState(() {});
      },
      child: Stack(
        children: [
          // 1. Das eigentliche Inventar-Fenster im Hintergrund
          Center(
            child: Container(
              width: 450,
              height: 350,
              padding: const EdgeInsets.all(6), // Etwas dickerer Retro-Rahmen
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                // Keine runden Ecken! Echte Pixel-Games sind eckig.
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  // Fetter, klobiger Innenrahmen für den CRT/NES-Look
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 6),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVENTAR',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 24, // Größer und wuchtiger
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const Divider(color: Color(0xFF1E1E1E), thickness: 4), // Dickere Trennlinie

                        Expanded(
                          child: GridView.builder(
                            itemCount: items.length,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isCurrentlySelected = widget.game.selectedItem?.id == item.id;

                              return MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    if (widget.game.selectedItem != null) {
                                      if (widget.game.selectedItem!.id == item.id) {
                                        _hoverText = "BENUTZE ${item.name.toUpperCase()}";
                                      } else {
                                        _hoverText =
                                            "BENUTZE ${widget.game.selectedItem!.name.toUpperCase()} MIT ${item.name.toUpperCase()}";
                                      }
                                    } else {
                                      _hoverText = "BENUTZE ${item.name.toUpperCase()} MIT...";
                                    }
                                  });
                                },
                                onExit: (_) => setState(
                                  () => _hoverText = widget.game.selectedItem != null
                                      ? "BENUTZE ${widget.game.selectedItem!.name.toUpperCase()} MIT..."
                                      : "",
                                ),
                                child: GestureDetector(
                                  onTap: () => _handleItemClick(item),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isCurrentlySelected
                                          ? Colors.orange.withValues(alpha: 0.5)
                                          : const Color(0xFF1E1E1E).withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: isCurrentlySelected ? Colors.orange : const Color(0xFF1E1E1E),
                                        width: 4, // Schön klobige Item-Ränder
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    // TRICK 1: FilterQuality.none zwingt Flutter dazu, das Bild PIXELIG zu skalieren!
                                    child: Image.asset(
                                      item.assetPath,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Container(
                          height: 40,
                          width: double.infinity,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _hoverText,
                            style: const TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Schließen-Button (X) im Arcade-Look
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => widget.game.overlays.remove('inventory'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
                          ),
                          child: const Text(
                            'X',
                            style: TextStyle(
                              color: Color(0xFFF5F5F5),
                              fontFamily: 'Courier New',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Das an der Maus klebende Item
          if (selectedItem != null)
            Positioned(
              left: widget.game.mousePosition.x - 24, // Größeres Sprite an der Maus (48 / 2)
              top: widget.game.mousePosition.y - 24,
              width: 48,
              height: 48,
              child: IgnorePointer(
                // TRICK 2: Auch hier FilterQuality.none für knackige Retro-Pixel an der Maus
                child: Image.asset(selectedItem.assetPath, fit: BoxFit.contain, filterQuality: FilterQuality.none),
              ),
            ),
        ],
      ),
    );
  }

  void _handleItemClick(InventoryItem item) {
    final activeSelection = widget.game.selectedItem;

    if (activeSelection == null) {
      widget.game.selectItem(item);
      setState(() {});
    } else if (activeSelection.id == item.id) {
      widget.game.resetSelection();
      setState(() {});
    } else {
      if (activeSelection.combinesWith == item.id || item.combinesWith == activeSelection.id) {
        if (activeSelection.onCombineSuccess != null) activeSelection.onCombineSuccess!(context);
        if (item.onCombineSuccess != null) item.onCombineSuccess!(context);

        widget.game.ownedItems.remove(activeSelection);
        widget.game.ownedItems.remove(item);
        widget.game.resetSelection();
        widget.game.overlays.remove('inventory');
      } else {
        setState(() => _hoverText = "DAS GEHT SO NICHT!"); // Schön in Retro-Schreibweise (Caps)
      }
    }
  }
}
