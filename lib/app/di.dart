import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squirrel_play/core/services/platform_info.dart';
import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/repositories/game_repository_impl.dart';
import 'package:squirrel_play/data/repositories/home_repository_impl.dart';
import 'package:squirrel_play/data/repositories/metadata_repository_impl.dart';
import 'package:squirrel_play/data/repositories/scan_directory_repository_impl.dart';
import 'package:squirrel_play/data/services/api_key_service.dart';
import 'package:squirrel_play/data/services/file_scanner_service.dart';
import 'package:squirrel_play/data/services/game_launcher_service.dart';
import 'package:squirrel_play/data/services/gamepad_service.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/rawg_batch_search_service.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_metadata_adapter.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/data/services/metadata_service.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/data/services/steam_detector.dart';
import 'package:squirrel_play/data/services/steam_library_parser.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_metadata_chain.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/repositories/scan_directory_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:squirrel_play/presentation/blocs/game_detail/game_detail_bloc.dart';
import 'package:squirrel_play/presentation/blocs/game_library/game_library_bloc.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_cubit.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_test_bloc.dart';
import 'package:squirrel_play/presentation/blocs/home/home_bloc.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_bloc.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_bloc.dart';
import 'package:squirrel_play/presentation/blocs/steam_scanner/steam_scanner_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:uuid/uuid.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Configures dependency injection for the application.
///
/// Registers all services, repositories, and BLoCs as singletons.
Future<void> configureDependencies() async {
  // Shared Preferences (for API key storage)
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Database
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());

  // Services
  getIt.registerSingleton<GamepadService>(GamepadService.instance);
  getIt.registerSingleton<SoundService>(SoundService.instance);
  getIt.registerSingleton<FocusTraversalService>(FocusTraversalService.instance);
  getIt.registerSingleton<FileScannerService>(FileScannerService());
  getIt.registerSingleton<GameLauncherService>(GameLauncherService());
  getIt.registerSingleton<Uuid>(const Uuid());

  // Platform Info (for testable platform-specific code)
  getIt.registerSingleton<PlatformInfo>(PlatformInfoImpl());

  // Steam Integration Services
  getIt.registerSingleton<SteamDetector>(
    SteamDetector(platformInfo: getIt<PlatformInfo>()),
  );
  getIt.registerSingleton<SteamLibraryParser>(
    SteamLibraryParser(platformInfo: getIt<PlatformInfo>()),
  );
  getIt.registerSingleton<SteamManifestParser>(
    SteamManifestParser(
      platformInfo: getIt<PlatformInfo>(),
    ),
  );

  // API Key Service
  getIt.registerSingleton<ApiKeyService>(
    ApiKeyService(prefs: getIt<SharedPreferences>()),
  );

  // Dio instance for Steam Store API (separate from RAWG)
  getIt.registerSingleton<Dio>(
    Dio(
      BaseOptions(
        baseUrl: 'https://store.steampowered.com/api/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    ),
    instanceName: 'steamStoreDio',
  );

  // Metadata Sources (singletons - aggregator holds permanent references)
  getIt.registerSingleton<SteamLocalSource>(
    SteamLocalSource(
      manifestParser: getIt<SteamManifestParser>(),
    ),
  );

  getIt.registerSingleton<SteamStoreSource>(
    SteamStoreSource(
      dio: getIt<Dio>(instanceName: 'steamStoreDio'),
    ),
  );

  getIt.registerSingleton<SteamMetadataAdapter>(
    SteamMetadataAdapter(
      steamLocalSource: getIt<SteamLocalSource>(),
      steamStoreSource: getIt<SteamStoreSource>(),
    ),
  );

  getIt.registerSingleton<RawgSource>(
    RawgSource(
      apiKeyService: getIt<ApiKeyService>(),
    ),
  );

  getIt.registerSingleton<RawgBatchSearchService>(
    RawgBatchSearchService(
      rawgSource: getIt<RawgSource>(),
    ),
  );

  // Metadata Aggregator (singleton with named source parameters)
  getIt.registerSingleton<MetadataAggregator>(
    MetadataAggregator(
      steamMetadataAdapter: getIt<SteamMetadataAdapter>(),
      rawgSource: getIt<RawgSource>(),
    ),
  );

  // Metadata Service
  getIt.registerSingleton<MetadataService>(
    MetadataService(
      apiKeyService: getIt<ApiKeyService>(),
      metadataAggregator: getIt<MetadataAggregator>(),
      rawgSource: getIt<RawgSource>(),
    ),
  );

  // Directory Metadata Chain
  getIt.registerSingleton<GameMetadataHandler>(
    DirectoryMetadataChain.build(
      manifestParser: getIt<SteamManifestParser>(),
    ),
  );

  // Register GameLauncher interface pointing to the service
  getIt.registerSingleton<GameLauncher>(getIt<GameLauncherService>());

  // Repositories
  getIt.registerSingleton<GameRepository>(
    GameRepositoryImpl(databaseHelper: getIt<DatabaseHelper>()),
  );
  getIt.registerSingleton<ScanDirectoryRepository>(
    ScanDirectoryRepositoryImpl(
      databaseHelper: getIt<DatabaseHelper>(),
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerSingleton<HomeRepository>(
    HomeRepositoryImpl(gameRepository: getIt<GameRepository>()),
  );
  getIt.registerSingleton<MetadataRepository>(
    MetadataRepositoryImpl(
      databaseHelper: getIt<DatabaseHelper>(),
      metadataService: getIt<MetadataService>(),
      metadataAggregator: getIt<MetadataAggregator>(),
      gameRepository: getIt<GameRepository>(),
      rawgBatchSearchService: getIt<RawgBatchSearchService>(),
    ),
  );

  // BLoCs/Cubits
  getIt.registerSingleton<GamepadCubit>(
    GamepadCubit(gamepadService: getIt<GamepadService>()),
  );

  // Factory for AddGameBloc (needs fresh instance per dialog)
  getIt.registerFactory<AddGameBloc>(() => AddGameBloc(
        gameRepository: getIt<GameRepository>(),
        homeRepository: getIt<HomeRepository>() as HomeRepositoryImpl,
        metadataHandler: getIt<GameMetadataHandler>(),
        scanDirectoryRepository: getIt<ScanDirectoryRepository>(),
        uuid: getIt<Uuid>(),
        onGamesAdded: null,
      ));

  // Factory for GameLibraryBloc
  getIt.registerFactory<GameLibraryBloc>(() => GameLibraryBloc(
        gameRepository: getIt<GameRepository>(),
        homeRepository: getIt<HomeRepository>() as HomeRepositoryImpl,
      ));

  // Factory for GameDetailBloc
  getIt.registerFactory<GameDetailBloc>(() => GameDetailBloc(
        gameRepository: getIt<GameRepository>(),
        metadataRepository: getIt<MetadataRepository>(),
        gameLauncher: getIt<GameLauncher>(),
        homeRepository: getIt<HomeRepository>(),
      ));

  // Factory for HomeBloc
  getIt.registerFactory<HomeBloc>(() => HomeBloc(
        homeRepository: getIt<HomeRepository>(),
        gameRepository: getIt<GameRepository>(),
        metadataRepository: getIt<MetadataRepository>(),
        gameLauncher: getIt<GameLauncher>(),
      ));

  // Factory for MetadataBloc
  getIt.registerFactory<MetadataBloc>(() => MetadataBloc(
        metadataRepository: getIt<MetadataRepository>(),
        gameRepository: getIt<GameRepository>(),
      ));

  // Factory for SteamScannerBloc
  getIt.registerFactory<SteamScannerBloc>(() => SteamScannerBloc(
        steamDetector: getIt<SteamDetector>(),
        libraryParser: getIt<SteamLibraryParser>(),
        manifestParser: getIt<SteamManifestParser>(),
        gameRepository: getIt<GameRepository>(),
        metadataRepository: getIt<MetadataRepository>(),
        metadataBloc: getIt<MetadataBloc>(),
        platformInfo: getIt<PlatformInfo>(),
        uuid: getIt<Uuid>(),
      ));

  // Factory for GamepadTestBloc (needs fresh instance per page visit)
  getIt.registerFactory<GamepadTestBloc>(() => GamepadTestBloc(
        gamepadService: getIt<GamepadService>(),
      ));

  // Singleton for QuickScanBloc - lives for app lifetime, handles background scans
  getIt.registerLazySingleton<QuickScanBloc>(() => QuickScanBloc(
        gameRepository: getIt<GameRepository>(),
        scanDirectoryRepository: getIt<ScanDirectoryRepository>(),
        fileScannerService: getIt<FileScannerService>(),
        steamDetector: getIt<SteamDetector>(),
        steamLibraryParser: getIt<SteamLibraryParser>(),
        steamManifestParser: getIt<SteamManifestParser>(),
        homeRepository: getIt<HomeRepository>() as HomeRepositoryImpl,
        metadataBloc: getIt<MetadataBloc>(),
        metadataRepository: getIt<MetadataRepository>(),
        uuid: getIt<Uuid>(),
      ));

  // Initialize services
  await getIt<DatabaseHelper>().database; // Ensure database is initialized
  await getIt<GamepadService>().initialize();
  await getIt<SoundService>().initialize();
  await getIt<MetadataService>().initialize(); // Initialize metadata service
  await getIt<FocusTraversalService>().initialize(
    gamepadService: getIt<GamepadService>(),
  );
}
