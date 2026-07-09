import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'speech_bubble.dart';

class CharacterEditor extends StatefulWidget {
  const CharacterEditor({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> with TickerProviderStateMixin {
  // Common State
  int _currentStep = 1;

  // Step 2 State (Character)
  late AnimationController _wobbleController;
  double _heightScale = 1.0;
  final double _minScale = 0.8; // Minimale Schrumpfung
  final double _maxScale = 1.3; // Maximale Größe (Hälfte von deinem vorherigen Wert)
  bool _isDraggingSlider = false;

  // Step 1 State (Name)
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final String _targetName = 'Hendrik';
  String _statusMessage = 'Bitte gib deinen Namen ein:';
  String _subMessage = '';
  bool _isNameFinished = false;
  bool _showStep1NextButton = false;

  // Step 2 State (Gender)
  String _selectedGender = 'Männlich';
  String _genderMessage = '';
  bool _isResettingGender = false;

  @override
  void initState() {
    super.initState();
    _wobbleController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
          lowerBound: 0.0,
          upperBound: 3.0, // Genug Puffer für den Elastic-Ausschlag
        )..addListener(() {
          if (!_isDraggingSlider) {
            setState(() {
              _heightScale = _wobbleController.value;
            });
          }
        });
    _wobbleController.value = 1.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSliderDragUpdate(DragUpdateDetails details, double maxHeight) {
    setState(() {
      _isDraggingSlider = true;

      // Berechnet einen Wert von 0.0 (unten) bis 1.0 (oben)
      final double ratio = 1.0 - (details.localPosition.dy / maxHeight).clamp(0.0, 1.0);

      // Mappt die Ratio auf das neue, sanftere Fenster (_minScale bis _maxScale)
      _heightScale = _minScale + (ratio * (_maxScale - _minScale));
      _wobbleController.value = _heightScale;
    });
  }

  void _onSliderDragEnd(DragEndDetails details) {
    _isDraggingSlider = false;

    // Listen mit den fiesen Sprüchen
    final List<String> spruecheGroesser = <String>[
      'Die Deckenhöhen in den Leveln sind genau 1,80m hoch. Sei dankbar, wenn wir dich nicht größer machen.',
      'Größer? In dieser Wirtschaftslage? Weißt du, wie viele Tokens eine größere Hitbox kostet?!',
    ];

    setState(() {
      // Schauen wir mal, was der Spieler mit Hendrik angestellt hat
      if (_heightScale > 1.05) {
        // Zufälligen Spruch aus der Liste wählen
        final math.Random random = math.Random();
        _genderMessage = spruecheGroesser[random.nextInt(spruecheGroesser.length)];
      } else if (_heightScale < 0.95) {
        // Spruch fürs Schrumpfen
        _genderMessage =
            'Wenn du kleiner wirst, fällst du durch die Map. Vertrau mir! Das ist die perfekte Höhe für ein Sprite.';
      }
    });

    // Startet das smoothe, langsame Zurückwabbeln
    _wobbleController.animateTo(1.0, duration: const Duration(milliseconds: 600), curve: Curves.elasticOut);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_currentStep != 1) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          _subMessage = 'Netter Versuch, aber Rückwärtsschreiben ist hier nicht erlaubt.';
        });
        return;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _validateName();
        return;
      }

      // Ignore other special keys (modifier keys, etc.)
      if (event.logicalKey.keyId > 0x100000000) return;

