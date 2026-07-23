import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_office/hud/retro_button.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../l10n/l10n.dart';
import '../utils/config.dart';

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
  final double _minScale = 0.8;
  final double _maxScale = 1.3;
  bool _isDraggingSlider = false;

  // Step 1 State (Name)
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _desktopKeyboardFocusNode = FocusNode();
  final String _targetName = 'Hendrik';
  String? _statusMessage;
  String _subMessage = '';
  bool _isNameFinished = false;
  bool _showStep1NextButton = false;

  // Step 2 State (Gender)
  String? _selectedGender;
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
          upperBound: 3.0,
        )..addListener(() {
          if (!_isDraggingSlider) {
            setState(() {
              _heightScale = _wobbleController.value;
            });
          }
        });
    _wobbleController.value = 1.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _controller.dispose();
    _textFieldFocusNode.dispose();
    _desktopKeyboardFocusNode.dispose();
    super.dispose();
  }

  void _onSliderDragUpdate(DragUpdateDetails details, double maxHeight) {
    setState(() {
      _isDraggingSlider = true;
      final double ratio = 1.0 - (details.localPosition.dy / maxHeight).clamp(0.0, 1.0);
      _heightScale = _minScale + (ratio * (_maxScale - _minScale));
      _wobbleController.value = _heightScale;
    });
  }

  void _onSliderDragEnd(DragEndDetails details) {
    _isDraggingSlider = false;

    final List<String> tooHighAnswers = <String>[
      S.of(context).character_editor_too_high_answer_1,
      S.of(context).character_editor_too_high_answer_2,
    ];

    setState(() {
      if (_heightScale > 1.05) {
        final math.Random random = math.Random();
        _genderMessage = tooHighAnswers[random.nextInt(tooHighAnswers.length)];
      } else if (_heightScale < 0.95) {
        _genderMessage = S.of(context).character_editor_too_small_answer_1;
      }
    });

    _wobbleController.animateTo(1.0, duration: const Duration(milliseconds: 600), curve: Curves.elasticOut);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_currentStep != 1) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          _subMessage = S.of(context).character_editor_step_1_funny_hint;
        });
        return;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _validateName();
        return;
      }
    }
  }

  void _validateName() {
    if (_controller.text.length < _targetName.length) {
      setState(() {
        _subMessage = S.of(context).character_editor_name_requirements;
      });
    } else {
      setState(() {
        _statusMessage = S.of(context).character_editor_nice_name;
        _subMessage = '';
        _isNameFinished = true;
        _showStep1NextButton = true;
      });
      _textFieldFocusNode.unfocus();
    }
  }

  void _selectGender(String gender) {
    if (_isResettingGender) return;
    if (gender == S.of(context).character_editor_gender_male) {
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

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _selectedGender = S.of(context).character_editor_gender_male;
          _genderMessage = S.of(context).character_editor_gender_hint;
          _isResettingGender = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Erlaube das Resizing
      extendBody: true, // WICHTIG: Zeichne über System-Bereiche
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        bottom: !isKeyboardVisible, // Deaktiviere Safe Area am unteren Rand, wenn Keyboard da ist
        child: KeyboardListener(
          focusNode: _desktopKeyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Berechne die Höhe basierend auf dem verfügbaren Platz abzüglich Insets

              final double scaleX = constraints.maxWidth / GameConfig.resolution.width;
              const double baseWidth = 600.0;

              return Center(
                child: SizedBox(
                  width: baseWidth * scaleX,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: baseWidth,
                      child: Container(
                        // Padding auf 0, wenn Keyboard aktiv
                        padding: EdgeInsets.all(isKeyboardVisible ? 0 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: isKeyboardVisible ? null : Border.all(color: Colors.orange, width: 6),
                        ),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Hilfsmethode, um den Code sauber zu halten
  Widget _buildCurrentStep() {
    if (_currentStep == 1) return _buildStep1();
    if (_currentStep == 2) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).character_editor_step_1_title,
          style: TextStyle(fontFamily: 'PressStart2P', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 30),
        Text(
          _statusMessage ?? S.of(context).character_editor_step_1_text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 18, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 20),
        if (!_isNameFinished)
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E1E1E), width: 3)),
            child: TextField(
              controller: _controller,
              focusNode: _textFieldFocusNode,
              readOnly: false,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.text,
              // Der Formatter fängt Tastatureingaben ab, bevor sie flackern können
              inputFormatters: <TextInputFormatter>[
                TextInputFormatter.withFunction((TextEditingValue oldValue, TextEditingValue newValue) {
                  final int oldLen = oldValue.text.length;
                  final int newLen = newValue.text.length;

                  // Fall 1: User drückt Backspace (neuer Text ist kürzer)
                  if (newLen < oldLen) {
                    scheduleMicrotask(() {
                      setState(() {
                        _subMessage = S.of(context).character_editor_step_1_funny_hint;
                      });
                    });
                    return oldValue; // Alten Zustand eiskalt beibehalten (kein Flackern!)
                  }

                  // Fall 2: "Hendrik" ist bereits komplett ausgefüllt
                  if (oldLen >= _targetName.length) {
                    return oldValue; // Keine weiteren Zeichen zulassen
                  }

                  // Fall 3: Ein Zeichen wird hinzugefügt -> Nächsten Buchstaben von "Hendrik" rausrücken
                  final String updatedText = _targetName.substring(0, oldLen + 1);

                  scheduleMicrotask(() {
                    setState(() {
                      _subMessage = '';
                    });
                  });

                  return TextEditingValue(
                    text: updatedText,
                    selection: TextSelection.collapsed(offset: updatedText.length),
                  );
                }),
              ],
              onSubmitted: (_) => _validateName(),
              style: const TextStyle(
                fontFamily: 'PressStart2P',
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
            fontFamily: 'PressStart2P',
            fontSize: 14,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_showStep1NextButton) ...<Widget>[
          const SizedBox(height: 30),
          RetroButton(
            title: S.of(context).character_editor_next_button_label,
            onTap: () => setState(() => _currentStep = 2),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).character_editor_step_1_title,
          style: TextStyle(fontFamily: 'PressStart2P', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _buildHeightSlider(),
                const SizedBox(width: 30),
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
                          width: 600,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    S.of(context).character_editor_gender_title,
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGenderOption(S.of(context).character_editor_gender_male, Icons.male),
                  _buildGenderOption(S.of(context).character_editor_gender_female, Icons.female),
                  _buildGenderOption(S.of(context).character_editor_gender_divers, Icons.transgender),
                  _buildGenderOption(S.of(context).character_editor_gender_jet, Icons.airplanemode_active),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            _genderMessage,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),

        RetroButton(
          title: S.of(context).character_editor_create_char_button_label,
          onTap: () => setState(() => _currentStep = 3),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).character_editor_end_title,
          style: TextStyle(fontFamily: 'PressStart2P', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 30),
        Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: S.of(context).character_editor_end_text,
              ),
              TextSpan(
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                text: 'Hendrik!',
              ),
            ],
          ),

          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 16,
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        RetroButton(
          title: S.of(context).character_editor_start_adventure_button_label,
          onTap: widget.onFinished,
        ),
      ],
    );
  }

  Widget _buildHeightSlider() {
    final double sliderHeight = 180;
    return Column(
      children: <Widget>[
        Text(
          S.of(context).character_editor_size_title,
          style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14, fontWeight: FontWeight.bold),
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
                Center(child: Container(width: 4, color: const Color(0xFF1E1E1E))),
                Positioned(
                  left: 2,
                  right: 2,
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
    final bool isSelected = (_selectedGender ?? S.of(context).character_editor_gender_male) == label;
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
              style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: Color(0xFF1E1E1E)),
            ),
          ],
        ),
      ),
    );
  }
}
