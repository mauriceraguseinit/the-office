import 'package:flutter/cupertino.dart';
import 'package:the_office/utils/styles.dart';

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
          style: GameStyles.buttonStyle.copyWith(
            color: _isPressed ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          ),
        ),
      ),
    );
  }
}
