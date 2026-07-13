import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class GameStyles {
  static const String mainFont = 'PressStart2P';

  static const TextStyle statusStyle = TextStyle(
    fontFamily: mainFont,
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    shadows: <Shadow>[
      Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0),
    ],
  );

  static const TextStyle interactionStyle = TextStyle(
    fontFamily: mainFont,
    color: Color(0xFFFFFFAA),
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black,
        offset: Offset(2, 2),
        blurRadius: 2,
      ),
    ],
  );

  static const TextStyle infoStyle = TextStyle(
    color: Colors.orange,
    fontFamily: mainFont,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    shadows: <Shadow>[
      Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0),
    ],
  );

  static const TextStyle dialogStyle = TextStyle(
    fontFamily: mainFont,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1E1E1E),
    height: 1.4,
  );

  static const TextStyle inventoryTitleStyle = TextStyle(
    fontFamily: mainFont,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E1E1E),
  );

  static const TextStyle inventoryHoverStyle = TextStyle(
    fontFamily: mainFont,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.orange,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontFamily: mainFont,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  static TextPaint get statusRenderer => TextPaint(style: statusStyle);
  static TextPaint get interactionRenderer => TextPaint(style: interactionStyle);
  static TextPaint get infoRenderer => TextPaint(style: infoStyle);
}
