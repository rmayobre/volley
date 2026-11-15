import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:volley_lints/src/rules/encodable_rules.dart';

import 'helpers.dart';
import 'stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsupportedPropertyTest);
    defineReflectiveTests(InvalidEncodableClassTest);
    defineReflectiveTests(UntypedPropertyTest);
    defineReflectiveTests(IgnoredFieldTest);
  });
}

@reflectiveTest
class UnsupportedPropertyTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = EncodableUnsupportedProperty();
    super.setUp();
  }

  Future<void> test_function_field() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  final void Function() callback;
  const Job(this.callback);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'this.callback'), 'this.callback'.length),
    ]);
  }

  Future<void> test_int_keyed_map_and_nested_list() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  final Map<int, String> byId;
  final List<Stream<int>> streams;
  const Job(this.byId, this.streams);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'this.byId'), 'this.byId'.length),
      lint(at(src, 'this.streams'), 'this.streams'.length),
    ]);
  }

  Future<void> test_class_not_encodable() async {
    const src =
        '''
$header
class Plain {}

@encodable
final class Job implements Message {
  final Plain plain;
  const Job(this.plain);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'this.plain'), 'this.plain'.length),
    ]);
  }

  Future<void> test_supported_types() async {
    await assertNoDiagnostics('''
$header
enum Color { red }

@encodable
final class Inner implements Message {
  final int n;
  const Inner(this.n);
}

@encodable
final class Job implements Message {
  final int a;
  final double b;
  final String c;
  final bool d;
  final DateTime e;
  final Duration f;
  final BigInt g;
  final RegExp h;
  final Color i;
  final List<Inner> j;
  final Map<String, Set<int>> k;
  final Inner? l;
  final Object? m;
  const Job(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h,
      this.i, this.j, this.k, this.l, this.m);
}
''');
  }

  Future<void> test_ignores_non_encodable_classes() async {
    await assertNoDiagnostics('''
$header
final class Job implements Message {
  final void Function() callback;
  const Job(this.callback);
}
''');
  }
}

@reflectiveTest
class InvalidEncodableClassTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = InvalidEncodableClass();
    super.setUp();
  }

  Future<void> test_not_a_message() async {
    const src =
        '''
$header
@encodable
final class Job {
  const Job();
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Job {'), 3, messageContainsAll: ['implement Message']),
    ]);
  }

  Future<void> test_generic() async {
    const src =
        '''
$header
@encodable
final class Job<T> implements Message {
  const Job();
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Job<T>'), 3, messageContainsAll: ['generic']),
    ]);
  }

  Future<void> test_abstract() async {
    const src =
        '''
$header
@encodable
abstract class Job implements Message {}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'Job implements'), 3, messageContainsAll: ['concrete']),
    ]);
  }

  Future<void> test_private_parameter() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  final int _n;
  const Job(this._n);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'this._n'), 'this._n'.length, messageContainsAll: ['private']),
    ]);
  }

  Future<void> test_parameter_without_field() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  const Job(int n);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'int n'), 'int n'.length, messageContainsAll: ['no field']),
    ]);
  }

  Future<void> test_valid() async {
    await assertNoDiagnostics('''
$header
@encodable
final class Job implements Message {
  final int n;
  int get doubled => n * 2;
  const Job(this.n);
}
''');
  }
}

@reflectiveTest
class UntypedPropertyTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = EncodableUntypedProperty();
    super.setUp();
  }

  Future<void> test_dynamic_and_object() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  final dynamic a;
  final Object b;
  const Job(this.a, this.b);
}
''';
    await assertDiagnostics(src, [
      lint(at(src, 'this.a'), 'this.a'.length),
      lint(at(src, 'this.b'), 'this.b'.length),
    ]);
  }

  Future<void> test_concrete_is_fine() async {
    await assertNoDiagnostics('''
$header
@encodable
final class Job implements Message {
  final int a;
  const Job(this.a);
}
''');
  }
}

@reflectiveTest
class IgnoredFieldTest extends AnalysisRuleTest with VolleyStubs {
  @override
  void setUp() {
    rule = EncodableIgnoredField();
    super.setUp();
  }

  Future<void> test_field_not_in_constructor() async {
    const src =
        '''
$header
@encodable
final class Job implements Message {
  final int n;
  int? cached;
  Job(this.n);
}
''';
    await assertDiagnostics(src, [lint(at(src, 'cached'), 'cached'.length)]);
  }

  Future<void> test_derived_and_static_fields_are_fine() async {
    await assertNoDiagnostics('''
$header
@encodable
final class Job implements Message {
  static const label = 'job';
  final int n;
  final int doubled;
  final int tripled = 3;
  const Job(this.n) : doubled = n * 2;
}
''');
  }
}
