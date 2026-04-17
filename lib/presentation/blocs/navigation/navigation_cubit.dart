import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Enum representing the current page in the navigation.
enum NavigationPage {
  /// Home page with game rows and dynamic background.
  home,

  /// Library page with grid view of all games.
  library,
}

/// State for the navigation cubit.
class NavigationState extends Equatable {
  /// Creates a navigation state.
  const NavigationState({
    required this.currentPage,
  });

  /// The currently active page.
  final NavigationPage currentPage;

  /// Initial state with home page selected.
  factory NavigationState.initial() {
    return const NavigationState(currentPage: NavigationPage.home);
  }

  /// Creates a copy of this state with the given fields replaced.
  NavigationState copyWith({
    NavigationPage? currentPage,
  }) {
    return NavigationState(
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [currentPage];
}

/// Cubit for managing navigation state.
///
/// Tracks the current page and provides methods to navigate between pages.
/// Used by the app shell to display the correct content.
class NavigationCubit extends Cubit<NavigationState> {
  /// Creates a navigation cubit with initial state.
  NavigationCubit() : super(NavigationState.initial());

  /// Navigates to the home page.
  void navigateToHome() {
    if (state.currentPage != NavigationPage.home) {
      emit(state.copyWith(currentPage: NavigationPage.home));
    }
  }

  /// Navigates to the library page.
  void navigateToLibrary() {
    if (state.currentPage != NavigationPage.library) {
      emit(state.copyWith(currentPage: NavigationPage.library));
    }
  }

  /// Gets whether the home page is currently active.
  bool get isHomePage => state.currentPage == NavigationPage.home;

  /// Gets whether the library page is currently active.
  bool get isLibraryPage => state.currentPage == NavigationPage.library;
}
