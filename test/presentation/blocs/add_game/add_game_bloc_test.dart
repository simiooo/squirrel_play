import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/models/discovered_executable_model.dart';
import 'package:squirrel_play/data/repositories/home_repository_impl.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:uuid/uuid.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockHomeRepositoryImpl extends Mock implements HomeRepositoryImpl {}

class MockGameMetadataHandler extends Mock implements GameMetadataHandler {}

class FakeGame extends Fake implements Game {}

class FakeDirectoryContext extends Fake implements DirectoryContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
    registerFallbackValue(FakeDirectoryContext());
  });

  group('AddGameBloc', () {
    late GameRepository gameRepository;
    late HomeRepositoryImpl homeRepository;
    late MockGameMetadataHandler metadataHandler;
    late AddGameBloc bloc;

    setUp(() {
      gameRepository = MockGameRepository();
      homeRepository = MockHomeRepositoryImpl();
      metadataHandler = MockGameMetadataHandler();

      when(() => gameRepository.gameExists(any()))
          .thenAnswer((_) async => false);
      when(() => gameRepository.addGame(any()))
          .thenAnswer((invocation) async {
        return invocation.positionalArguments.first as Game;
      });
      when(() => homeRepository.notifyGamesChanged())
          .thenAnswer((_) async => {});
      when(() => gameRepository.getAllGames())
          .thenAnswer((_) async => []);

      bloc = AddGameBloc(
        gameRepository: gameRepository,
        homeRepository: homeRepository,
        metadataHandler: metadataHandler,
        uuid: const Uuid(),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is AddGameInitial', () {
      expect(bloc.state, const AddGameInitial());
    });

    group('FileSelected', () {
      blocTest<AddGameBloc, AddGameState>(
        'triggers chain and uses suggested title in emitted state',
        build: () => bloc,
        seed: () => const ManualAddForm(),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((invocation) async {
            final context = invocation.positionalArguments.first as DirectoryContext;
            context.title = 'Suggested Game Title';
          });
        },
        act: (bloc) => bloc.add(const FileSelected(
          path: '/games/mygame/game.exe',
          fileName: 'game.exe',
        )),
        expect: () => [
          isA<ManualAddForm>().having(
            (s) => s.name,
            'name',
            'Suggested Game Title',
          ).having(
            (s) => s.executablePath,
            'executablePath',
            '/games/mygame/game.exe',
          ).having(
            (s) => s.fileName,
            'fileName',
            'game.exe',
          ),
        ],
        verify: (_) {
          verify(() => metadataHandler.handle(any())).called(1);
        },
      );

      blocTest<AddGameBloc, AddGameState>(
        'falls back to cleaned filename when chain returns null title',
        build: () => bloc,
        seed: () => const ManualAddForm(),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((_) async {});
        },
        act: (bloc) => bloc.add(const FileSelected(
          path: '/games/mygame/my-awesome_game.exe',
          fileName: 'my-awesome_game.exe',
        )),
        expect: () => [
          isA<ManualAddForm>().having(
            (s) => s.name,
            'name',
            'my-awesome_game',
          ),
        ],
      );
    });

    group('ConfirmManualAdd', () {
      blocTest<AddGameBloc, AddGameState>(
        'uses the name from state (set by chain in FileSelected)',
        build: () => bloc,
        seed: () => const ManualAddForm(
          executablePath: '/games/mygame/game.exe',
          fileName: 'game.exe',
          name: 'Chain Suggested Title',
        ),
        act: (bloc) => bloc.add(const ConfirmManualAdd()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verify(() => gameRepository.addGame(any(
            that: isA<Game>().having(
              (g) => g.title,
              'title',
              'Chain Suggested Title',
            ),
          ))).called(1);
        },
      );
    });

    group('ConfirmScanSelection', () {
      final testExecutables = [
        DiscoveredExecutableModel(
          path: '/games/steam/steamapps/common/GameA/gameA.exe',
          fileName: 'gameA.exe',
          directoryId: 'dir1',
          isSelected: true,
        ),
        DiscoveredExecutableModel(
          path: '/games/standalone/GameB.exe',
          fileName: 'GameB.exe',
          directoryId: 'dir2',
          isSelected: true,
        ),
      ];

      blocTest<AddGameBloc, AddGameState>(
        'uses suggestedTitle from chain for Game.title',
        build: () => bloc,
        seed: () => ScanResults(
          directories: const [],
          executables: testExecutables,
        ),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((invocation) async {
            final context = invocation.positionalArguments.first as DirectoryContext;
            if (context.executablePath.contains('GameA')) {
              context.title = 'Steam Official Game A';
            } else {
              context.title = 'Cleaned Game B';
            }
          });
        },
        act: (bloc) => bloc.add(const ConfirmScanSelection()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verify(() => gameRepository.addGame(any(
            that: isA<Game>().having(
              (g) => g.title,
              'title',
              'Steam Official Game A',
            ),
          ))).called(1);
          verify(() => gameRepository.addGame(any(
            that: isA<Game>().having(
              (g) => g.title,
              'title',
              'Cleaned Game B',
            ),
          ))).called(1);
        },
      );

      blocTest<AddGameBloc, AddGameState>(
        'sets suggestedTitle on executable during confirmation',
        build: () => bloc,
        seed: () => ScanResults(
          directories: const [],
          executables: [
            DiscoveredExecutableModel(
              path: '/games/mygame/game.exe',
              fileName: 'game.exe',
              directoryId: 'dir1',
              isSelected: true,
            ),
          ],
        ),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((invocation) async {
            final context = invocation.positionalArguments.first as DirectoryContext;
            context.title = 'Suggested From Chain';
          });
        },
        act: (bloc) => bloc.add(const ConfirmScanSelection()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verify(() => gameRepository.addGame(any(
            that: isA<Game>().having(
              (g) => g.title,
              'title',
              'Suggested From Chain',
            ),
          ))).called(1);
        },
      );

      blocTest<AddGameBloc, AddGameState>(
        'falls back to fileName without .exe when chain returns null',
        build: () => bloc,
        seed: () => ScanResults(
          directories: const [],
          executables: [
            DiscoveredExecutableModel(
              path: '/games/mygame/my_game.exe',
              fileName: 'my_game.exe',
              directoryId: 'dir1',
              isSelected: true,
            ),
          ],
        ),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((_) async {});
        },
        act: (bloc) => bloc.add(const ConfirmScanSelection()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verify(() => gameRepository.addGame(any(
            that: isA<Game>().having(
              (g) => g.title,
              'title',
              'my_game',
            ),
          ))).called(1);
        },
      );

      blocTest<AddGameBloc, AddGameState>(
        'skips unselected executables',
        build: () => bloc,
        seed: () => ScanResults(
          directories: const [],
          executables: [
            DiscoveredExecutableModel(
              path: '/games/mygame/gameA.exe',
              fileName: 'gameA.exe',
              directoryId: 'dir1',
              isSelected: true,
            ),
            DiscoveredExecutableModel(
              path: '/games/mygame/gameB.exe',
              fileName: 'gameB.exe',
              directoryId: 'dir1',
              isSelected: false,
            ),
          ],
        ),
        setUp: () {
          when(() => metadataHandler.handle(any())).thenAnswer((_) async {});
        },
        act: (bloc) => bloc.add(const ConfirmScanSelection()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verify(() => gameRepository.addGame(any())).called(1);
        },
      );

      blocTest<AddGameBloc, AddGameState>(
        'skips duplicates silently',
        build: () => bloc,
        seed: () => ScanResults(
          directories: const [],
          executables: [
            DiscoveredExecutableModel(
              path: '/games/mygame/gameA.exe',
              fileName: 'gameA.exe',
              directoryId: 'dir1',
              isSelected: true,
            ),
          ],
        ),
        setUp: () {
          when(() => gameRepository.gameExists('/games/mygame/gameA.exe'))
              .thenAnswer((_) async => true);
        },
        act: (bloc) => bloc.add(const ConfirmScanSelection()),
        expect: () => [
          const Adding(),
          const AddGameInitial(),
        ],
        verify: (_) {
          verifyNever(() => gameRepository.addGame(any()));
        },
      );
    });
  });
}
