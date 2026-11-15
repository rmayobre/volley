// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Web worker entrypoint for workers.dart. Compile it with:
//   dart compile js -O2 -o workers.worker.js workers.worker.dart

import 'package:volley_workers/volley_workers.dart';

import 'workers.dart';

void main() => runWorkerEntrypoint({
  'analyze': analyzeWorkerMain,
  'countPrimes': countPrimesWorkerMain,
});
