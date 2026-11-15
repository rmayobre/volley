#!/bin/sh
# Compiles the generated web worker entrypoint into web/, where Flutter serves
# it next to index.html. The name matches the generated default `workerScript`:
# <source file>.worker.js.
set -e
cd "$(dirname "$0")/.."
dart run build_runner build
dart compile js -O2 -o web/workers.worker.js lib/workers.worker.dart
