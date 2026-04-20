import 'package:logging/logging.dart';

class AppLogger {
  static void init({Level level = Level.INFO}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  static Logger getLogger(String name) => Logger(name);
}
