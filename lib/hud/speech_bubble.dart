import 'dart:async';

import 'package:flutter/material.dart';

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
          style: TextStyle(
            fontFamily: 'Courier New', // Garantiert die Retro-Schrift für JEDEN Buchstaben
            fontSize: 18,
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
      child: Container(
        width: 450,
        height: 220,
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

                          // WICHTIG: Text.rich verwenden statt normalem Text!
                          // In deiner speech_bubble.dart beim Erstellen des Text.rich:
                          child: Text.rich(
                            TextSpan(
                              children: _displayedCharacters,
                              // HIER: Der Style muss direkt auf die Kinder vererbt werden
                              style: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF1E1E1E), // Zwingt alle normalen Buchstaben, dunkelgrau zu sein!
                                height: 1.4,
                              ),
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

              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: widget.onClose,
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
    );
  }
}

// Die Klassen RetroAction, RetroButton und _RetroButtonState bleiben exakt unverändert!
class RetroAction {
  RetroAction({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;
}

class RetroButton extends StatefulWidget {
  const RetroButton({super.key, required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;
  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 30),
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0, bottom: _isPressed ? 0 : 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFFF5F5F5) : const Color(0xFF1E1E1E),
          border: Border.all(color: _isPressed ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5), width: 2),
        ),
        child: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            color: _isPressed ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            fontFamily: 'Courier New',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
