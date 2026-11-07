#!/bin/sh
# Compiles the web worker scripts into web/, where Flutter serves them next to
# index.html. The names match the generated defaults: <function>.worker.js.
set -e
cd "$(dirname "$0")/.."
dart run build_runner build
dart compile js -O2 -o web/analyze.worker.js web_workers/analyze_worker.dart
dart compile js -O2 -o web/countPrimes.worker.js web_workers/count_primes_worker.dart
