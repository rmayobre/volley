import 'package:volley_api/volley_api.dart';

import '../../coroutine/coroutine_message.dart' show CoroutineMessage;
import '../../coroutine/coroutine_result.dart';

final class Bootstrapper {
  static Channel<CoroutineResult, CoroutineMessage> get coroutineChannel =>
      throw UnimplementedError(
        'Bootstrapper is not supported on this platform.',
      );

  static Future<void> initialize() async {
    throw UnimplementedError('Bootstrapper is not supported on this platform.');
  }
}