      if (_controller.text.length < _targetName.length) {
        setState(() {
          _controller.text = _targetName.substring(0, _controller.text.length + 1);
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          _subMessage = '';
        });
      }
    }
  }

  void _validateName() {
    if (_controller.text.length < _targetName.length) {
      setState(() {
        _subMessage = 'Der Name muss mindestens 7 Buchstaben lang sein.';
      });
    } else {
      setState(() {
        _statusMessage = 'Ein wunderschöner Name. Kurz, prägnant... Hendrik.';
        _subMessage = '';
        _isNameFinished = true;
        _showStep1NextButton = true;
      });
    }
  }

  void _selectGender(String gender) {
    if (_isResettingGender) return;
    if (gender == 'Männlich') {
      setState(() {
        _selectedGender = gender;
        _genderMessage = '';
      });
      return;
    }

    setState(() {
      _selectedGender = gender;
      _genderMessage = '';
      _isResettingGender = true;
    });

    // Reset to "Männlich" after a short delay
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _selectedGender = 'Männlich';
          _genderMessage = 'Nett, dass du gefragt wirst, oder? Bleibt trotzdem so.';
          _isResettingGender = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    if (_currentStep == 1) {
      currentWidget = _buildStep1();
    } else if (_currentStep == 2) {
      currentWidget = _buildStep2();
    } else {
      currentWidget = _buildStep3();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: Colors.orange, width: 6),
            ),
            child: currentWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'CHARAKTER-EDITOR',
          style: TextStyle(fontFamily: 'Courier New', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 30),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Courier New', fontSize: 18, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 20),
        if (!_isNameFinished)
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E1E1E), width: 3)),
            child: TextField(
              controller: _controller,
              readOnly: true,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(border: InputBorder.none, hintText: '...'),
            ),
          ),
        if (!_isNameFinished && _controller.text.length == _targetName.length) ...<Widget>[
          const SizedBox(height: 20),
          RetroButton(title: 'OK', onTap: _validateName),
        ],
        const SizedBox(height: 15),
        Text(
          _subMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 14,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_showStep1NextButton) ...<Widget>[
          const SizedBox(height: 30),
          RetroButton(title: 'Weiter', onTap: () => setState(() => _currentStep = 2)),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'CHARAKTER-EDITOR',
          style: TextStyle(fontFamily: 'Courier New', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Leftmost: Height Slider
            _buildHeightSlider(),
            const SizedBox(width: 30),
            // Left: Hendrik Image (Frame 1 of down.png)
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()..scaleByVector3(Vector3(1.0, _heightScale, 1.0)),
              child: Container(
                width: 150,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                  color: Colors.white,
                ),
                child: ClipRect(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/images/down.png',
                      width: 600, // 4 frames approx
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
            // Right: Options
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'GESCHLECHT:',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGenderOption('Männlich', Icons.male),
                  _buildGenderOption('Weiblich', Icons.female),
                  _buildGenderOption('Divers', Icons.transgender),
                  _buildGenderOption('Kampfjet', Icons.airplanemode_active),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _genderMessage,
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        RetroButton(title: 'Charakter Erstellen', onTap: () => setState(() => _currentStep = 3)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'GLÜCKWUNSCH!',
          style: TextStyle(fontFamily: 'Courier New', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 30),
        const Text(
          'Hervorragend! Du hast dir deinen Charakter mit viel Liebe zum Detail selbst zusammengestellt.\n\nViel Spaß im Abenteuer, Hendrik!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 16,
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        // Erst dieser Button startet das eigentliche Spiel über das Callback
        RetroButton(title: 'Abenteuer starten', onTap: widget.onFinished),
      ],
    );
  }

  Widget _buildHeightSlider() {
    final double sliderHeight = 180;
    return Column(
      children: <Widget>[
        const Text(
          'GRÖSSE',
          style: TextStyle(fontFamily: 'Courier New', fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onVerticalDragUpdate: (DragUpdateDetails details) => _onSliderDragUpdate(details, sliderHeight),
          onVerticalDragEnd: _onSliderDragEnd,
          child: Container(
            width: 35,
            height: sliderHeight,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
              color: Colors.white,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Track
                Center(child: Container(width: 4, color: const Color(0xFF1E1E1E))),
                // Handle
                Positioned(
                  left: 2,
                  right: 2,
                  // Berechnet den exakten Prozentwert innerhalb der neuen Grenzen
                  top: (sliderHeight * (1.0 - (_heightScale - _minScale) / (_maxScale - _minScale))) - 12.5,
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon) {
    final bool isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: () => _selectGender(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                color: isSelected ? Colors.orange : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
            ),
            const SizedBox(width: 15),
            Icon(icon, color: const Color(0xFF1E1E1E)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 16, color: Color(0xFF1E1E1E)),
            ),
          ],
        ),
      ),
    );
  }
}
