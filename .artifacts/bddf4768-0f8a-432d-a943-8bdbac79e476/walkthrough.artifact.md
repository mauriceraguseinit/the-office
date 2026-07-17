# Walkthrough - Start Menu and Save Game Integration

I have added a start menu that automatically detects if a save game exists and allows the player to either continue their journey or start a fresh game.

## Changes

### 1. Start Menu UI
- **[start_menu.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/hud/start_menu.dart)**: A new full-screen menu with the "The Office" title and two main options: **Fortsetzen** (Continue) and **Neues Spiel** (New Game).

### 2. Scene Logic
- **[main.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/main.dart)**:
    - Added `loading` and `startMenu` scenes.
    - On startup, the app now checks `SaveManager.hasSaveGame()`.
    - **No Save**: Goes directly to the `CharacterEditor`.
    - **Save Exists**: Shows the `StartMenu`.
    - **Fortsetzen**: Sets a flag in `OfficeGame` and switches to the game scene.
    - **Neues Spiel**: Deletes the existing save and starts the `CharacterEditor`.

### 3. Game Auto-Load
- **[office_game.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/office_game.dart)**: Added a `_shouldLoadOnMount` flag. If set, the game will automatically call `loadGame()` once all assets and components are loaded, ensuring the player spawns at the correct saved location.

## Verification Results
- **Direct Editor Flow**: Verified that without a save game, the character editor appears as usual.
- **Resume Flow**: Verified that clicking "Fortsetzen" correctly restores the player position and inventory.
- **Reset Flow**: Verified that clicking "Neues Spiel" wipes the old data and starts the character creation process.

> [!TIP]
> This new flow provides a much better first-time user experience while still making it easy for returning players to jump right back into the action.
