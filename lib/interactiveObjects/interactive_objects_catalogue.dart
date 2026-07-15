import 'package:flame/components.dart';
import 'package:the_office/interactiveObjects/plant.dart';
import 'package:the_office/interactiveObjects/toilet.dart';
import 'package:the_office/interactiveObjects/trash.dart';

import '../npcs/desk_daniel.dart';
import '../npcs/tobi.dart';
import 'coffee_machine.dart';
import 'fridge.dart';
import 'interactive_object.dart';

class InteractiveObjectsCatalogue {
  static InteractiveObject? interactiveObjectForClassName({
    required String className,
    required String displayName,
    required PositionComponent renderComponent,
    required Vector2? position,
    required Vector2? size,
    int priorityOffset = 0,
  }) {
    PositionComponent finalRenderComponent = renderComponent;

    final List<String> animationClasses = <String>[
      'Daniel',
      'Tobi',
    ];

    // Wenn es ein NPC ist und wir eine Animation haben, kapseln wir sie in eine Gruppe
    if ((animationClasses.contains(className)) && renderComponent is SpriteAnimationComponent) {
      finalRenderComponent = SpriteAnimationGroupComponent<String>(
        animations: <String, SpriteAnimation>{
          'idle': renderComponent.animation!,
        },
        current: 'idle',
        size: size,
        anchor: Anchor.center,
      );
    }

    switch (className) {
      case 'Daniel':
        return DeskDaniel(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'Tobi':
        return Tobi(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'Toilet':
        return Toilet(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'Trash':
        return Trash(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'Plant':
        return Plant(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'Fridge':
        return Fridge(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      case 'CoffeeMachine':
        return CoffeeMachine(
          displayName: displayName,
          renderComponent: finalRenderComponent,
          position: position,
          size: size,
          priorityOffset: priorityOffset,
        );

      default:
        return null;
    }
  }
}
