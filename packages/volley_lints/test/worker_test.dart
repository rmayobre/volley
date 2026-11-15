import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:volley_lints/src/rules/worker_rules.dart';

import 'helpers.dart';
import 'stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidActorTest);
    defineReflectiveTests(InvalidCoroutineTest);
    defineReflectiveTests(InvalidSingletonTest);
    defineReflectiveTests(WorkerUnsupportedTypeTest);
  });
}

const _messages = '''
@encodable
final class Ping implements Message {
  final String text;
  const Ping(this.text);
}

@encodable
final class Pong implements Message {
  final String text;
  const Pong(this.text);
}
''';

@reflectiveTest
class InvalidActorTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = InvalidActorFunction();
    super.setUp();
  }

  Future<void> test_valid() async {
    await assertNoDiagnostics('''
$header
$_messages
@actor
Future<Pong> echo(Ping ping) async => Pong(ping.text);

@actor
Pong sync(Ping ping) => Pong(ping.text);
''');
  }

  Future<void> test_two_parameters() async {
    final src = '''
$header
$_messages
@actor
Pong echo(Ping a, Ping b) => Pong(a.text);
''';
    await assertDiagnostics(src, [
      lint(at(src, 'echo'), 4, messageContainsAll: ['exactly one']),
    ]);
  }

  Future<void> test_optional_parameter() async {
    final src = '''
$header
$_messages
@actor
Pong echo([Ping? a]) => Pong('');
''';
    await assertDiagnostics(src, [lint(at(src, 'echo'), 4)]);
  }

  Future<void> test_not_a_message() async {
    final src = '''
$header
$_messages
@actor
int count(Ping ping) => 1;
''';
    await assertDiagnostics(src, [
      lint(at(src, 'count'), 5, messageContainsAll: ['return a Message']),
    ]);
  }

  Future<void> test_generic() async {
    final src = '''
$header
$_messages
@actor
Pong echo<T>(Ping ping) => Pong('');
''';
    await assertDiagnostics(src, [
      lint(at(src, 'echo'), 4, messageContainsAll: ['generic']),
    ]);
  }

  Future<void> test_method() async {
    final src = '''
$header
$_messages
class Host {
  @actor
  static Pong echo(Ping ping) => Pong('');
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'echo'), 4, messageContainsAll: ['top-level']),
    ]);
  }
}

@reflectiveTest
class InvalidCoroutineTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = InvalidCoroutineFunction();
    super.setUp();
  }

  Future<void> test_valid() async {
    await assertNoDiagnostics('''
$header
@coroutine
Future<int> sum(List<int> values, int offset) async => offset;
''');
  }

  Future<void> test_named_parameter() async {
    final src = '''
$header
@coroutine
int sum(List<int> values, {int offset = 0}) => offset;
''';
    await assertDiagnostics(src, [
      lint(at(src, 'sum'), 3, messageContainsAll: ['positional']),
    ]);
  }

  Future<void> test_generic() async {
    final src = '''
$header
@coroutine
T first<T>(List<int> values) => throw 'unreachable';
''';
    await assertDiagnostics(src, [lint(at(src, 'first'), 5)]);
  }
}

@reflectiveTest
class InvalidSingletonTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = InvalidSingletonClass();
    super.setUp();
  }

  Future<void> test_valid() async {
    await assertNoDiagnostics('''
$header
$_messages
@singleton
final class Counter extends SerializedSingleton<Pong, Ping> {
  @override
  Pong reduce(Ping event) => Pong(event.text);
}
''');
  }

  Future<void> test_not_a_singleton() async {
    final src = '''
$header
@singleton
final class Counter {}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Counter'), 7, messageContainsAll: ['extend']),
    ]);
  }

  Future<void> test_required_constructor_parameter() async {
    final src = '''
$header
$_messages
@singleton
final class Counter extends SerializedSingleton<Pong, Ping> {
  final int start;
  Counter(this.start);
  @override
  Pong reduce(Ping event) => Pong(event.text);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Counter extends'), 7, messageContainsAll: ['required']),
    ]);
  }

  Future<void> test_abstract() async {
    final src = '''
$header
$_messages
@singleton
abstract class Counter extends SerializedSingleton<Pong, Ping> {}
''';
    await assertDiagnostics(src, [lint(at(src, 'Counter extends'), 7)]);
  }
}

@reflectiveTest
class WorkerUnsupportedTypeTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = WorkerUnsupportedType();
    super.setUp();
  }

  Future<void> test_coroutine_parameter_and_result() async {
    final src = '''
$header
class Plain {}

@coroutine
Plain make(Plain input) => input;
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Plain make'), 5),
      lint(at(src, 'Plain input'), 11),
    ]);
  }

  Future<void> test_actor_message_not_encodable() async {
    final src = '''
$header
final class Raw implements Message {
  const Raw();
}

@actor
Raw echo(Raw raw) => raw;
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Raw echo'), 3),
      lint(at(src, 'Raw raw'), 7),
    ]);
  }

  Future<void> test_singleton_messages() async {
    final src = '''
$header
final class Raw implements Message {
  const Raw();
}

@singleton
final class Counter extends SerializedSingleton<Raw, Raw> {
  @override
  Raw reduce(Raw event) => event;
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Raw, Raw'), 3),
      lint(at(src, 'Raw>'), 3),
    ]);
  }

  Future<void> test_generic_is_left_to_the_shape_rule() async {
    await assertNoDiagnostics('''
$header
@coroutine
T first<T>(List<int> values) => throw 'no';
''');
  }

  Future<void> test_supported() async {
    await assertNoDiagnostics('''
$header
$_messages
@actor
Future<Pong> echo(Ping ping) async => Pong(ping.text);

@coroutine
Future<Map<String, List<int>>> group(List<String> keys, Duration d) async => {};

@singleton
final class Counter extends SerializedSingleton<Pong, Ping> {
  @override
  Pong reduce(Ping event) => Pong(event.text);
}
''');
  }
}
