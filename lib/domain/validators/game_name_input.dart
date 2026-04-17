import 'package:formz/formz.dart';

/// Validation error types for game name input.
enum GameNameValidationError {
  /// Input is empty.
  empty,

  /// Input is too short (less than 1 character).
  tooShort,
}

/// Formz input for game name validation.
class GameNameInput extends FormzInput<String, GameNameValidationError> {
  const GameNameInput.pure() : super.pure('');
  const GameNameInput.dirty([super.value = '']) : super.dirty();

  @override
  GameNameValidationError? validator(String value) {
    if (value.isEmpty) {
      return GameNameValidationError.empty;
    }
    if (value.trim().isEmpty) {
      return GameNameValidationError.tooShort;
    }
    return null;
  }

  /// Returns a user-friendly error message.
  String? get errorMessage {
    if (isPure) return null;
    switch (error) {
      case GameNameValidationError.empty:
        return 'Game name is required';
      case GameNameValidationError.tooShort:
        return 'Game name must be at least 1 character';
      default:
        return null;
    }
  }
}
