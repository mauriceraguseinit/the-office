import 'package:get_it/get_it.dart';

import '../office_game.dart';
import 'game_state.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<GameState>(() => GameState());
}

void registerGameInstance(OfficeGame game) {
  if (sl.isRegistered<OfficeGame>()) {
    sl.unregister<OfficeGame>();
  }
  sl.registerSingleton<OfficeGame>(game);
}
