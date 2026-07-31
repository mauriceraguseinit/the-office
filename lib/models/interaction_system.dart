import 'dart:math';

import '../managers/game_state.dart';
import 'inventory_item.dart';

abstract class Requirement {
  bool isSatisfied(GameState state, InventoryItem? activeItem);
}

class FlagRequirement extends Requirement {
  FlagRequirement(this.flag, {this.requiredValue = true});
  final String flag;
  final bool requiredValue;

  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return state.hasFlag(flag) == requiredValue;
  }
}

class ItemRequirement extends Requirement {
  ItemRequirement(this.itemId);
  final String itemId;

  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return activeItem?.id == itemId;
  }
}

class NoItemRequirement extends Requirement {
  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return activeItem == null;
  }
}

class AnyItemRequirement extends Requirement {
  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return activeItem != null;
  }
}

class HasItemRequirement extends Requirement {
  HasItemRequirement(this.itemId);
  final String itemId;

  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return state.ownedItems.any((InventoryItem item) => item.id == itemId);
  }
}

class HasNoItemRequirement extends Requirement {
  HasNoItemRequirement(this.itemId);
  final String itemId;

  @override
  bool isSatisfied(GameState state, InventoryItem? activeItem) {
    return !state.ownedItems.any((InventoryItem item) => item.id == itemId);
  }
}

abstract class GameAction {
  void execute(GameState state);
}

class SetFlagAction extends GameAction {
  SetFlagAction(this.flag, {this.value = true});
  final String flag;
  final bool value;

  @override
  void execute(GameState state) {
    state.setFlag(flag, value: value);
  }
}

class ShowMessageAction extends GameAction {
  ShowMessageAction(this.message);
  final String message;

  @override
  void execute(GameState state) {
    state.setPlayerMessage(message);
  }
}

class ShowRandomMessageAction extends GameAction {
  ShowRandomMessageAction(this.messages);
  final List<String> messages;

  @override
  void execute(GameState state) {
    final Random random = Random();
    state.setPlayerMessage(messages[random.nextInt(messages.length)]);
  }
}

class ShowStackMessageAction extends GameAction {
  ShowStackMessageAction(this.key, this.messages);
  final String key;
  final List<String> messages;

  @override
  void execute(GameState state) {
    final int count = state.getVariable(key) as int? ?? 0;
    state.setPlayerMessage(messages[count]);

    if (count + 1 < messages.length) {
      state.setVariable(key, count + 1);
    }
  }
}

class AddItemAction extends GameAction {
  AddItemAction(this.item);
  final InventoryItem item;

  @override
  void execute(GameState state) {
    state.ownedItems.add(item);
  }
}

class RemoveItemAction extends GameAction {
  RemoveItemAction(this.itemId);
  final String itemId;

  @override
  void execute(GameState state) {
    state.ownedItems.removeWhere((InventoryItem item) => item.id == itemId);
  }
}

class PeeAction extends GameAction {
  @override
  void execute(GameState state) {
    // Diese Action wird im InteractiveObject speziell behandelt,
    // um die Animation auf Hendrik zu triggern.
  }
}

class RemoveObjectAction extends GameAction {
  @override
  void execute(GameState state) {
    // Diese Action wird im InteractiveObject speziell behandelt,
    // um das Objekt aus der Welt zu entfernen.
  }
}

class CustomAction extends GameAction {
  CustomAction(this.callback);
  final void Function(GameState state) callback;

  @override
  void execute(GameState state) {
    callback(state);
  }
}

class InteractionRule {
  InteractionRule({
    this.requirements = const <Requirement>[],
    this.actions = const <GameAction>[],
    this.overlayToOpen,
  });
  final List<Requirement> requirements;
  final List<GameAction> actions;
  final String? overlayToOpen;

  bool canExecute(GameState state, InventoryItem? activeItem) {
    return requirements.every((Requirement req) => req.isSatisfied(state, activeItem));
  }

  void execute(GameState state) {
    for (final GameAction action in actions) {
      action.execute(state);
    }
  }
}
