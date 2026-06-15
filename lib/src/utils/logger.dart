import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(methodCount: 0),
  // printer: SimplePrinter(),
);

/// Callback for warnings. Set this to receive warnings from the library.
/// Example: `fitToolWarning = (msg) => print('FIT warning: $msg');`
void Function(String message)? fitToolWarning;

/// Internal helper that logs warning and calls callback if set
void logWarning(String message) {
  logger.w(message);
  fitToolWarning?.call(message);
}
