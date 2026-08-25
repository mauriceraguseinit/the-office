import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_office/managers/audio_manager.dart';
import 'package:the_office/managers/service_locator.dart';
import 'package:the_office/utils/assets.dart';
import 'package:the_office/utils/styles.dart';

enum TetrominoType { I, J, L, O, S, T, Z }

class MergeConflictTetris extends FlameGame<World> with HasKeyboardHandlerComponents<World> {
  static const int gridWidth = 10;
  static const int gridHeight = 20;
  static const double blockSize = 30.0;

  late List<List<Color?>> grid;
  late Tetromino currentPiece;
  double tickTime = 0.5;
  double _accumulator = 0;
  int linesCleared = 0;
  bool isGameOver = false;

  final Random _random = Random();

  @override
  Color backgroundColor() => const Color(0xFF1E1E1E); // IDE Dark Theme

  @override
  Future<void> onLoad() async {
    grid = List<List<Color?>>.generate(gridHeight, (_) => List<Color?>.filled(gridWidth, null));
    _spawnNewPiece();

    add(
      TextComponent<TextPaint>(
        text: 'IDE: MERGE CONFLICT TETRIS',
        textRenderer: TextPaint(style: GameStyles.buttonStyle.copyWith(fontSize: 14, color: Colors.blueAccent)),
        position: Vector2(10, 10),
      ),
    );
  }

  void _spawnNewPiece() {
    final TetrominoType type = TetrominoType.values[_random.nextInt(TetrominoType.values.length)];
    currentPiece = Tetromino(type);
    currentPiece.position = Vector2(gridWidth / 2 - 2, 0);

    if (_checkCollision(currentPiece.position, currentPiece.shape)) {
      isGameOver = true;
      _onGameOver();
    }
  }

  void _onGameOver() {
    sl<AudioManager>().playSfx(GameAudio.fan);
    sl<AudioManager>().playSfx(GameAudio.buildFailed);
  }

