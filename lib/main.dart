import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hendrik.dart';
import 'package:the_office/speech_bubble.dart';
import 'package:the_office/tobi.dart';
import 'package:the_office/trigger_zone.dart';
import 'package:the_office/util.dart';
import 'package:the_office/vertical_wall.dart';

import 'default_component.dart';
import 'desk_daniel.dart';

void main() {
  runApp(
    GameWidget(
      game: OfficeGame(),
      overlayBuilderMap: {
        'tobi': (context, OfficeGame game) => RetroSpeechBubble(
          text: 'Nerv mich nicht. Ich bereite gerade meinen nächsten Zahnarzttermin vor.',
          onClose: () {
            game.overlays.remove('tobi');
          },
        ),
        'daniel': (context, OfficeGame game) => RetroSpeechBubble(
          text:
              'Irgendwie hab ich hunger glaube ich. Mal sehen ob ich noch ne Dose Tuhnfisch habe, die ich zu meinem Joghurt essen kann.',
          onClose: () {
            game.overlays.remove('daniel');
          },
        ),
        'intro': (context, OfficeGame game) => RetroSpeechBubble(
          actions: [RetroAction(title: 'Starten', onTap: () => game.overlays.remove('intro'))],
          text:
              'Willkommen im Büro.\n\nHeute wird es wieder sehr heiß!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
          onClose: () {
            game.overlays.remove('intro');
          },
        ),
      },
      initialActiveOverlays: const ['intro'],
    ),
  );
}

/// Das Hauptspiel-Objekt managt die Welt und die Events
class OfficeGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late TextComponent statusText;
  bool isDeskLocked = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Hintergrund erstellen
    final background = BackgroundComponent();

    // 2. Schreibtisch erstellen
    final deskBottomLeft = DeskComponent(position: Vector2(300, 230), size: Vector2(100, 60))..angle = Units.degree90;

    final deskBottomRight = DeskComponent(position: Vector2(300, 380), size: Vector2(100, 60))..angle = Units.degree270;
    final deskTopLeft = DeskComponent(position: Vector2(300, 70), size: Vector2(100, 60))..angle = Units.degree90;
    final leftWall = VerticalWall(position: Vector2(0, -90), size: Vector2(10, 790));
    final rightWall = VerticalWall(position: Vector2(600, -90), size: Vector2(10, 790));
    final door = DefaultComponent(
      position: Vector2(380, 600),
      size: Vector2(100, 100),
      hitBox: false,
      wallElement: WallElement.door,
    )..priority = 12;
    final window = DefaultComponent(
      position: Vector2(95 * 2, -100),
      size: Vector2(100, 100),
      hitBox: false,
      wallElement: WallElement.window,
    );
    final window2 = DefaultComponent(
      position: Vector2(95 * 4, -100),
      size: Vector2(100, 100),
      hitBox: false,
      wallElement: WallElement.window,
    );

    List<DefaultComponent> wallsTop = List.generate(
      10,
      (index) => DefaultComponent(position: Vector2(0 + index * 95, -100), size: Vector2(100, 100)),
    );

    List<DefaultComponent> wallsBottomLeft = List.generate(
      4,
      (index) => DefaultComponent(position: Vector2(0 + index * 95, 600), size: Vector2(100, 100)),
    );
    List<DefaultComponent> wallsBottomRight = List.generate(
      5,
      (index) => DefaultComponent(position: Vector2(475 + index * 95, 600), size: Vector2(100, 100)),
    );

    // 3. Spieler erstellen (Dev) - ca. 50% größer
    final player = Hendrik(position: Vector2(320, 400), size: Vector2(40, 75));

    // Alles zur World hinzufügen
    //Ground
    world.add(background);

    //desks
    world.add(deskBottomLeft);

    world.add(deskBottomRight);
    world.add(deskTopLeft);

    //door
    world.add(door);

    //walls
    for (var wall in wallsTop) {
      world.add(wall);
    }

    world.add(leftWall);
    world.add(rightWall);

    for (var wall in wallsBottomLeft) {
      world.add(wall);
    }
    for (var wall in wallsBottomRight) {
      world.add(wall);
    }

    //windows
    world.add(window);
    world.add(window2);

    //player
    world.add(player);

    _buildNpcs();
    //npcs

    // Die Kamera heftet sich an die Fersen des Spielers
    camera.follow(player);

    _buildHud();
  }

  // Methode um den PC-Status zu toggeln
  void toggleScreenLock() {
    isDeskLocked = !isDeskLocked;
    if (isDeskLocked) {
      statusText.text = 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)';
    } else {
      statusText.text = 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)';
    }
  }

  void _buildHud() {
    // 4. UI-Texte erstellen
    statusText = TextComponent(
      text: 'PC-Status: Entsperrt (Gefahr!)',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final infoText = TextComponent(
      text: 'BEWEGUNG: WASD/Pfeiltasten | LEERTASTE: PC Sperren/Entsperren\nAKTION: Taste E',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    // WICHTIG: Die Texte werden jetzt an das VIEWPORT der Kamera gehängt!
    // Dadurch wandern sie garantiert in den absoluten Vordergrund (HUD)
    camera.viewport.add(statusText);
    camera.viewport.add(infoText);
  }

  void _buildNpcs() {
    // 1. Tobi ganz normal erstellen und zur World hinzufügen
    final tobiNpc = Tobi(position: Vector2(520, 100), size: Vector2(Tobi.frameWidth * 0.15, Tobi.pngHeight * 0.15));
    world.add(tobiNpc);

    // TriggerZone als eigenständiges Objekt in die World legen
    final tobiTrigger = TriggerZone(
      target: tobiNpc,
      padding: 25.0,
      onAction: () {
        overlays.add('tobi');
      },
    );
    world.add(tobiTrigger);

    // 2. Daniels Tisch erstellen, rotieren und zur World hinzufügen
    final deskTopRight = DeskDaniel(
      position: Vector2(300, 220),
      size: Vector2(DeskDaniel.frameWidth * 0.28, DeskDaniel.pngHeight * 0.28),
    )..angle = Units.degree270;
    world.add(deskTopRight);

    // TriggerZone für Daniel ebenfalls in die World legen
    final danielTrigger = TriggerZone(
      target: deskTopRight,
      padding: 35.0, // Bei Tischen gerne etwas mehr Padding, da sie breiter sind
      onAction: () {
        overlays.add('daniel'); // Oder dein Daniel-Overlay
      },
    );
    world.add(danielTrigger);
  }
}

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

/// Der Schreibtisch (Desk)
class DeskComponent extends SpriteComponent {
  DeskComponent({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    sprite = await Sprite.load('desk.png');
    final original = sprite!.srcSize;
    size = Vector2(original.x * 0.5, original.y * 0.5);

    add(RectangleHitbox());
  }
}
