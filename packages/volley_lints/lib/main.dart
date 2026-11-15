/// Analyzer plugin for volley. Enable it in `analysis_options.yaml`:
///
/// ```yaml
/// plugins:
///   volley_lints: ^0.1.0
/// ```
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/closure_rules.dart';
import 'src/rules/encodable_rules.dart';
import 'src/rules/library_rules.dart';
import 'src/rules/worker_rules.dart';

/// The plugin instance the analysis server looks for.
final plugin = VolleyLintsPlugin();

/// Registers every volley rule.
final class VolleyLintsPlugin extends Plugin {
  @override
  String get name => 'volley_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(EncodableUnsupportedProperty())
      ..registerWarningRule(InvalidEncodableClass())
      ..registerWarningRule(EncodableUntypedProperty())
      ..registerWarningRule(EncodableIgnoredField())
      ..registerWarningRule(InvalidActorFunction())
      ..registerWarningRule(InvalidCoroutineFunction())
      ..registerWarningRule(InvalidSingletonClass())
      ..registerWarningRule(WorkerUnsupportedType())
      ..registerWarningRule(MissingGeneratedPart())
      ..registerWarningRule(WorkerLibraryImportsNative())
      ..registerWarningRule(UnsendableClosureCapture());
  }
}
