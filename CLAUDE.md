# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Google Photos Takeout Helper (`gpth`) — a pure Dart CLI tool that organizes chaotic Google Takeout photo exports into a single chronological folder with correct file modification dates. Originally Python (v2.x), rewritten in Dart (v3.0+).

## Common Commands

```bash
dart pub get              # Install dependencies
dart test                 # Run all tests
dart test test/gpth_test.dart --name "test name"  # Run a single test
dart format --output=none --set-exit-if-changed .  # Check formatting
dart analyze --fatal-infos  # Static analysis (strict)
dart run bin/gpth.dart    # Run the app locally
```

CI runs: `dart test` → format check → `dart analyze --fatal-infos` (see `.github/workflows/dart-test.yaml`).

## Architecture

**Entry point**: `bin/gpth.dart` — parses CLI args, orchestrates the pipeline.

**Processing pipeline** (sequential, in-place mutation of a global `List<Media>`):
1. **Folder classification** (`folder_classify.dart`) — identifies year folders vs album folders
2. **Media collection** — creates `Media` objects from discovered files
3. **Extras removal** (`extras.dart`) — filters out edited variants (-edited, -modifié, etc.)
4. **Deduplication** (`grouping.dart`) — groups by file size, then SHA256 hash (max 64MB)
5. **Date extraction** (`date_extractor.dart`) — tries extractors in priority order:
   - JSON metadata (`json_extractor.dart`) — reads Google's sidecar `.json` files
   - EXIF (`exif_extractor.dart`)
   - Filename guessing (`guess_extractor.dart`)
   - JSON "tryhard" — aggressive fuzzy matching for mismatched JSON filenames
6. **Album merging** (`grouping.dart`) — deduplicates across album folders
7. **File moving** (`moving.dart`) — moves/copies to output, creates album shortcuts

**Key type**: `Media` class (`media.dart`) — mutable object holding file reference, cached hash, extracted date, album associations, and `dateTakenAccuracy` score.

**Album modes** (4 strategies in `moving.dart`): shortcut (symlinks), duplicate-copy, json metadata file, nothing.

## Notable Edge Cases in the Codebase

- Google truncates JSON sidecar filenames at 51 chars and swaps brackets (e.g., `image(1).jpg` → `image.jpg(1).json`)
- MacOS NFD unicode normalization handled via `unorm_dart`
- Files uploaded without extensions get special handling
- Windows: timestamps before 1970 fail; PowerShell shortcut creation can fail (falls back to copy)

## Test Structure

Single test file `test/gpth_test.dart` creates temporary files (1x1 JPEG with EXIF) and tests deduplication, extras removal, album merging, date extraction, and file moving.
