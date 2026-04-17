import 'package:formz/formz.dart';

/// Validation error types for executable path input.
enum ExecutablePathValidationError {
  /// Input is empty.
  empty,

  /// Path does not end with .exe.
  notExecutable,
}

/// Formz input for executable path validation.
class ExecutablePathInput extends FormzInput<String, ExecutablePathValidationError> {
  const ExecutablePathInput.pure() : super.pure('');
  const ExecutablePathInput.dirty([super.value = '']) : super.dirty();

  @override
  ExecutablePathValidationError? validator(String value) {
    if (value.isEmpty) {
      return ExecutablePathValidationError.empty;
    }
    if (!value.toLowerCase().endsWith('.exe')) {
      return ExecutablePathValidationError.notExecutable;
    }
    return null;
  }

  /// Returns a user-friendly error message.
  String? get errorMessage {
    if (isPure) return null;
    switch (error) {
      case ExecutablePathValidationError.empty:
        return 'Please select an executable file';
      case ExecutablePathValidationError.notExecutable:
        return 'File must be a Windows executable (.exe)';
      default:
        return null;
    }
  }
}
