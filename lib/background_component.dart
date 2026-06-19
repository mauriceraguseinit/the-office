import 'dart:ui';

import 'package:flame/components.dart';

/// Der Hintergrund des Büros mit gekachelter Laminat-Textur
class BackgroundComponent extends Component {
  late Sprite _laminatSprite;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    debugMode = true;
    // Lädt das Bild aus dem Ordner assets/images/
    // Flame sucht automatisch im "assets/images/" Verzeichnis
    _laminatSprite = await Sprite.load('laminat.png');
    _isLoaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;

    // Hier bestimmen wir, wie groß die Kacheln gezeichnet werden sollen.
    // Wenn dein Bild z.B. 512x512 Pixel groß ist, kannst du es hier skalieren,
    // damit die Dielen im Spiel nicht zu riesig wirken.
    final double tileWidth = 128; // Breite einer Kachel im Spiel
    final double tileHeight = 128; // Höhe einer Kachel im Spiel

    // Wir füllen den gesamten Bildschirm (von 0 bis 2000 Pixeln als Puffer)
    // In einem echten Spiel würde man sich hier an der Raum- oder Bildschirmgröße orientieren.
    for (double x = 0; x < 2000; x += tileWidth) {
      for (double y = 0; y < 2000; y += tileHeight) {
        _laminatSprite.render(canvas, position: Vector2(x, y), size: Vector2(tileWidth, tileHeight));
      }
    }
  }
}
