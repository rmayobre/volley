import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../semantics.dart';

/// Members of [declaration]'s body (empty for an empty `;` body).
List<ClassMember> membersOf(ClassDeclaration declaration) {
  final body = declaration.body;
  return body is BlockClassBody ? body.members : const [];
}

/// Reports `@actor` functions whose shape the generator rejects.
final class InvalidActorFunction extends AnalysisRule {
  static const LintCode code = LintCode(
    'invalid_actor_function',
    "Invalid @actor function '{0}': {1}",
    correctionMessage:
        'An @actor is a non-generic top-level function taking one Message '
        'and returning a Message (optionally in a Future).',
    severity: DiagnosticSeverity.ERROR,
  );

  InvalidActorFunction()
    : super(
        name: 'invalid_actor_function',
        description:
            '@actor functions are top-level and map one Message to a '
            'Message.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _FunctionVisitor(
      WorkerAnnotation.actor,
      (node, problem) => reportAtToken(node, arguments: [problem.$1, problem.$2]),
    );
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

/// Reports `@coroutine` functions whose shape the generator rejects.
final class InvalidCoroutineFunction extends AnalysisRule {
  static const LintCode code = LintCode(
    'invalid_coroutine_function',
    "Invalid @coroutine function '{0}': {1}",
    correctionMessage:
        'A @coroutine is a non-generic top-level function with required '
        'positional parameters only.',
    severity: DiagnosticSeverity.ERROR,
  );

  InvalidCoroutineFunction()
    : super(
        name: 'invalid_coroutine_function',
        description:
            '@coroutine functions are top-level with required positional '
            'parameters only.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _FunctionVisitor(
      WorkerAnnotation.coroutine,
      (node, problem) => reportAtToken(node, arguments: [problem.$1, problem.$2]),
    );
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

typedef _Report = void Function(Token name, (String, String) problem);

/// Checks the declaration shape of `@actor` / `@coroutine` functions.
final class _FunctionVisitor extends SimpleAstVisitor<void> {
  _FunctionVisitor(this.annotation, this.report);

  final WorkerAnnotation annotation;
  final _Report report;

  String get _label => annotation == WorkerAnnotation.actor ? '@actor' : '@coroutine';

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !hasWorkerAnnotation(element, annotation)) return;
    report(node.name, (
      node.name.lexeme,
      '$_label can only annotate top-level functions.',
    ));
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !hasWorkerAnnotation(element, annotation)) return;
    final name = node.name.lexeme;
    void fail(String problem) => report(node.name, (name, problem));

    if (element is! TopLevelFunctionElement) {
      return fail('$_label can only annotate top-level functions.');
    }
    if (element.typeParameters.isNotEmpty) {
      return fail('$_label functions cannot be generic.');
    }
    final parameters = element.formalParameters;
    if (annotation == WorkerAnnotation.actor) {
      if (parameters.length != 1 || !parameters.single.isRequiredPositional) {
        return fail('it must take exactly one required positional Message.');
      }
      final input = parameters.single.type;
      final output = unwrapFuture(element.returnType);
      for (final type in [input, output]) {
        if (!isMessageType(type)) {
          return fail(
            'it must take a Message and return a Message (optionally in a '
            'Future); found `${type.getDisplayString()}`.',
          );
        }
      }
    } else if (parameters.any((p) => !p.isRequiredPositional)) {
      fail('only required positional parameters are supported.');
    }
  }
}

/// Reports `@singleton` classes the generator rejects.
final class InvalidSingletonClass extends AnalysisRule {
  static const LintCode code = LintCode(
    'invalid_singleton_class',
    "Invalid @singleton class '{0}': {1}",
    correctionMessage:
        'A @singleton is a concrete, non-generic SerializedSingleton or '
        'ConcurrentSingleton with a no-argument constructor.',
    severity: DiagnosticSeverity.ERROR,
  );

  InvalidSingletonClass()
    : super(
        name: 'invalid_singleton_class',
        description:
            '@singleton classes extend a volley Singleton and can be built '
            'without arguments.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _SingletonVisitor(this));
  }
}

final class _SingletonVisitor extends SimpleAstVisitor<void> {
  _SingletonVisitor(this.rule);
  final InvalidSingletonClass rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null ||
        !hasWorkerAnnotation(element, WorkerAnnotation.singleton)) {
      return;
    }
    final name = element.name ?? '';
    void fail(String problem) => rule.reportAtToken(
      node.namePart.typeName,
      arguments: [name, problem],
    );
    if (element.isAbstract || element.typeParameters.isNotEmpty) {
      return fail('it must be a concrete, non-generic class.');
    }
    final constructor = element.unnamedConstructor;
    if (constructor == null ||
        constructor.formalParameters.any((p) => p.isRequired)) {
      return fail(
        'it needs an unnamed constructor without required parameters, '
        'because the instance is built without arguments.',
      );
    }
    if (singletonSupertype(element) == null) {
      fail('it must extend SerializedSingleton or ConcurrentSingleton.');
    }
  }
}

/// Reports types in worker signatures that have no wire form.
final class WorkerUnsupportedType extends AnalysisRule {
  static const LintCode code = LintCode(
    'worker_unsupported_type',
    "'{0}' uses a type that cannot be sent to a worker: {1}",
    correctionMessage:
        'Use a supported type, or make the message class @encodable.',
    severity: DiagnosticSeverity.ERROR,
  );

  WorkerUnsupportedType()
    : super(
        name: 'worker_unsupported_type',
        description:
            'Parameters, results and singleton messages of workers must be '
            'sendable to a web worker.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _UnsupportedTypeVisitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addClassDeclaration(this, visitor);
  }
}

final class _UnsupportedTypeVisitor extends SimpleAstVisitor<void> {
  _UnsupportedTypeVisitor(this.rule);
  final WorkerUnsupportedType rule;

  void _check(SyntacticEntity at, String owner, DartType type) {
    final reason = unsupportedWorkerType(type);
    if (reason != null) {
      rule.reportAtOffset(
        at.offset,
        at.length,
        arguments: [owner, reason],
      );
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element is! TopLevelFunctionElement) return;
    final isActor = hasWorkerAnnotation(element, WorkerAnnotation.actor);
    final isCoroutine = hasWorkerAnnotation(element, WorkerAnnotation.coroutine);
    if (!isActor && !isCoroutine) return;
    // Generic functions are reported by invalid_*_function.
    if (element.typeParameters.isNotEmpty) return;
    // An actor's wrong shape is reported by invalid_actor_function.
    if (isActor && element.formalParameters.length != 1) return;
    final name = node.name.lexeme;
    for (final parameter
        in node.functionExpression.parameters?.parameters ??
            const <FormalParameter>[]) {
      final declared = parameter.declaredFragment?.element;
      if (declared != null && declared.isRequiredPositional) {
        _check(parameter, name, declared.type);
      }
    }
    _check(
      node.returnType ?? node.name,
      name,
      unwrapFuture(element.returnType),
    );
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null ||
        !hasWorkerAnnotation(element, WorkerAnnotation.singleton)) {
      return;
    }
    final base = singletonSupertype(element);
    if (base == null || base.typeArguments.length < 2) return;
    final written = node.extendsClause?.superclass.typeArguments?.arguments;
    final types = base.typeArguments.take(2).toList();
    for (var i = 0; i < types.length; i++) {
      final at = written != null && written.length == 2
          ? written[i]
          : node.namePart.typeName;
      _check(at, element.name ?? '', types[i]);
    }
  }
}
