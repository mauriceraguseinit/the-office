import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:the_office/utils/styles.dart';

import '../utils/config.dart';

class RetroSpeechBubble extends StatefulWidget {
  const RetroSpeechBubble({
    super.key,
    required this.text,
    this.onClose,
    this.actions = const <RetroAction>[],
    this.speed = const Duration(milliseconds: 30),
  });
  final String text;
  final VoidCallback? onClose;
  final List<RetroAction> actions;
  final Duration speed;

  @override
  State<RetroSpeechBubble> createState() => _RetroSpeechBubbleState();
}

class _RetroSpeechBubbleState extends State<RetroSpeechBubble> {
  // Enthält am Ende alle fertig formatierten Einzelbuchstaben
  List<TextSpan> _allCharacters = <TextSpan>[];
  // Die aktuell angezeigten Buchstaben im Typewriter
  List<TextSpan> _displayedCharacters = <TextSpan>[];

  int _currentIndex = 0;
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  bool _isTypewriterFinished = false;

  @override
  void initState() {
    super.initState();

    _allCharacters = _parseCustomTags(widget.text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTypewriterEffect();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // --- DER CUSTOM PARSER ---
  List<TextSpan> _parseCustomTags(String rawText) {
    final List<TextSpan> characters = <TextSpan>[];

    bool isBold = false;
    Color currentColor = const Color(0xFF1E1E1E); // Standard-Schriftfarbe

    int i = 0;
    while (i < rawText.length) {
      // Wenn wir ein Tag öffnen
      if (rawText[i] == '[') {
        // 1. Check für Schließende Tags
        if (rawText.startsWith('[/b]', i)) {
          isBold = false;
          i += 4;
          continue;
        } else if (rawText.startsWith('[/color]', i)) {
          currentColor = const Color(0xFF1E1E1E); // Zurück auf Standard
          i += 8;
          continue;
        }
        // 2. Check für Öffnende Tags
        else if (rawText.startsWith('[b]', i)) {
          isBold = true;
          i += 3;
          continue;
        } else if (rawText.startsWith('[color=', i)) {
          // Wir suchen das schließende ']' des Color-Tags
          final int closeBracket = rawText.indexOf(']', i);
          if (closeBracket != -1) {
            final String colorStr = rawText.substring(i + 7, closeBracket);

            // Farbe zuweisen
            if (colorStr == 'red') {
              currentColor = Colors.red;
            } else if (colorStr == 'orange') {
              currentColor = Colors.orange;
            } else if (colorStr == 'blue') {
              currentColor = Colors.blue;
            } else if (colorStr == 'green') {
              currentColor = Colors.green;
            } else if (colorStr.startsWith('#')) {
              currentColor = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
            }

            i = closeBracket + 1;
            continue;
          }
        }
      }

      // Wenn es ein ganz normaler Buchstabe (oder \n) ist, fügen wir ihn mit dem aktuellen Zustand hinzu
      characters.add(
        TextSpan(
          text: rawText[i],
          style: GameStyles.dialogStyle.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: currentColor,
          ),
        ),
      );

      i++;
    }

    return characters;
  }

  void _startTypewriterEffect() {
    if (_allCharacters.isEmpty) {
      setState(() => _isTypewriterFinished = true);
      return;
    }

    // Wir stellen sicher, dass die Liste beim Start wirklich leer ist
    _displayedCharacters.clear();
    _currentIndex = 0;

    _timer = Timer.periodic(widget.speed, (Timer timer) {
      if (_currentIndex < _allCharacters.length) {
        setState(() {
          // DER TRICK: Wir erstellen eine brandneue Instanz der Liste.
          // Das triggert das UI-Rendering in Flutter garantiert!
          _displayedCharacters = <TextSpan>[..._displayedCharacters, _allCharacters[_currentIndex]];
          _currentIndex++;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isTypewriterFinished = true;
        });
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Wir berechnen die maximale Größe, die das Overlay im echten Fenster einnehmen darf,
          // basierend auf dem gleichen Seitenverhältnis (GameConfig.resolution).
          final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
          final double scaleY = constraints.maxHeight / GameConfig.resolution.height;
          final double gameScale = min(scaleX, scaleY);

          // Deine festen virtuellen Wunschmaße für die Box
          const double baseWidth = 450.0;
          const double baseHeight = 220.0;

          // NUTZE FITTEDBOX STATT TRANSFORM.SCALE:
          // Das sorgt dafür, dass die Hitboxen (Gesten) exakt mit der Grafik mitskalieren.
          return SizedBox(
            width: baseWidth * gameScale,
            height: baseHeight * gameScale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: baseWidth,
                height: baseHeight,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 4),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          top: 24,
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    child: Text.rich(
                                      TextSpan(
                                        children: _displayedCharacters,
                                        style: GameStyles.dialogStyle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (widget.actions.isNotEmpty && _isTypewriterFinished) ...<Widget>[
                                const SizedBox(height: 12),
                                Center(
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: widget.actions.map((RetroAction action) {
                                      return RetroButton(title: action.title, onTap: action.onTap);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Das "X" zum Schließen hat jetzt wieder eine perfekt sitzende Hitbox!
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: widget.onClose,
                            behavior:
                                HitTestBehavior.opaque, // Zwingt Flutter, die gesamte Box als Trefffläche zu werten
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ), // Etwas mehr Padding spendiert für besseres Klicken
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                border: Border.all(color: const Color(0xFFF5F5F5), width: 1),
                              ),
                              child: Text(
                                'X',
                                style: GameStyles.buttonStyle.copyWith(
                                  color: const Color(0xFFF5F5F5),
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
            ),
          );
        },
      ),
    );
  }
}

// Die Klassen RetroAction, RetroButton und _RetroButtonState bleiben exakt unverändert!
class RetroAction {
  RetroAction({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;
}
