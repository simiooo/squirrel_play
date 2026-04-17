import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/app/router.dart';
import 'package:squirrel_play/core/i18n/locale_cubit.dart';
import 'package:squirrel_play/core/theme/app_theme.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_cubit.dart';
import 'package:squirrel_play/presentation/blocs/navigation/navigation_cubit.dart';

/// The root application widget.
///
/// Configures the [MaterialApp.router] with:
/// - GoRouter for navigation
/// - Dark theme from [AppTheme.darkTheme]
/// - Localization delegates for English and Chinese
/// - BLoC providers for state management
/// - LocaleCubit for language switching
class SquirrelPlayApp extends StatelessWidget {
  /// Creates the root application widget.
  const SquirrelPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => getIt<GamepadCubit>()),
        BlocProvider(
          create: (_) => LocaleCubit(prefs: getIt<SharedPreferences>()),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp.router(
            title: 'Squirrel Play',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,

            // Localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('zh'), // Chinese Simplified
            ],

            // Current locale from LocaleCubit
            locale: localeState.locale,

            // Locale resolution
            localeResolutionCallback: (locale, supportedLocales) {
              // Default to English if locale not supported
              if (locale == null) {
                return const Locale('en');
              }

              // Check for exact match
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }

              // Default to English
              return const Locale('en');
            },

            // Router
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}