  bool _checkCollision(Vector2 pos, List<List<int>> shape) {
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] != 0) {
          final int gridX = (pos.x + x).toInt();
          final int gridY = (pos.y + y).toInt();

          if (gridX < 0 || gridX >= gridWidth || gridY >= gridHeight) return true;
          if (gridY >= 0 && grid[gridY][gridX] != null) return true;
        }
      }
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _accumulator += dt;
    if (_accumulator >= tickTime) {
      _accumulator = 0;
      _moveDown();
    }
  }

  void _moveDown() {
    if (!_checkCollision(currentPiece.position + Vector2(0, 1), currentPiece.shape)) {
      currentPiece.position.y += 1;
    } else {
      _lockPiece();
    }
  }

  void _lockPiece() {
    for (int y = 0; y < currentPiece.shape.length; y++) {
      for (int x = 0; x < currentPiece.shape[y].length; x++) {
        if (currentPiece.shape[y][x] != 0) {
          final int gridX = (currentPiece.position.x + x).toInt();
          final int gridY = (currentPiece.position.y + y).toInt();
          if (gridY >= 0) {
            grid[gridY][gridX] = currentPiece.color;
          }
        }
      }
    }
    _clearLines();
    _spawnNewPiece();
  }

  void _clearLines() {
    int clearedThisTurn = 0;
    for (int y = gridHeight - 1; y >= 0; y--) {
      if (grid[y].every((Color? c) => c != null)) {
        grid.removeAt(y);
        grid.insert(0, List<Color?>.filled(gridWidth, null));
        clearedThisTurn++;
        y++; // Re-check the same index
      }
    }
    if (clearedThisTurn > 0) {
      linesCleared += clearedThisTurn;
      tickTime = max(0.1, 0.5 - (linesCleared / 10) * 0.05);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Grid Background
    final Paint paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke;

    for (int y = 0; y <= gridHeight; y++) {
      canvas.drawLine(Offset(0, y * blockSize), Offset(gridWidth * blockSize, y * blockSize), paint);
    }
    for (int x = 0; x <= gridWidth; x++) {
      canvas.drawLine(Offset(x * blockSize, 0), Offset(x * blockSize, gridHeight * blockSize), paint);
    }

    // Draw Locked Blocks
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (grid[y][x] != null) {
          _drawBlock(canvas, x.toDouble(), y.toDouble(), grid[y][x]!);
        }
      }
    }

    // Draw Current Piece
    if (!isGameOver) {
      for (int y = 0; y < currentPiece.shape.length; y++) {
        for (int x = 0; x < currentPiece.shape[y].length; x++) {
          if (currentPiece.shape[y][x] != 0) {
            _drawBlock(canvas, currentPiece.position.x + x, currentPiece.position.y + y, currentPiece.color);
          }
        }
      }
    }

    // Draw UI
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'BUILDS SUCCESSFUL: $linesCleared',
        style: const TextStyle(color: Colors.green, fontSize: 16, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(gridWidth * blockSize + 20, 50));

    if (isGameOver) {
      final TextPainter failPainter = TextPainter(
        text: const TextSpan(
          text: 'BUILD FAILED',
          style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      failPainter.paint(canvas, Offset(gridWidth * blockSize / 2 - 100, gridHeight * blockSize / 2));
    }
  }

  void _drawBlock(Canvas canvas, double x, double y, Color color) {
    final Paint paint = Paint()..color = color;
    final Rect rect = Rect.fromLTWH(x * blockSize, y * blockSize, blockSize - 1, blockSize - 1);
    canvas.drawRect(rect, paint);

    // Add 8-bit border
    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // Add thematic label
    final String label = _getLabelForColor(color);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: blockSize - 4);
    tp.paint(canvas, Offset(x * blockSize + 2, y * blockSize + blockSize / 2 - 3));
  }

  String _getLabelForColor(Color color) {
    if (color == Colors.cyan) return 'NULL POINTER';
    if (color == Colors.blue) return 'MERGE CONFLICT';
    if (color == Colors.orange) return 'UNUSED IMPORT';
    if (color == Colors.yellow) return 'DEPRECATED';
    if (color == Colors.green) return 'INDEX OUT';
    if (color == Colors.purple) return 'MEM LEAK';
    if (color == Colors.red) return 'FIXME!!!';
    return 'BUG';
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    if (isGameOver) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
        if (!_checkCollision(currentPiece.position - Vector2(1, 0), currentPiece.shape)) {
          currentPiece.position.x -= 1;
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
        if (!_checkCollision(currentPiece.position + Vector2(1, 0), currentPiece.shape)) {
          currentPiece.position.x += 1;
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
        _moveDown();
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
        final List<List<int>> rotated = currentPiece.getRotated();
        if (!_checkCollision(currentPiece.position, rotated)) {
          currentPiece.shape = rotated;
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.space)) {
        while (!_checkCollision(currentPiece.position + Vector2(0, 1), currentPiece.shape)) {
          currentPiece.position.y += 1;
        }
        _lockPiece();
      }
    }
    return KeyEventResult.handled;
  }
}

class Tetromino {
  Tetromino(this.type) {
    switch (type) {
      case TetrominoType.I:
        shape = <List<int>>[
          <int>[1, 1, 1, 1],
        ];
        color = Colors.cyan;
        break;
      case TetrominoType.J:
        shape = <List<int>>[
          <int>[1, 0, 0],
          <int>[1, 1, 1],
        ];
        color = Colors.blue;
        break;
      case TetrominoType.L:
        shape = <List<int>>[
          <int>[0, 0, 1],
          <int>[1, 1, 1],
        ];
        color = Colors.orange;
        break;
      case TetrominoType.O:
        shape = <List<int>>[
          <int>[1, 1],
          <int>[1, 1],
        ];
        color = Colors.yellow;
        break;
      case TetrominoType.S:
        shape = <List<int>>[
          <int>[0, 1, 1],
          <int>[1, 1, 0],
        ];
        color = Colors.green;
        break;
      case TetrominoType.T:
        shape = <List<int>>[
          <int>[0, 1, 0],
          <int>[1, 1, 1],
        ];
        color = Colors.purple;
        break;
      case TetrominoType.Z:
        shape = <List<int>>[
          <int>[1, 1, 0],
          <int>[0, 1, 1],
        ];
        color = Colors.red;
        break;
    }
  }
  final TetrominoType type;
  late List<List<int>> shape;
  late Color color;
  Vector2 position = Vector2.zero();

  List<List<int>> getRotated() {
    final int rows = shape.length;
    final int cols = shape[0].length;
    final List<List<int>> rotated = List<List<int>>.generate(cols, (_) => List<int>.filled(rows, 0));

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        rotated[x][rows - 1 - y] = shape[y][x];
      }
    }
    return rotated;
  }
}
