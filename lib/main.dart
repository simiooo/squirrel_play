import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:squirrel_play/app/app.dart';
import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/services/window_manager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await WindowManagerService().initialize();

  await configureDependencies();

  runApp(const SquirrelPlayApp());
}
