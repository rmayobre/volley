import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../semantics.dart';

/// The `@encodable` class a visitor is looking at, with its unnamed
/// constructor and the AST node of each of that constructor's parameters.
final class EncodableClass {
  EncodableClass(this.node, this.element);

  final ClassDeclaration node;
  final ClassElement element;

  ConstructorElement? get constructor => element.unnamedConstructor;

  /// The constructor declaration of [constructor], if written in source.
  ConstructorDeclaration? get constructorNode {
    final target = constructor;
    if (target == null) return null;
    for (final member in node.body.members) {
      if (member is ConstructorDeclaration &&
          member.declaredFragment?.element == target) {
        return member;
      }
    }
    return null;
  }

  /// The node to report [parameter] on: the written parameter, or the class
  /// name when the constructor is implicit.
  SyntacticEntity nodeFor(FormalParameterElement parameter) {
    final params = constructorNode?.parameters.parameters;
    if (params != null) {
      for (final p in params) {
        if (p.declaredFragment?.element == parameter) return p;
      }
    }
    return node.namePart.typeName;
  }
}

/// Visits each `@encodable` class declaration.
abstract base class EncodableVisitor extends SimpleAstVisitor<void> {
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null ||
        !hasWorkerAnnotation(element, WorkerAnnotation.encodable)) {
      return;
    }
    visitEncodable(EncodableClass(node, element));
  }

  void visitEncodable(EncodableClass encodable);
}

void _report(
  AnalysisRule rule,
  SyntacticEntity entity, {
  List<Object> arguments = const [],
}) {
  rule.reportAtOffset(entity.offset, entity.length, arguments: arguments);
}

/// Reports `@encodable` constructor parameters whose type has no wire form.
final class EncodableUnsupportedProperty extends AnalysisRule {
  static const LintCode code = LintCode(
    'encodable_unsupported_property',
    "'{0}' cannot be sent to a worker: {1}",
    correctionMessage:
        'Change the type, annotate it with @encodable, or remove the '
        'parameter.',
    severity: DiagnosticSeverity.ERROR,
  );

  EncodableUnsupportedProperty()
    : super(
        name: 'encodable_unsupported_property',
        description:
            '@encodable classes may only hold types that can cross a worker '
            'boundary.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends EncodableVisitor {
  _Visitor(this.rule);
  final EncodableUnsupportedProperty rule;

  @override
  void visitEncodable(EncodableClass encodable) {
    for (final parameter in encodable.constructor?.formalParameters ?? const []) {
      final reason = unsupportedWorkerType(parameter.type);
      if (reason != null) {
        _report(
          rule,
          encodable.nodeFor(parameter),
          arguments: [parameter.name ?? '', reason],
        );
      }
    }
  }
}

/// Reports `@encodable` classes the generator cannot build codecs for.
final class InvalidEncodableClass extends AnalysisRule {
  static const LintCode code = LintCode(
    'invalid_encodable_class',
    "Invalid @encodable class '{0}': {1}",
    correctionMessage: 'Fix the declaration so the generator can read it.',
    severity: DiagnosticSeverity.ERROR,
  );

  InvalidEncodableClass()
    : super(
        name: 'invalid_encodable_class',
        description:
            '@encodable classes must be concrete, non-generic messages with '
            'an unnamed constructor whose parameters match fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _InvalidVisitor(this));
  }
}

final class _InvalidVisitor extends EncodableVisitor {
  _InvalidVisitor(this.rule);
  final InvalidEncodableClass rule;

  @override
  void visitEncodable(EncodableClass encodable) {
    final element = encodable.element;
    final name = element.name ?? '';
    void report(String problem, [SyntacticEntity? at]) => _report(
      rule,
      at ?? encodable.node.namePart.typeName,
      arguments: [name, problem],
    );

    if (!isMessageClass(element)) return report('it must implement Message.');
    if (element.typeParameters.isNotEmpty) {
      return report('generic classes are not supported.');
    }
    if (element.isAbstract) return report('the class must be concrete.');
    final constructor = encodable.constructor;
    if (constructor == null) {
      return report('it needs an unnamed constructor.');
    }
    for (final parameter in constructor.formalParameters) {
      final field = parameter.name;
      if (field == null) continue;
      final at = encodable.nodeFor(parameter);
      if (field.startsWith('_')) {
        report('parameter `$field` is private; use a public name.', at);
      } else if (element.getField(field) == null &&
          element.getGetter(field) == null) {
        report(
          'parameter `$field` has no field or getter named `$field`, so its '
          'value cannot be read when encoding.',
          at,
        );
      }
    }
  }
}

/// Warns about `Object` / `dynamic` constructor parameters of `@encodable`
/// classes, which the generator cannot check.
final class EncodableUntypedProperty extends AnalysisRule {
  static const LintCode code = LintCode(
    'encodable_untyped_property',
    "'{0}' is untyped, so what it holds can only be checked at runtime.",
    correctionMessage:
        'Use a concrete type; an unsupported value fails with '
        'UnsendableMessageException.',
    severity: DiagnosticSeverity.WARNING,
  );

  EncodableUntypedProperty()
    : super(
        name: 'encodable_untyped_property',
        description:
            'Avoid Object and dynamic in @encodable classes: their contents '
            'are not validated at build time.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _UntypedVisitor(this));
  }
}

final class _UntypedVisitor extends EncodableVisitor {
  _UntypedVisitor(this.rule);
  final EncodableUntypedProperty rule;

  @override
  void visitEncodable(EncodableClass encodable) {
    for (final parameter in encodable.constructor?.formalParameters ?? const []) {
      if (isUntyped(parameter.type)) {
        _report(
          rule,
          encodable.nodeFor(parameter),
          arguments: [parameter.name ?? ''],
        );
      }
    }
  }
}

/// Warns about fields of `@encodable` classes that are not constructor
/// parameters: the generated codecs silently skip them.
final class EncodableIgnoredField extends AnalysisRule {
  static const LintCode code = LintCode(
    'encodable_ignored_field',
    "Field '{0}' is not a constructor parameter, so it is not sent to the "
        'worker.',
    correctionMessage:
        'Add it to the unnamed constructor, or make it static or derived '
        'from the parameters.',
    severity: DiagnosticSeverity.WARNING,
  );

  EncodableIgnoredField()
    : super(
        name: 'encodable_ignored_field',
        description:
            'Fields that are not constructor parameters are lost when an '
            '@encodable message crosses a worker boundary.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _IgnoredVisitor(this));
  }
}

final class _IgnoredVisitor extends EncodableVisitor {
  _IgnoredVisitor(this.rule);
  final EncodableIgnoredField rule;

  @override
  void visitEncodable(EncodableClass encodable) {
    final constructor = encodable.constructor;
    if (constructor == null) return;
    final params = {
      for (final p in constructor.formalParameters)
        if (p.name != null) p.name!,
    };
    final initialized = <String>{
      for (final i
          in encodable.constructorNode?.initializers ??
              const <ConstructorInitializer>[])
        if (i is ConstructorFieldInitializer) i.fieldName.name,
    };
    for (final member in encodable.node.body.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (params.contains(name) ||
            initialized.contains(name) ||
            variable.initializer != null) {
          continue;
        }
        _report(rule, variable.name, arguments: [name]);
      }
    }
  }
}
