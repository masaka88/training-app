# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application project named `training_app`. It's a minimal Flutter project initialized with a basic "Hello World" app structure.

## Communication Language

When communicating with users, respond in Japanese.

## Architecture and Structure

- **Framework**: Flutter 3.9.0+ with Dart
- **Main Entry Point**: `lib/main.dart` - Contains the main app with a simple MaterialApp showing "Hello World"
- **Dependencies**: Uses Material Design components (`uses-material-design: true`)
- **Linting**: Uses `flutter_lints` package with standard Flutter linting rules
- **Platforms**: Supports web and macOS (evidenced by `/web` and `/macos` directories)

## Development Commands

**Note**: This project requires Flutter SDK to be installed and available in the PATH.

### Essential Commands

- **Install dependencies**: `flutter pub get`
- **Run the app**: `flutter run`
- **Build for release**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Run tests**: `flutter test` (no tests currently exist)
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`

### Development Workflow

- **Hot reload**: Available when running `flutter run` in debug mode
- **Clean build cache**: `flutter clean` then `flutter pub get`
- **Generate platform-specific code**: `flutter create --platforms android,ios .` (if needed)

## Configuration Files

- `pubspec.yaml`: Project configuration and dependencies
- `analysis_options.yaml`: Includes Flutter linting rules from `package:flutter_lints/flutter.yaml`
- `lib/main.dart`: Single-file app with `MainApp` StatelessWidget

## Development Notes

- No test directory currently exists - tests should be created in `test/` directory
- Project uses standard Flutter project structure
- Material Design is enabled for UI components
- Currently supports web and macOS platforms out of the box
