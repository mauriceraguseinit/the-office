import 'package:flutter/material.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/l10n/l10n.dart';
import 'package:the_office/office_game.dart';
import 'package:the_office/utils/assets.dart';
import 'package:the_office/utils/styles.dart';

class ElevatorOverlay extends StatelessWidget {
  const ElevatorOverlay({super.key, required this.game});
  final OfficeGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: Border.all(color: Colors.grey, width: 4),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'AUFZUG',
              style: GameStyles.inventoryTitleStyle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildFloorButton(context, '5', GameTiles.office),
            _buildFloorButton(context, '4', GameTiles.office),
            _buildFloorButton(context, '3', GameTiles.office),
            _buildFloorButton(context, '2', GameTiles.office),
            _buildFloorButton(context, '1', GameTiles.office),
            _buildFloorButton(context, 'E', GameTiles.office),
            _buildFloorButton(context, 'K', GameTiles.officeCellar),
            const SizedBox(height: 20),
            RetroButton(
              title: 'ABBRECHEN',
              onTap: () => game.overlays.remove('elevator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorButton(BuildContext context, String label, String mapAsset) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RetroButton(
        title: label,
        alignment: Alignment.center,
        onTap: () {
          game.overlays.remove('elevator');

          if (<String>['5', '3', '2', '1', 'E'].contains(label)) {
            game.showPlayerMessage(S.of(context).elevator_refusal);
          } else {
            game.loadLevel(mapAsset);
          }
        },
      ),
    );
  }
}
