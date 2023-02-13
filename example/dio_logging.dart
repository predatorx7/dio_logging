import 'package:dio/dio.dart';
import 'package:dio_logging/dio_logging.dart';
import 'package:logging/logging.dart';

void main() async {
  final client = Dio();

  final myLogger = Logger('my_logger');

  hierarchicalLoggingEnabled = true;
  myLogger.level = Level.ALL;

  myLogger.onRecord.listen((event) {
    final message = event.object?.toString() ?? event.message;
    if (event.error != null) print(event.error.toString());
    print(message);
    if (event.stackTrace != null) print(event.stackTrace.toString());
  });

  client.interceptors.add(DioLogging(logger: myLogger));

  final response = await client.get(
    'https://jsonplaceholder.typicode.com/todos/1',
  );

  final data = response.data;

  myLogger.info('Received data: $data');
}
