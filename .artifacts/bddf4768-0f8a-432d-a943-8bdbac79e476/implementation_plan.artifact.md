# Implementation Plan - Start Menu with Save Game Support

This plan outlines the steps to add a start menu that checks for an existing save game before entering the character editor or the game.

## User Review Required

> [!IMPORTANT]
> If a save game exists, the user will see a menu with "Fortsetzen" and "Neues Spiel". Clicking "Neues Spiel" will permanently delete the old save game and start the character editor.

## Proposed Changes

### 1. New UI Component
#### [NEW] [start_menu.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/hud/start_menu.dart)
- Create a `StartMenu` widget with a retro design.
- Buttons:
    - **Fortsetzen**: Triggers game loading and switches to the main game scene.
    - **Neues Spiel**: Deletes the save game and switches to the character editor.

### 2. Scene Management
#### [MODIFY] [main.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/main.dart)
- Add `Scenes.loading` and `Scenes.startMenu` to the enum.
- In `_TheOfficeAppState.initState()`, check if a save game exists using `SaveManager.hasSaveGame()`.
- Update the `build` method to handle the new scenes.
- Implement the transition logic:
    - `loading` -> `startMenu` (if save exists) or `editor` (if no save).
    - `startMenu` (Fortsetzen) -> `game`.
    - `startMenu` (Neues Spiel) -> `editor`.

### 3. Game Integration
#### [MODIFY] [office_game.dart](file:///C:/Users/ragus/StudioProjects/the-office/lib/office_game.dart)
- Ensure that if the game is started via "Fortsetzen", the state is correctly loaded. I will add a flag or a method to trigger `loadGame()` immediately after mounting.

## Verification Plan

### Manual Verification
1. **First Run (No Save)**:
    - Start the app.
    - Verify it goes directly to the Character Editor.
2. **Resume Support**:
    - Play the game, save it (F5 or Menu).
    - Restart the app.
    - Verify the "Fortsetzen / Neues Spiel" menu appears.
3. **Fortsetzen**:
    - Click "Fortsetzen".
    - Verify you are back in the office at the saved position with your items.
4. **Neues Spiel**:
    - Click "Neues Spiel".
    - Verify you are taken to the Character Editor.
    - Verify the old save game is gone.
