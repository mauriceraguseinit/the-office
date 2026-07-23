// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get welcome_text =>
      'Willkommen im Büro.\n\nHeute wird es durch den Regen schwül und warm!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.';

  @override
  String get start_button_label => 'Starten';

  @override
  String get skip_button_label => 'Überspringen';

  @override
  String get character_editor_step_1_title => 'CHARAKTER-EDITOR';

  @override
  String get character_editor_step_1_text => 'Bitte gib deinen Namen ein:';

  @override
  String get character_editor_step_1_funny_hint => 'Netter Versuch, aber Rückwärtsschreiben ist hier nicht erlaubt.';

  @override
  String get character_editor_next_button_label => 'Weiter';

  @override
  String get character_editor_gender_title => 'GESCHLECHT';

  @override
  String get character_editor_size_title => 'GRÖSSE';

  @override
  String get character_editor_start_adventure_button_label => 'Abenteuer starten';

  @override
  String get character_editor_end_text =>
      'Hervorragend! Du hast dir deinen Charakter mit viel Liebe zum Detail selbst zusammengestellt.\n\nViel Spaß im Abenteuer,\n\n';

  @override
  String get character_editor_end_title => 'GLÜCKWUNSCH!';

  @override
  String get character_editor_create_char_button_label => 'Charakter Erstellen';

  @override
  String get character_editor_gender_male => 'Männlich';

  @override
  String get character_editor_gender_female => 'Weiblich';

  @override
  String get character_editor_gender_divers => 'Divers';

  @override
  String get character_editor_gender_jet => 'Kampfjet';

  @override
  String get character_editor_gender_hint => 'Nett, dass du gefragt wirst, oder? Bleibt trotzdem so.';

  @override
  String get character_editor_nice_name => 'Ein wunderschöner Name. Kurz, prägnant... Hendrik.';

  @override
  String get character_editor_name_requirements => 'Der Name muss mindestens 7 Buchstaben lang sein.';

  @override
  String get character_editor_too_high_answer_1 =>
      'Die Deckenhöhen in den Leveln sind genau 1,80m hoch. Sei dankbar, wenn wir dich nicht größer machen.';

  @override
  String get character_editor_too_high_answer_2 =>
      'Größer? In dieser Wirtschaftslage? Weißt du, wie viele Tokens eine größere Hitbox kostet?!';

  @override
  String get character_editor_too_small_answer_1 =>
      'Wenn du kleiner wirst, fällst du durch die Map. Vertrau mir! Das ist die perfekte Höhe für ein Sprite.';
}
