import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'inventory_item.dart';
import 'main.dart'; // Importiere dein Hauptspiel für den Zugriff auf OfficeGame

class InventoryOverlay extends StatefulWidget {
  final OfficeGame game;
  const InventoryOverlay({super.key, required this.game});

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  String _hoverText = "";

  @override
  @override
  Widget build(BuildContext context) {
    final items = widget.game.ownedItems;
    final selectedItem = widget.game.selectedItem;

    return MouseRegion(
      onHover: (event) {
        // Wir aktualisieren die Position im Spiel
        widget.game.mousePosition = Vector2(event.position.dx, event.position.dy);
        // WICHTIG: setState aufrufen, damit das Flutter-Cursorbild hier flüssig mitwandert!
        setState(() {});
      },
      child: Stack(
        children: [
          // 1. Das eigentliche Inventar-Fenster im Hintergrund
          Center(
            child: Container(
              width: 450,
              height: 350,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 4),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const Divider(color: Color(0xFF1E1E1E), thickness: 2),

                        Expanded(
                          child: GridView.builder(
                            itemCount: items.length,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isCurrentlySelected = widget.game.selectedItem?.id == item.id;

                              return MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    if (widget.game.selectedItem != null) {
                                      if (widget.game.selectedItem!.id == item.id) {
                                        _hoverText = "Benutze ${item.name}";
                                      } else {
                                        _hoverText = "Benutze ${widget.game.selectedItem!.name} mit ${item.name}";
                                      }
                                    } else {
                                      _hoverText = "Benutze ${item.name} with...";
                                    }
                                  });
                                },
                                onExit: (_) => setState(
                                  () => _hoverText = widget.game.selectedItem != null
                                      ? "Benutze ${widget.game.selectedItem!.name} mit..."
                                      : "",
                                ),
                                child: GestureDetector(
                                  onTap: () => _handleItemClick(item),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isCurrentlySelected
                                          ? Colors.orange.withOpacity(0.4)
                                          : const Color(0xFF1E1E1E).withOpacity(0.1),
                                      border: Border.all(
                                        color: isCurrentlySelected ? Colors.orange : const Color(0xFF1E1E1E),
                                        width: isCurrentlySelected ? 3 : 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(item.assetPath, fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Container(
                          height: 30,
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

                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => widget.game.overlays.remove('inventory'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            border: Border.all(color: const Color(0xFFF5F5F5), width: 1),
                          ),
                          child: const Text(
                            ' X ',
                            style: TextStyle(
                              color: Color(0xFFF5F5F5),
                              fontFamily: 'Courier New',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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

          // 2. TRICK: Wenn im Overlay ein Item aktiv ist, zeichnen wir es direkt in FLUTTER on top!
          if (selectedItem != null)
            Positioned(
              left: widget.game.mousePosition.x - 16, // Mittig auf der Maus (32 / 2)
              top: widget.game.mousePosition.y - 16,
              width: 32,
              height: 32,
              child: IgnorePointer(
                // Verhindert, dass das Bild Klicks blockiert
                child: Image.asset(selectedItem.assetPath, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  void _handleItemClick(InventoryItem item) {
    final activeSelection = widget.game.selectedItem;

    if (activeSelection == null) {
      // 1. Fall: Kein Item ausgewählt -> Dieses Item auswählen
      widget.game.selectItem(item);
      setState(() {});
    } else if (activeSelection.id == item.id) {
      // 2. Fall: Dasselbe Item noch mal anklicken -> Abwählen
      widget.game.resetSelection();
      setState(() {});
    } else {
      // 3. Fall: Ein anderes Item ist bereits ausgewählt -> Kombinieren prüfen!
      if (activeSelection.combinesWith == item.id || item.combinesWith == activeSelection.id) {
        // Kombination erfolgreich!
        if (activeSelection.onCombineSuccess != null) activeSelection.onCombineSuccess!(context);
        if (item.onCombineSuccess != null) item.onCombineSuccess!(context);

        // Items aus dem Inventar löschen (Beispiel)
        widget.game.ownedItems.remove(activeSelection);
        widget.game.ownedItems.remove(item);
        widget.game.resetSelection();
        widget.game.overlays.remove('inventory');
      } else {
        // Kombination nicht möglich -> Sound oder Text "Das geht so nicht!"
        setState(() => _hoverText = "Das kann ich nicht miteinander kombinieren!");
      }
    }
  }
}
