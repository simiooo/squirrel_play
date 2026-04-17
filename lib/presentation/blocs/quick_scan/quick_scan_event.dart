import 'package:equatable/equatable.dart';

/// Base class for QuickScan events.
abstract class QuickScanEvent extends Equatable {
  const QuickScanEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request a quick scan of all directories and Steam libraries.
class QuickScanRequested extends QuickScanEvent {
  const QuickScanRequested();
}

/// Event to cancel an in-progress scan.
class QuickScanCancelled extends QuickScanEvent {
  const QuickScanCancelled();
}
