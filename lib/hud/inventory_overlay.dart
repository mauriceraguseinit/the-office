import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../office_game.dart';
import '../utils/config.dart';

class InventoryOverlay extends StatefulWidget {
  const InventoryOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  String _hoverText = '';

  @override
  Widget build(BuildContext context) {
    final List<InventoryItem> items = widget.game.ownedItems;
    final InventoryItem? selectedItem = widget.game.selectedItem;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Berechne den Skalierungsfaktor passend zum FixedResolutionViewport von Flame
        final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
        final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
        final double gameScale = min(scaleX, scaleY);

        // Feste virtuelle Wunschmaße für das Inventarfenster
        const double baseWidth = 450.0;
        const double baseHeight = 350.0;

        return MouseRegion(
          // Tracke die Mausbewegung relativ zum gesamten skalierten Overlay-Raum
          onHover: (PointerHoverEvent event) {
            widget.game.mousePosition = Vector2(event.localPosition.dx, event.localPosition.dy);
            setState(() {});
          },
          child: Stack(
            children: <Widget>[
              // 1. Das eigentliche Inventar-Fenster im Hintergrund (Mit skalierter Hitbox)
              Center(
                child: MouseRegion(
                  onExit: (_) {
                    if (widget.game.selectedItem != null) {
                      widget.game.overlays.remove('inventory');
                    }
                  },
                  child: SizedBox(
                    width: baseWidth * gameScale,
                    height: baseHeight * gameScale,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: baseWidth,
                        height: baseHeight,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              border: Border.all(color: const Color(0xFF1E1E1E), width: 6),
                            ),
                            child: Stack(
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'INVENTAR',
                                      style: TextStyle(
                                        fontFamily: 'PressStart2P',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const Divider(color: Color(0xFF1E1E1E), thickness: 4),

                                    Expanded(
                                      child: GridView.builder(
                                        itemCount: items.length,
                                        physics: const BouncingScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemBuilder: (BuildContext context, int index) {
                                          final InventoryItem item = items[index];
                                          final bool isCurrentlySelected = widget.game.selectedItem?.id == item.id;

                                          return MouseRegion(
                                            onEnter: (_) {
                                              setState(() {
                                                if (widget.game.selectedItem != null) {
                                                  if (widget.game.selectedItem!.id == item.id) {
                                                    _hoverText = 'BENUTZE ${item.name.toUpperCase()}';
                                                  } else {
                                                    _hoverText =
                                                        'BENUTZE ${widget.game.selectedItem!.name.toUpperCase()} MIT ${item.name.toUpperCase()}';
                                                  }
                                                } else {
                                                  _hoverText = 'BENUTZE ${item.name.toUpperCase()} MIT...';
                                                }
                                              });
                                            },
                                            onExit: (_) => setState(
                                              () => _hoverText = widget.game.selectedItem != null
                                                  ? 'BENUTZE ${widget.game.selectedItem!.name.toUpperCase()} MIT...'
                                                  : '',
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _handleItemClick(item),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isCurrentlySelected
                                                      ? Colors.orange.withValues(alpha: 0.5)
                                                      : const Color(0xFF1E1E1E).withValues(alpha: 0.1),
                                                  border: Border.all(
                                                    color: isCurrentlySelected
                                                        ? Colors.orange
                                                        : const Color(0xFF1E1E1E),
                                                    width: 4,
                                                  ),
                                                ),
                                                padding: const EdgeInsets.all(6),
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
                                          fontFamily: 'PressStart2P',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Schließen-Button (X) mit absolut korrekter Hitbox
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => widget.game.overlays.remove('inventory'),
                                    behavior: HitTestBehavior.opaque,
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
                                          fontFamily: 'PressStart2P',
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
                    ),
                  ),
                ),
              ),

              // 2. Das an der Maus klebende Item (Wird ebenfalls via Positioned frei im skalierten Stack platziert)
              if (selectedItem != null)
                Positioned(
                  left: widget.game.mousePosition.x - 24,
                  top: widget.game.mousePosition.y - 24,
                  width: 48,
                  height: 48,
                  child: IgnorePointer(
                    child: Image.asset(
                      selectedItem.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleItemClick(InventoryItem item) {
    final InventoryItem? activeSelection = widget.game.selectedItem;

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
        setState(() => _hoverText = 'DAS GEHT SO NICHT!');
      }
    }
  }
}
