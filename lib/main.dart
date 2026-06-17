import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_office/util.dart';

void main() {
  // Startet das Spiel im Flutter-Framework
  runApp(GameWidget(game: OfficeGame()));
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
    final desk = DeskComponent(position: Vector2(200, 230), size: Vector2(100, 60))..angle = Units.degree90;
    final desk2 = DeskComponent(position: Vector2(200, 220), size: Vector2(100, 60))..angle = Units.degree270;
    final desk3 = DeskComponent(position: Vector2(200, 380), size: Vector2(100, 60))..angle = Units.degree270;
    final desk4 = DeskComponent(position: Vector2(200, 70), size: Vector2(100, 60))..angle = Units.degree90;
    final door = DoorComponent(position: Vector2(380, 600), size: Vector2(100, 100), hitBox: false);
    final window = WallComponent(
      position: Vector2(95 * 2, -100),
      size: Vector2(100, 100),
      hitBox: false,
      wallElement: WallElement.window,
    );

    List<WallComponent> walls = List.generate(
      10,
      (index) => WallComponent(position: Vector2(0 + index * 95, -100), size: Vector2(100, 100)),
    );

    List<WallComponent> walls2 = List.generate(
      4,
      (index) => WallComponent(position: Vector2(0 + index * 95, 600), size: Vector2(100, 100)),
    );
    List<WallComponent> walls3 = List.generate(
      5,
      (index) => WallComponent(position: Vector2(475 + index * 95, 600), size: Vector2(100, 100)),
    );

    // 3. Spieler erstellen (Dev) - ca. 50% größer
    final player = DevPlayer(position: Vector2(320, 300), size: Vector2(40, 75));

    // Alles zur World hinzufügen
    world.add(background);
    world.add(desk);
    world.add(desk2);
    world.add(desk3);
    world.add(desk4);

    world.add(door);
    for (var wall in walls) {
      world.add(wall);
    }
    for (var wall in walls2) {
      world.add(wall);
    }
    for (var wall in walls3) {
      world.add(wall);
    }
    world.add(window);
    world.add(player);
    world.add(Tobi(position: Vector2(520, 100), size: Vector2(40, 75)));

    // Die Kamera heftet sich an die Fersen des Spielers
    camera.follow(player);

    // 4. UI-Texte erstellen
    statusText = TextComponent(
      text: 'PC-Status: Entsperrt (Gefahr!)',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final infoText = TextComponent(
      text: 'BEWEGUNG: WASD/Pfeiltasten | LEERTASTE: PC Sperren/Entsperren',
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

  // Methode um den PC-Status zu toggeln
  void toggleScreenLock() {
    isDeskLocked = !isDeskLocked;
    if (isDeskLocked) {
      statusText.text = 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)';
    } else {
      statusText.text = 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)';
    }
  }
}

/// Der Hintergrund des Büros mit gekachelter Laminat-Textur
class BackgroundComponent extends Component {
  late Sprite _laminatSprite;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
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

enum WallElement { wall, window }

class WallComponent extends SpriteComponent {
  WallComponent({
    required super.position,
    required super.size,
    this.hitBox = true,
    this.wallElement = WallElement.wall,
  });

  final bool hitBox;
  final WallElement wallElement;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    sprite = await Sprite.load(switch (wallElement) {
      WallElement.wall => 'wall.png',
      WallElement.window => 'window.png',
    });
    final original = sprite!.srcSize;
    size = Vector2(original.x * 1, original.y * 1);
    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}

class DoorComponent extends SpriteComponent {
  DoorComponent({required super.position, required super.size, this.hitBox = true});

  final bool hitBox;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 10;
    sprite = await Sprite.load('door.png');
    final original = sprite!.srcSize;
    size = Vector2(original.x * 1, original.y * 1);
    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}

class Tobi extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame> {
  Tobi({required super.position, required super.size, this.hitBox = true});

  final bool hitBox;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 10;
    final anim = await game.loadSpriteAnimation(
      'tobi_idle.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(1488 / 4, 495)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}

enum Direction { left, right, up, down }

/// Der Spieler (Flutter-Entwickler) mit Tastatur-Steuerung
/// Der Spieler mit echten Lauf-Animationen
/// Der Spieler (Flutter-Entwickler) nutzt jetzt Flame's fertige SpriteAnimationGroupComponent.
/// Das ist der sauberste Weg für Richtungs-Animationen!
/// Der Spieler (Flutter-Entwickler) nutzt jetzt Flame's fertige SpriteAnimationGroupComponent.
class DevPlayer extends SpriteAnimationGroupComponent<Direction>
    with KeyboardHandler, HasGameReference<OfficeGame>, CollisionCallbacks {
  DevPlayer({required super.position, required super.size});

  final Vector2 _velocity = Vector2.zero();
  final double _speed = 200.0;
  double _currentDt = 0.0;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Prüfen, ob das andere Objekt eine Wand ist
    if (other.children.any((component) => component is RectangleHitbox)) {
      // Hier stoppst du die Bewegung des Spielers
      // Beispiel: Position auf den vorherigen Frame zurücksetzen
      position -= _velocity * _speed * _currentDt;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Wir definieren die gewünschte Ziel-Höhe des Spielers im Spiel (ca. 50% größer als vorher)
    const double targetHeight = 75.0;

    // 1. DOWN Animation (Original Frame: 206 x 229)
    // Wir berechnen die perfekte Breite: (206 / 229) * 75 = ca. 67.4
    const double widthDown = (206 / 229) * targetHeight;
    final animDown = await game.loadSpriteAnimation(
      'down.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(206, 229)),
    );

    // 2. UP Animation (Original Frame: 190 x 256)
    // Perfekte Breite: (190 / 256) * 75 = ca. 55.6
    final animUp = await game.loadSpriteAnimation(
      'up.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(190, 256)),
    );

    // 3. LEFT Animation (Original Frame: 139 x 261)
    // Perfekte Breite: (139 / 261) * 75 = ca. 39.9
    final animLeft = await game.loadSpriteAnimation(
      'left.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    // 4. RIGHT Animation (Identisch zu Left)
    final animRight = await game.loadSpriteAnimation(
      'right.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {Direction.down: animDown, Direction.up: animUp, Direction.left: animLeft, Direction.right: animRight};

    // WICHTIG: Wir setzen die Standard-Größe beim Start auf die Down-Maße
    size = Vector2(widthDown, targetHeight);
    current = Direction.down;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    const double targetHeight = 75.0;
    _currentDt = dt;

    // Wir passen die hitbox/Größe des Players dynamisch an die aktuelle Richtung an
    if (current == Direction.down) {
      size = Vector2((206 / 229) * targetHeight, targetHeight);
    } else if (current == Direction.up) {
      size = Vector2((190 / 256) * targetHeight, targetHeight);
    } else if (current == Direction.left || current == Direction.right) {
      size = Vector2((139 / 261) * targetHeight, targetHeight);
    }

    if (_velocity.length > 0) {
      super.update(dt);
      position += _velocity * _speed * dt;
    } else {
      super.update(0);
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Bewegung zurücksetzen
    _velocity.setZero();

    // Tasten abfragen und den 'current'-Zustand der Komponente ändern
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _velocity.y = -1;
      current = Direction.up;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _velocity.y = 1;
      current = Direction.down;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _velocity.x = -1;
      current = Direction.left;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _velocity.x = 1;
      current = Direction.right;
    }

    if (_velocity.length > 0) {
      _velocity.normalize();
    }

    // PC sperren mit Leertaste
    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.space)) {
      game.toggleScreenLock();
    }

    return false;
  }
}
