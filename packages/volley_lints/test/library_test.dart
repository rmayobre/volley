import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:volley_lints/src/rules/closure_rules.dart';
import 'package:volley_lints/src/rules/library_rules.dart';

import 'helpers.dart';
import 'stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingGeneratedPartTest);
    defineReflectiveTests(WorkerLibraryImportsNativeTest);
    defineReflectiveTests(UnsendableClosureCaptureTest);
  });
}

@reflectiveTest
class MissingGeneratedPartTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = MissingGeneratedPart();
    super.setUp();
  }

  Future<void> test_missing() async {
    final src = '''
$header
@coroutine
int one() => 1;
''';
    await assertDiagnostics(src, [
      lint(at(src, '@coroutine'), '@coroutine'.length,
          messageContainsAll: ['test.gen.dart']),
    ]);
  }

  Future<void> test_present() async {
    newFile('$testPackageLibPath/test.gen.dart', "part of 'test.dart';");
    await assertNoDiagnostics('''
$header
part 'test.gen.dart';

@coroutine
int one() => 1;
''');
  }

  Future<void> test_nothing_annotated() async {
    await assertNoDiagnostics('''
$header
int one() => 1;
''');
  }
}

@reflectiveTest
class WorkerLibraryImportsNativeTest extends AnalysisRuleTest
    with VolleyStubs {
  @override
  void setUp() {
    rule = WorkerLibraryImportsNative();
    super.setUp();
  }

  Future<void> test_dart_io_in_worker_library() async {
    final src = '''
$header
import 'dart:io';

@coroutine
int one() => 1;
''';
    await assertDiagnostics(src, [
      lint(at(src, "import 'dart:io'"), "import 'dart:io';".length),
    ]);
  }

  Future<void> test_dart_io_without_workers_is_fine() async {
    await assertNoDiagnostics('''
import 'dart:io';

int one() => 1;
''');
  }
}

@reflectiveTest
class UnsendableClosureCaptureTest extends AnalysisRuleTest
    with VolleyStubs {
  @override
  void setUp() {
    rule = UnsendableClosureCapture();
    super.setUp();
  }

  Future<void> test_captures_stream_controller() async {
    final src = '''
import 'package:volley/volley.dart';

void run(Stream<int> sink, int n) {
  coroutine(() {
    sink.hashCode;
    return n;
  });
}
''';
    await assertDiagnostics(src, [lint(at(src, 'sink.hashCode'), 'sink'.length)]);
  }

  Future<void> test_captures_function_in_actor() async {
    final src = '''
import 'package:volley/volley.dart';

final class Ping implements Message {}

void run(void Function() log) {
  actor<Ping, Ping>((Ping p) {
    log();
    return p;
  });
}
''';
    await assertDiagnostics(src, [lint(at(src, 'log();'), 'log'.length)]);
  }

  Future<void> test_sendable_capture_and_locals_are_fine() async {
    await assertNoDiagnostics('''
import 'package:volley/volley.dart';

void run(int n, List<String> names) {
  coroutine(() {
    final local = n + names.length;
    return local;
  });
}
''');
  }

  Future<void> test_top_level_function_is_fine() async {
    await assertNoDiagnostics('''
import 'package:volley/volley.dart';

int work() => 1;

void run() {
  coroutine(work);
}
''');
  }
}
