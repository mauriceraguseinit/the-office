import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_office/managers/game_state.dart';

class SaveManager {
  static const String _saveKey = 'savegame_data';

  Future<void> saveGame(GameState state) async {
    try {
      debugPrint('SaveManager: Saving game...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(state.toJson());
      debugPrint('SaveManager: JSON to save: $jsonString');
      await prefs.setString(_saveKey, jsonString);
      debugPrint('SaveManager: Game saved successfully.');
    } catch (e) {
      debugPrint('SaveManager: Error saving game: $e');
      rethrow;
    }
  }

  Future<bool> hasSaveGame() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  Future<void> loadGame(GameState state) async {
    try {
      debugPrint('SaveManager: Loading game...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_saveKey);
      
      if (jsonString != null) {
        debugPrint('SaveManager: JSON loaded: $jsonString');
        final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
        state.fromJson(json);
        debugPrint('SaveManager: Game loaded successfully.');
      } else {
        debugPrint('SaveManager: No save game found.');
      }
    } catch (e) {
      debugPrint('SaveManager: Error loading game: $e');
      rethrow;
    }
  }

  Future<void> deleteSaveGame() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}
