import 'package:flame/components.dart';
import 'package:flame/effects.dart'; // <-- Neu für das Ein-/Ausblenden
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../utils/config.dart';
import '../utils/styles.dart';
import 'intro_game.dart';

// Ein kleiner Hilfs-Container, der das HasPaint Mix-in nutzt.
// Dadurch bekommt er das '.opacity'-Feld und vererbt es an seine Kinder.
class OpacityContainer extends PositionComponent with HasPaint<Object> {
  OpacityContainer({super.anchor});
}

class CreditsSequence extends PositionComponent with HasGameReference<IntroGame> {
  CreditsSequence({super.priority})
    : super(
        position: Vector2(
          GameConfig.resolution.width / 2,
          GameConfig.resolution.height / 2,
        ),
        anchor: Anchor.center,
      );

  final List<Map<String, String>> _credits = <Map<String, String>>[
    <String, String>{'role': 'REGIE', 'name': 'Maurice Raguse'},
    <String, String>{'role': 'DREHBUCH', 'name': 'Maurice Raguse'},
    <String, String>{'role': 'GRAFIKEN', 'name': 'Maurice Raguse'},
    <String, String>{'role': 'SOUND DESIGN', 'name': 'Aus dem Netz geklaut'},
    <String, String>{'role': 'LEAD PROGRAMMER', 'name': 'Gemini & viel Club Mate'},
    <String, String>{'role': 'GAME BALANCING', 'name': 'Zufallsgenerator (math.Random)'},
    <String, String>{'role': 'KUCHEN-BEAUFTRAGTER (PC UNLOCKED)', 'name': 'Tobias Ullerich'},
    <String, String>{'role': 'DRUCKSTAU-BEHEBER', 'name': 'IT-Support Inhouse (Etage 2)'},
    <String, String>{'role': 'FENSTER-AUF-ODER-ZU-ENTSCHEIDER', 'name': 'Daniel Wolf'},
  ];

  int _currentIndex = 0;

  // Jetzt als OpacityContainer deklariert
  late OpacityContainer _textContainer;
  late TextComponent<TextRenderer> _roleText;
  late TextComponent<TextRenderer> _nameText;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final TextPaint rolePaint = TextPaint(
      style: const TextStyle(
        color: Colors.orange,
        fontSize: 20,
        fontFamily: GameStyles.mainFont,
        fontWeight: FontWeight.bold,
        shadows: <Shadow>[
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
    );

    final TextPaint namePaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontFamily: GameStyles.mainFont,
        fontWeight: FontWeight.bold,
        shadows: <Shadow>[
          Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
    );

    // Nutzen des neuen Containers mit HasPaint
    _textContainer = OpacityContainer(anchor: Anchor.center);

    _roleText = TextComponent<TextRenderer>(
      text: '',
      textRenderer: rolePaint,
      anchor: Anchor.center,
      position: Vector2(0, -25),
    );

    _nameText = TextComponent<TextRenderer>(
      text: '',
      textRenderer: namePaint,
      anchor: Anchor.center,
      position: Vector2(0, 25),
    );

    _textContainer.add(_roleText);
    _textContainer.add(_nameText);
    add(_textContainer);

    _showNextCredit();
  }

  void _showNextCredit() {
    if (_currentIndex >= _credits.length) {
      removeFromParent();
      return;
    }

    _roleText.text = _credits[_currentIndex]['role']!;
    _nameText.text = _credits[_currentIndex]['name']!;

    // Alte Effekte entfernen
    _textContainer.removeAll(_textContainer.children.whereType<OpacityEffect>());

    // Jetzt ist der Setter dank 'with HasPaint' absolut valide!
    _textContainer.opacity = 0.0;

    // 1. Einblenden
    _textContainer.add(OpacityEffect.to(1.0, EffectController(duration: 0.5)));

    // 2. Warten und Ausblenden
    add(
      TimerComponent(
        period: 3.0,
        onTick: () {
          _textContainer.add(OpacityEffect.to(0.0, EffectController(duration: 0.5)));

          add(
            TimerComponent(
              period: 0.6,
              onTick: () {
                _currentIndex++;
                _showNextCredit();
              },
            ),
          );
        },
      ),
    );
  }
}
