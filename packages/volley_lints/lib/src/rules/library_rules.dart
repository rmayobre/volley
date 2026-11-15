import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../semantics.dart';

/// Declarations in [unit] that carry a `volley_workers` annotation.
Iterable<CompilationUnitMember> annotatedMembers(CompilationUnit unit) sync* {
  for (final member in unit.declarations) {
    final Element? element = switch (member) {
      ClassDeclaration() => member.declaredFragment?.element,
      FunctionDeclaration() => member.declaredFragment?.element,
      _ => null,
    };
    if (element != null && hasAnyWorkerAnnotation(element)) yield member;
  }
}

bool _isPartFile(CompilationUnit unit) =>
    unit.directives.any((d) => d is PartOfDirective);

/// Reports annotated libraries without the `part 'x.gen.dart';` directive.
final class MissingGeneratedPart extends AnalysisRule {
  static const LintCode code = LintCode(
    'missing_generated_part',
    "Add `part '{0}';` so the generated code can be used.",
    correctionMessage: 'Then run `dart run build_runner build`.',
    severity: DiagnosticSeverity.ERROR,
  );

  MissingGeneratedPart()
    : super(
        name: 'missing_generated_part',
        description:
            'Libraries with volley_workers annotations need a part directive '
            'for the generated file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _PartVisitor(this));
  }
}

final class _PartVisitor extends SimpleAstVisitor<void> {
  _PartVisitor(this.rule);
  final MissingGeneratedPart rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (_isPartFile(node)) return;
    final first = annotatedMembers(node).firstOrNull;
    if (first == null) return;
    final fileName = node.declaredFragment?.source.shortName;
    if (fileName == null || !fileName.endsWith('.dart')) return;
    final expected =
        '${fileName.substring(0, fileName.length - '.dart'.length)}.gen.dart';
    final hasPart = node.directives.whereType<PartDirective>().any(
      (d) => d.uri is SimpleStringLiteral &&
          (d.uri as SimpleStringLiteral).value == expected,
    );
    if (hasPart) return;
    final target = first.metadata.isNotEmpty
        ? first.metadata.first
        : first;
    rule.reportAtNode(target, arguments: [expected]);
  }
}

/// Warns about native-only imports in libraries that define workers.
final class WorkerLibraryImportsNative extends AnalysisRule {
  static const LintCode code = LintCode(
    'worker_library_imports_native',
    "'{0}' is not available in a web worker.",
    correctionMessage:
        'Move this code to a library the worker does not import, or use a '
        'conditional import.',
    severity: DiagnosticSeverity.WARNING,
  );

  WorkerLibraryImportsNative()
    : super(
        name: 'worker_library_imports_native',
        description:
            'Libraries with workers are compiled to JavaScript, so they '
            'cannot import native-only dart: libraries.',
      );

  @override
  LintCode get diagnosticCode => code;

  static const _nativeOnly = {
    'dart:io',
    'dart:isolate',
    'dart:ffi',
    'dart:mirrors',
  };

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _NativeVisitor(this));
  }
}

final class _NativeVisitor extends SimpleAstVisitor<void> {
  _NativeVisitor(this.rule);
  final WorkerLibraryImportsNative rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (annotatedMembers(node).isEmpty) return;
    for (final directive in node.directives) {
      if (directive is! ImportDirective) continue;
      final uri = directive.uri;
      if (uri is! SimpleStringLiteral) continue;
      if (WorkerLibraryImportsNative._nativeOnly.contains(uri.value)) {
        rule.reportAtNode(directive, arguments: [uri.value]);
      }
    }
  }
}
