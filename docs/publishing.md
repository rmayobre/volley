# Publishing to pub.dev

Four packages are published, and each depends on the one before it, so publish
them in this order and wait for each to appear on pub.dev before the next:

1. `volley_api`
2. `volley`
3. `volley_workers`
4. `volley_workers_gen`

For each package:

```
cd packages/<name>
dart pub publish --dry-run   # must report "Package has 0 warnings"
dart pub publish
```

The first upload opens a browser to sign in with a Google account. Versions
cannot be deleted once published, only retracted or discontinued, so check the
dry run before publishing.

To release a new version, bump `version` in the package's `pubspec.yaml`, add a
changelog entry, and raise the sibling constraints (`volley_api: ^x.y.z`) if
the new version needs them. Optionally tag the commit, for example
`git tag volley_api-v0.1.0`.

The repository root and the two packages under `examples/` set
`publish_to: none` and are never published.
