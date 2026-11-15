import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag; // ignore: implementation_imports
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

/// Minimal stand-ins for the volley packages, enough to resolve the code under
/// test. Mixed into every rule test.
mixin VolleyStubs on AnalysisRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    diag.unusedImport,
  ];

  @override
  void setUp() {
    newPackage('volley_api').addFile('lib/volley_api.dart', '''
abstract interface class Message {}
abstract interface class MapEncodableMessage implements Message {
  Map<String, Object?> toMap();
}
abstract interface class Disposable {
  void dispose();
}
abstract interface class Channel<I, O> {}
abstract interface class Actor<I extends Message, O extends Message>
    implements Disposable {}
abstract interface class Coroutine<R> implements Disposable {}
''');
    newPackage('volley').addFile('lib/volley.dart', '''
import 'dart:async';
import 'package:volley_api/volley_api.dart';
export 'package:volley_api/volley_api.dart';

Future<Actor<I, O>> actor<I extends Message, O extends Message>(
  FutureOr<I> Function(O) reducer,
) => throw UnimplementedError();

Coroutine<R> coroutine<R>(FutureOr<R> Function() compute) =>
    throw UnimplementedError();

abstract class Singleton<O extends Message, I extends Message> {
  O reduce(I event);
}
abstract class SerializedSingleton<O extends Message, I extends Message>
    extends Singleton<O, I> {}
abstract class ConcurrentSingleton<O extends Message, I extends Message>
    extends Singleton<O, I> {}
''');
    newPackage('volley_workers').addFile('lib/volley_workers.dart', '''
export 'package:volley/volley.dart';
final class ActorWorker { const ActorWorker(); }
const actor = ActorWorker();
final class CoroutineWorker { const CoroutineWorker(); }
const coroutine = CoroutineWorker();
final class Encodable { const Encodable(); }
const encodable = Encodable();
final class SingletonWorker { const SingletonWorker(); }
const singleton = SingletonWorker();
''');
    super.setUp();
  }
}
