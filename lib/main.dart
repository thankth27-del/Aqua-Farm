import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'save/save_repository.dart';
import 'ui/app.dart';
import 'ui/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SaveRepository.open();
  runApp(
    ProviderScope(
      overrides: [saveRepositoryProvider.overrideWithValue(repo)],
      child: const AquaFarmApp(),
    ),
  );
}
