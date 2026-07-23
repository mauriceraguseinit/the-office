import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_de.dart';
import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// No description provided for @welcome_text.
  ///
  /// In de, this message translates to:
  /// **'Willkommen im Büro.\\n\\nHeute wird es durch den Regen schwül und warm!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\\n\\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.'**
  String get welcome_text;

  /// No description provided for @start_button_label.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get start_button_label;

  /// No description provided for @skip_button_label.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip_button_label;

  /// No description provided for @character_editor_step_1_title.
  ///
  /// In de, this message translates to:
  /// **'CHARAKTER-EDITOR'**
  String get character_editor_step_1_title;

  /// No description provided for @character_editor_step_1_text.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Namen ein:'**
  String get character_editor_step_1_text;

  /// No description provided for @character_editor_step_1_funny_hint.
  ///
  /// In de, this message translates to:
  /// **'Netter Versuch, aber Rückwärtsschreiben ist hier nicht erlaubt.'**
  String get character_editor_step_1_funny_hint;

  /// No description provided for @character_editor_next_button_label.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get character_editor_next_button_label;

  /// No description provided for @character_editor_gender_title.
  ///
  /// In de, this message translates to:
  /// **'GESCHLECHT'**
  String get character_editor_gender_title;

  /// No description provided for @character_editor_size_title.
  ///
  /// In de, this message translates to:
  /// **'GRÖSSE'**
  String get character_editor_size_title;

  /// No description provided for @character_editor_start_adventure_button_label.
  ///
  /// In de, this message translates to:
  /// **'Abenteuer starten'**
  String get character_editor_start_adventure_button_label;

  /// No description provided for @character_editor_end_text.
  ///
  /// In de, this message translates to:
  /// **'Hervorragend! Du hast dir deinen Charakter mit viel Liebe zum Detail selbst zusammengestellt.\\n\\nViel Spaß im Abenteuer,\\n\\n'**
  String get character_editor_end_text;

  /// No description provided for @character_editor_end_title.
  ///
  /// In de, this message translates to:
  /// **'GLÜCKWUNSCH!'**
  String get character_editor_end_title;

  /// No description provided for @character_editor_create_char_button_label.
  ///
  /// In de, this message translates to:
  /// **'Charakter Erstellen'**
  String get character_editor_create_char_button_label;

  /// No description provided for @character_editor_gender_male.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get character_editor_gender_male;

  /// No description provided for @character_editor_gender_female.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get character_editor_gender_female;

  /// No description provided for @character_editor_gender_divers.
  ///
  /// In de, this message translates to:
  /// **'Divers'**
  String get character_editor_gender_divers;

  /// No description provided for @character_editor_gender_jet.
  ///
  /// In de, this message translates to:
  /// **'Kampfjet'**
  String get character_editor_gender_jet;

  /// No description provided for @character_editor_gender_hint.
  ///
  /// In de, this message translates to:
  /// **'Nett, dass du gefragt wirst, oder? Bleibt trotzdem so.'**
  String get character_editor_gender_hint;

  /// No description provided for @character_editor_nice_name.
  ///
  /// In de, this message translates to:
  /// **'Ein wunderschöner Name. Kurz, prägnant... Hendrik.'**
  String get character_editor_nice_name;

  /// No description provided for @character_editor_name_requirements.
  ///
  /// In de, this message translates to:
  /// **'Der Name muss mindestens 7 Buchstaben lang sein.'**
  String get character_editor_name_requirements;

  /// No description provided for @character_editor_too_high_answer_1.
  ///
  /// In de, this message translates to:
  /// **'Die Deckenhöhen in den Leveln sind genau 1,80m hoch. Sei dankbar, wenn wir dich nicht größer machen.'**
  String get character_editor_too_high_answer_1;

  /// No description provided for @character_editor_too_high_answer_2.
  ///
  /// In de, this message translates to:
  /// **'Größer? In dieser Wirtschaftslage? Weißt du, wie viele Tokens eine größere Hitbox kostet?!'**
  String get character_editor_too_high_answer_2;

  /// No description provided for @character_editor_too_small_answer_1.
  ///
  /// In de, this message translates to:
  /// **'Wenn du kleiner wirst, fällst du durch die Map. Vertrau mir! Das ist die perfekte Höhe für ein Sprite.'**
  String get character_editor_too_small_answer_1;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return SDe();
    case 'en':
      return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
