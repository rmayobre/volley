import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when the closure given to `actor()` / `coroutine()` captures a
/// variable whose value cannot cross an isolate boundary.
final class UnsendableClosureCapture extends AnalysisRule {
  static const LintCode code = LintCode(
    'unsendable_closure_capture',
    "The closure captures '{0}' ({1}), which cannot be sent to an isolate.",
    correctionMessage:
        'Pass a top-level or static function, or capture only sendable '
        'values.',
    severity: DiagnosticSeverity.WARNING,
  );

  UnsendableClosureCapture()
    : super(
        name: 'unsendable_closure_capture',
        description:
            'Closures passed to actor() and coroutine() run in another '
            'isolate, so what they capture must be sendable.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _CallVisitor(this));
  }
}

/// Type names whose instances hold native resources, ports or callbacks.
const _unsendableTypes = {
  'Stream',
  'StreamController',
  'StreamSubscription',
  'StreamSink',
  'Sink',
  'Future',
  'Completer',
  'Timer',
  'Zone',
  'Socket',
  'ServerSocket',
  'RawSocket',
  'Process',
  'HttpClient',
  'HttpServer',
  'ReceivePort',
  'RawReceivePort',
  'Actor',
  'Coroutine',
  'Channel',
  'IngressChannel',
  'EgressChannel',
  'Disposable',
  'Pool',
  'MessageBus',
};

String? _whyUnsendable(DartType type) {
  if (type is FunctionType) return 'a function';
  if (type is InterfaceType) {
    final name = type.element.name;
    if (_unsendableTypes.contains(name)) return name!;
    for (final supertype in type.allSupertypes) {
      final superName = supertype.element.name;
      if (_unsendableTypes.contains(superName)) return type.element.name ?? '';
    }
  }
  return null;
}

final class _CallVisitor extends SimpleAstVisitor<void> {
  _CallVisitor(this.rule);
  final UnsendableClosureCapture rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.methodName.element;
    if (target is! TopLevelFunctionElement ||
        (target.name != 'actor' && target.name != 'coroutine')) {
      return;
    }
    final uri = target.library.uri;
    if (uri.scheme != 'package' || uri.pathSegments.first != 'volley') return;
    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) return;
    final callback = arguments.first;
    if (callback is! FunctionExpression) return;
    final collector = _Declared();
    callback.accept(collector);
    callback.accept(_Captures(rule, collector.declared));
  }
}

/// Collects the variables and parameters declared inside a closure.
final class _Declared extends RecursiveAstVisitor<void> {
  final declared = <Element>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element != null) declared.add(element);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (final parameter in node.parameters) {
      final element = parameter.declaredFragment?.element;
      if (element != null) declared.add(element);
    }
    super.visitFormalParameterList(node);
  }
}

final class _Captures extends RecursiveAstVisitor<void> {
  _Captures(this.rule, this.declared);
  final UnsendableClosureCapture rule;
  final Set<Element> declared;
  final _reported = <Element>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is! LocalVariableElement && element is! FormalParameterElement) {
      return;
    }
    if (declared.contains(element) || !_reported.add(element!)) return;
    final type = element is VariableElement ? element.type : null;
    final why = type == null ? null : _whyUnsendable(type);
    if (why != null) rule.reportAtNode(node, arguments: [node.name, why]);
  }
}
