import 'package:get_it/get_it.dart';

import '../office_game.dart';
import 'audio_manager.dart';
import 'game_state.dart';
import 'save_manager.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<GameState>(() => GameState());
  sl.registerLazySingleton<AudioManager>(() => AudioManager());
  sl.registerLazySingleton<SaveManager>(() => SaveManager());
}

void registerGameInstance(OfficeGame game) {
  if (sl.isRegistered<OfficeGame>()) {
    sl.unregister<OfficeGame>();
  }
  sl.registerSingleton<OfficeGame>(game);
}
