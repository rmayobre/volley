import 'package:flutter/material.dart';
import 'package:volley_workers/volley_workers.dart';

import 'workers.dart';

void main() => runApp(const WorkersApp());

class WorkersApp extends StatelessWidget {
  const WorkersApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'volley_workers',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _limits = [1000000, 5000000, 20000000];

  int _limit = _limits[1];
  bool _busy = false;
  String _result = 'Pick a limit and start a job.';
  Actor<AnalyzeReport, AnalyzeRequest>? _analyzer;

  @override
  void dispose() {
    _analyzer?.dispose();
    super.dispose();
  }

  /// A one-shot job: a coroutine in a worker (web) or isolate (elsewhere).
  Future<void> _countPrimes() => _run(() async {
    final count = await launchCountPrimes(_limit).result;
    return '$count primes below $_limit (coroutine)';
  });

  /// A long-lived worker. It is spawned on first use and reused afterwards;
  /// it also bumps the [RunLog] singleton that lives on this page.
  Future<void> _analyze() => _run(() async {
    final analyzer = _analyzer ??= await spawnAnalyze();
    final reply = analyzer.channel.messages.first;
    analyzer.channel.send(AnalyzeRequest(_limit));
    final report = await reply;
    return '${report.count} primes below ${report.limit}, largest '
        '${report.largest}, found in ${report.milliseconds} ms '
        '(actor, run #${report.runs})';
  });

  Future<void> _run(Future<String> Function() job) async {
    setState(() {
      _busy = true;
      _result = 'Working...';
    });
    String text;
    try {
      text = await job();
    } on Object catch (error) {
      text = 'Failed: $error';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = text;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('volley_workers')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The work runs off the UI thread, so the spinner below keeps '
                'turning. On the web it runs in Web Workers; elsewhere in '
                'isolates. The code is the same.',
              ),
              const SizedBox(height: 24),
              SegmentedButton<int>(
                segments: [
                  for (final limit in _limits)
                    ButtonSegment(value: limit, label: Text('$limit')),
                ],
                selected: {_limit},
                onSelectionChanged:
                    _busy
                        ? null
                        : (value) => setState(() => _limit = value.single),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _countPrimes,
                      child: const Text('Count (coroutine)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _busy ? null : _analyze,
                      child: const Text('Analyze (actor)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
              Text(
                _result,
                key: const Key('result'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
