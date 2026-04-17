import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/core/utils/filename_cleaner.dart';

void main() {
  group('FilenameCleaner', () {
    group('cleanForDisplay', () {
      test('should remove file extension', () {
        final result = FilenameCleaner.cleanForDisplay('game.exe');
        expect(result, equals('game'));
      });

      test('should replace underscores with spaces', () {
        final result = FilenameCleaner.cleanForDisplay('my_game.exe');
        expect(result, equals('my game'));
      });

      test('should replace hyphens with spaces', () {
        final result = FilenameCleaner.cleanForDisplay('my-game.exe');
        expect(result, equals('my game'));
      });

      test('should trim extra spaces', () {
        final result = FilenameCleaner.cleanForDisplay('  my_game  .exe  ');
        expect(result, equals('my game'));
      });
    });

    group('cleanForSearch - Rule 1: Remove file extension', () {
      test('should remove .exe extension', () {
        final result = FilenameCleaner.cleanForSearch('game.exe');
        expect(result, equals('game'));
      });

      test('should remove .msi extension', () {
        final result = FilenameCleaner.cleanForSearch('gametool.msi');
        expect(result, equals('gametool'));
      });

      test('should handle filenames without extension', () {
        final result = FilenameCleaner.cleanForSearch('game');
        expect(result, equals('game'));
      });
    });

    group('cleanForSearch - Rule 2: Replace underscores/hyphens with spaces', () {
      test('should replace underscores with spaces', () {
        final result = FilenameCleaner.cleanForSearch('my_game_file.exe');
        expect(result, equals('my game file'));
      });

      test('should replace hyphens with spaces', () {
        final result = FilenameCleaner.cleanForSearch('my-game-file.exe');
        expect(result, equals('my game file'));
      });

      test('should replace both underscores and hyphens', () {
        final result = FilenameCleaner.cleanForSearch('my-game_file.exe');
        expect(result, equals('my game file'));
      });
    });

    group('cleanForSearch - Rule 3: Remove version patterns', () {
      test('should remove v1.0 pattern', () {
        final result = FilenameCleaner.cleanForSearch('game v1.0.exe');
        expect(result, equals('game'));
      });

      test('should remove 1.0.0 pattern', () {
        final result = FilenameCleaner.cleanForSearch('game 1.0.0.exe');
        expect(result, equals('game'));
      });

      test('should remove v1.0.0 pattern', () {
        final result = FilenameCleaner.cleanForSearch('game v1.0.0.exe');
        expect(result, equals('game'));
      });

      test('should remove (v1.0) pattern', () {
        final result = FilenameCleaner.cleanForSearch('game (v1.0).exe');
        expect(result, equals('game'));
      });

      test('should remove [1.0.0] pattern', () {
        final result = FilenameCleaner.cleanForSearch('game [1.0.0].exe');
        expect(result, equals('game'));
      });

      test('should remove complex version like v2.1', () {
        final result = FilenameCleaner.cleanForSearch('Cyberpunk 2077 v2.1.exe');
        expect(result, equals('Cyberpunk 2077'));
      });

      test('should remove version like 1.5.6', () {
        final result = FilenameCleaner.cleanForSearch('Stardew Valley 1.5.6.exe');
        expect(result, equals('Stardew Valley'));
      });
    });

    group('cleanForSearch - Rule 4: Remove common suffixes', () {
      test('should remove setup suffix', () {
        final result = FilenameCleaner.cleanForSearch('game setup.exe');
        expect(result, equals('game'));
      });

      test('should remove installer suffix', () {
        final result = FilenameCleaner.cleanForSearch('game installer.exe');
        expect(result, equals('game'));
      });

      test('should remove uninstall suffix', () {
        final result = FilenameCleaner.cleanForSearch('game uninstall.exe');
        expect(result, equals('game'));
      });

      test('should remove launcher suffix', () {
        final result = FilenameCleaner.cleanForSearch('game launcher.exe');
        expect(result, equals('game'));
      });

      test('should remove patch suffix', () {
        final result = FilenameCleaner.cleanForSearch('game patch.exe');
        expect(result, equals('game'));
      });

      test('should remove update suffix', () {
        final result = FilenameCleaner.cleanForSearch('game update.exe');
        expect(result, equals('game'));
      });

      test('should handle case-insensitive suffixes', () {
        final result = FilenameCleaner.cleanForSearch('Game SETUP.exe');
        expect(result, equals('Game'));
      });
    });

    group('cleanForSearch - Rule 5: Remove platform suffixes', () {
      test('should remove win32 suffix', () {
        final result = FilenameCleaner.cleanForSearch('game win32.exe');
        expect(result, equals('game'));
      });

      test('should remove win64 suffix', () {
        final result = FilenameCleaner.cleanForSearch('game win64.exe');
        expect(result, equals('game'));
      });

      test('should remove x64 suffix', () {
        final result = FilenameCleaner.cleanForSearch('game x64.exe');
        expect(result, equals('game'));
      });

      test('should remove x86 suffix', () {
        final result = FilenameCleaner.cleanForSearch('game x86.exe');
        expect(result, equals('game'));
      });

      test('should remove windows suffix', () {
        final result = FilenameCleaner.cleanForSearch('game windows.exe');
        expect(result, equals('game'));
      });

      test('should remove pc suffix', () {
        final result = FilenameCleaner.cleanForSearch('game pc.exe');
        expect(result, equals('game'));
      });
    });

    group('cleanForSearch - Rule 6: Remove language suffixes', () {
      test('should remove en suffix', () {
        final result = FilenameCleaner.cleanForSearch('game en.exe');
        expect(result, equals('game'));
      });

      test('should remove eng suffix', () {
        final result = FilenameCleaner.cleanForSearch('game eng.exe');
        expect(result, equals('game'));
      });

      test('should remove english suffix', () {
        final result = FilenameCleaner.cleanForSearch('game english.exe');
        expect(result, equals('game'));
      });

      test('should remove multi suffix', () {
        final result = FilenameCleaner.cleanForSearch('game multi.exe');
        expect(result, equals('game'));
      });
    });

    group('cleanForSearch - Rule 7: Remove edition suffixes', () {
      test('should remove goty suffix', () {
        final result = FilenameCleaner.cleanForSearch('game goty.exe');
        expect(result, equals('game'));
      });

      test('should remove deluxe suffix', () {
        final result = FilenameCleaner.cleanForSearch('game deluxe.exe');
        expect(result, equals('game'));
      });

      test('should remove premium suffix', () {
        final result = FilenameCleaner.cleanForSearch('game premium.exe');
        expect(result, equals('game'));
      });

      test('should remove gold suffix', () {
        final result = FilenameCleaner.cleanForSearch('game gold.exe');
        expect(result, equals('game'));
      });

      test('should remove complete suffix', () {
        final result = FilenameCleaner.cleanForSearch('game complete.exe');
        expect(result, equals('game'));
      });

      test('should remove ultimate suffix', () {
        final result = FilenameCleaner.cleanForSearch('game ultimate.exe');
        expect(result, equals('game'));
      });
    });

    group('cleanForSearch - Rule 8: Remove common prefixes', () {
      test('should remove "the" prefix', () {
        final result = FilenameCleaner.cleanForSearch('the game.exe');
        expect(result, equals('game'));
      });

      test('should remove "a" prefix', () {
        final result = FilenameCleaner.cleanForSearch('a game.exe');
        expect(result, equals('game'));
      });

      test('should remove "an" prefix', () {
        final result = FilenameCleaner.cleanForSearch('an game.exe');
        expect(result, equals('game'));
      });

      test('should handle case-insensitive prefixes', () {
        final result = FilenameCleaner.cleanForSearch('The Game.exe');
        expect(result, equals('Game'));
      });

      test('should not remove prefix if not followed by space', () {
        final result = FilenameCleaner.cleanForSearch('thegame.exe');
        expect(result, equals('thegame'));
      });
    });

    group('cleanForSearch - Rule 9: Collapse multiple spaces', () {
      test('should collapse multiple spaces to single space', () {
        final result = FilenameCleaner.cleanForSearch('game    file.exe');
        expect(result, equals('game file'));
      });

      test('should handle mixed whitespace', () {
        final result = FilenameCleaner.cleanForSearch('game  \t\n  file.exe');
        expect(result, equals('game file'));
      });
    });

    group('cleanForSearch - Rule 10: Trim whitespace', () {
      test('should trim leading whitespace', () {
        final result = FilenameCleaner.cleanForSearch('   game.exe');
        expect(result, equals('game'));
      });

      test('should trim trailing whitespace', () {
        final result = FilenameCleaner.cleanForSearch('game.exe   ');
        expect(result, equals('game'));
      });

      test('should trim both leading and trailing whitespace', () {
        final result = FilenameCleaner.cleanForSearch('  game.exe  ');
        expect(result, equals('game'));
      });
    });

    group('cleanForSearch - Contract test cases', () {
      test('The Witcher 3 v1.32 setup.exe → Witcher 3', () {
        final result = FilenameCleaner.cleanForSearch('The Witcher 3 v1.32 setup.exe');
        expect(result, equals('Witcher 3'));
      });

      test('Hollow Knight Win64 Launcher.exe → Hollow Knight', () {
        final result = FilenameCleaner.cleanForSearch('Hollow Knight Win64 Launcher.exe');
        expect(result, equals('Hollow Knight'));
      });

      test('Cyberpunk 2077 v2.1 GOTY Win64.exe → Cyberpunk 2077', () {
        final result = FilenameCleaner.cleanForSearch('Cyberpunk 2077 v2.1 GOTY Win64.exe');
        expect(result, equals('Cyberpunk 2077'));
      });

      test('Stardew Valley 1.5.6.exe → Stardew Valley', () {
        final result = FilenameCleaner.cleanForSearch('Stardew Valley 1.5.6.exe');
        expect(result, equals('Stardew Valley'));
      });
    });

    group('getConfidenceScore', () {
      test('should return 0.0 for empty string', () {
        final result = FilenameCleaner.getConfidenceScore('');
        expect(result, equals(0.0));
      });

      test('should penalize very short names', () {
        final result = FilenameCleaner.getConfidenceScore('ab');
        expect(result, lessThan(1.0));
      });

      test('should penalize names that are just numbers', () {
        final result = FilenameCleaner.getConfidenceScore('12345');
        expect(result, lessThan(0.5));
      });

      test('should boost names with multiple words', () {
        final singleWord = FilenameCleaner.getConfidenceScore('game');
        final multiWord = FilenameCleaner.getConfidenceScore('my game');
        // Multi-word names should have equal or higher score (capped at 1.0)
        expect(multiWord, greaterThanOrEqualTo(singleWord));
      });

      test('should cap score at 1.0', () {
        final result = FilenameCleaner.getConfidenceScore('my awesome game title');
        expect(result, equals(1.0));
      });
    });
  });
}
