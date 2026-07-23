// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get welcome_text =>
      'Welcome to the office.\n\nToday, the rain is making it humid and warm!!! So grab a cold mate from the fridge and get to work.\n\nYou can access the Jira board with your tasks on your PC.';

  @override
  String get start_button_label => 'Start';

  @override
  String get skip_button_label => 'Skip';

  @override
  String get character_editor_step_1_title => 'CHARACTER EDITOR';

  @override
  String get character_editor_step_1_text => 'Please enter your name:';

  @override
  String get character_editor_step_1_funny_hint => 'Nice try, but writing backwards is not allowed here.';

  @override
  String get character_editor_next_button_label => 'Next';

  @override
  String get character_editor_gender_title => 'GENDER';

  @override
  String get character_editor_size_title => 'HEIGHT';

  @override
  String get character_editor_start_adventure_button_label => 'Start adventure';

  @override
  String get character_editor_end_text =>
      'Excellent! You have created your character with great attention to detail.\n\nHave fun on your adventure,\n\n';

  @override
  String get character_editor_end_title => 'CONGRATULATIONS!';

  @override
  String get character_editor_create_char_button_label => 'Create character';

  @override
  String get character_editor_gender_male => 'Male';

  @override
  String get character_editor_gender_female => 'Female';

  @override
  String get character_editor_gender_divers => 'Diverse';

  @override
  String get character_editor_gender_jet => 'Fighter jet';

  @override
  String get character_editor_gender_hint => 'Nice that you\'re being asked, right? Still stays that way.';

  @override
  String get character_editor_nice_name => 'A beautiful name. Short, concise... Hendrik.';

  @override
  String get character_editor_name_requirements => 'The name must be at least 7 letters long.';

  @override
  String get character_editor_too_high_answer_1 =>
      'The ceiling heights in the levels are exactly 1.80m. Be grateful we\'re not making you any taller.';

  @override
  String get character_editor_too_high_answer_2 =>
      'Taller? In this economy? Do you know how many tokens a bigger hitbox costs?!';

  @override
  String get character_editor_too_small_answer_1 =>
      'If you get any smaller, you\'ll fall through the map. Trust me! This is the perfect height for a sprite.';

  @override
  String get menu_button => 'Menu';

  @override
  String get menu_title => 'MAIN MENU';

  @override
  String get menu_save => 'Save';

  @override
  String get menu_load => 'Load';

  @override
  String get continue_button_label => 'Continue';

  @override
  String get new_game_button_label => 'New game';

  @override
  String get menu_coffey => 'Brew coffee';

  @override
  String get menu_controls => 'Controls';

  @override
  String get welcome_back_title => 'WELCOME BACK';

  @override
  String get menu_coffey_text =>
      '[b]Hendrik:[/b]\n\nI pressed [color=red]COFFEE[/color], but all I got was an error message: [i]Error 418: I\'m a teapot.[/i]\n\nTypical IT...';

  @override
  String get menu_controls_text => 'MOVEMENT: WASD / Touch (Hold)\nACTION: Key E\nINVENTORY: Key I';
}
