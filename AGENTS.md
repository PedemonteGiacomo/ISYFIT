# AGENT Instructions

This repository contains a Flutter application. When modifying Dart code or other project files:

- Format Dart code by running `dart format .` before committing.
- Run static analysis with `flutter analyze`.
- Execute `flutter test` to run the unit/widget tests.
- Include results of these commands in the PR Testing section. If `flutter` or `dart` is not installed, note the failure due to missing dependencies.
- Follow conventional commit style for commit messages (e.g., `feat:`, `fix:`, `docs:`).

## Environment Setup

The `dart` and `flutter` commands are required for formatting, analysis, and
testing. If they are missing, install the Flutter SDK by following the official
instructions at <https://docs.flutter.dev/get-started/install>. After
installation:

1. Ensure that both `flutter` and `dart` are available on your `PATH`.
2. Run `flutter doctor` to verify your environment is configured correctly.
3. Once the tools are installed, re-run `dart format .`, `flutter analyze`, and
   `flutter test` before committing.

