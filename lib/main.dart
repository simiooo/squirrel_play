import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:squirrel_play/app/app.dart';
import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/services/window_manager_service.dart';
import 'package:squirrel_play/data/services/system_settings_service.dart';
import 'package:squirrel_play/data/services/system_volume_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await WindowManagerService().initialize();

  await configureDependencies();

  // Apply fullscreen setting from command line or persisted preference
  final systemSettings = getIt<SystemSettingsService>();
  final startFullscreen = systemSettings.shouldStartFullscreen(
    Platform.executableArguments,
  );
  if (startFullscreen) {
    await WindowManagerService().setFullscreen(true);
  }

  // Initialize system volume to 80%
  await getIt<SystemVolumeService>().initialize();

  runApp(const SquirrelPlayApp());
}
