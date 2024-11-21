// lib/src/core/utils/logger.dart
import 'package:logging/logging.dart';

class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}\nStackTrace: ${record.stackTrace}');
      }
    });
    _logger = Logger('PicturePerfect');
  }

  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
  static void debug(String message) => _logger.fine(message);
}
