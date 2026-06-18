import 'dart:async';

import 'package:flutter/material.dart';

class RetroSpeechBubble extends StatefulWidget {
  final String text;
  final VoidCallback? onClose;
  final List<RetroAction> actions; // Die neue optionale Liste
  final Duration speed;

  const RetroSpeechBubble({
    super.key,
    required this.text,
    this.onClose,
    this.actions = const [],
    this.speed = const Duration(milliseconds: 50),
  });

  @override
  State<RetroSpeechBubble> createState() => _RetroSpeechBubbleState();
}

class _RetroSpeechBubbleState extends State<RetroSpeechBubble> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  bool _isTypewriterFinished = false; // Neu: Zeigt die Buttons erst nach dem Tippen an

  @override
  void initState() {
    super.initState();
    _startTypewriterEffect();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTypewriterEffect() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
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
          duration: const Duration(milliseconds: 100),
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
        decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.zero),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(color: const Color(0xFF1E1E1E), width: 4),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 24,
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  // NEU: Zwingt den Text (und die Buttons), linksbündig zu starten
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Textbereich
                    Expanded(
                      child: SizedBox(
                        width: double.infinity, // Zwingt die Box, die volle Breite zu nutzen
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _displayedText,
                            textAlign: TextAlign.left, // Text explizit linksbündig
                            style: const TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Buttons anzeigen
                    if (widget.actions.isNotEmpty && _isTypewriterFinished) ...[
                      const SizedBox(height: 12),
                      // Centered, damit die Buttons schön in der Mitte der Box sitzen
                      Center(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: widget.actions.map((action) {
                            return RetroButton(title: action.title, onTap: action.onTap);
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Schließen-Button oben rechts
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

class RetroAction {
  final String title;
  final VoidCallback onTap;

  RetroAction({required this.title, required this.onTap});
}

class RetroButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const RetroButton({super.key, required this.title, required this.onTap});

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Registriert den Moment des Drückens
      onTapDown: (_) => setState(() => _isPressed = true),
      // Registriert das Loslassen (Erfolg)
      onTapUp: (_) => setState(() => _isPressed = false),
      // Falls der Finger vom Button runtergezogen wird, ohne loszulassen
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 30), // Extrem schnelle Reaktion für den "Knackig"-Effekt
        // Trick: Wenn gedrückt, verschieben wir den Button per Margin 2 Pixel nach unten
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0, bottom: _isPressed ? 0 : 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Invertiert die Farben beim Drücken (wird hellgrau mit dunkler Schrift)
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
