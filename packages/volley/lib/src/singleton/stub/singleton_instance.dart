import 'package:volley_api/volley_api.dart';

import '../singleton.dart';

Future<Channel<I, O>> singletonInstance<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>(T Function() build) =>
    throw UnimplementedError('Singleton is not supported on this platform.');

Future<I> singletonRequest<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>(O message) =>
    throw UnimplementedError('Singleton is not supported on this platform.');
