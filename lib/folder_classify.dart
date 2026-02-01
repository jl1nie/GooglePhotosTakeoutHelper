/// This file contains utils for determining type of a folder
/// Whether it's a legendary "year folder", album, trash, etc
import 'dart:io';

import 'package:gpth/utils.dart';
import 'package:path/path.dart' as p;

/// Known localized prefixes for Google Takeout year folders.
/// Format: "<prefix> YYYY" (prefix includes trailing space)
const _yearFolderPrefixes = [
  // Confirmed by user reports:
  'Photos from ', // EN
  'Fotos von ', // DE (confirmed: issue #461)
  'Fotos aus ', // DE (alternate)
  'Photos de ', // FR (confirmed: issue #461)
  // Inferred from Google's localization patterns:
  'Fotos de ', // ES, PT, CA
  "Foto's uit ", // NL
  'Foto dal ', // IT
  'Foto del ', // IT (alternate)
  'Zdjęcia z ', // PL
  'Фото за ', // RU
  'Фотографии за ', // RU (alternate)
  'Fotky z ', // CS
  'Fotografii din ', // RO
  'Foton från ', // SV
  'Bilder fra ', // NO
  'Billeder fra ', // DA
  'Valokuvat ', // FI ("Valokuvat YYYY" - no preposition)
  'Fényképek - ', // HU
  'Fotoğraflar ', // TR
];

/// Known localized suffixes for year-first languages.
/// Format: "YYYY<suffix>"
const _yearFolderSuffixes = [
  ' 年の写真', // JA (confirmed: "2026 年の写真")
  '年のフォト', // JA (alternate)
  '년의 사진', // KO
  '年的照片', // ZH-CN
  '年的相片', // ZH-TW
];

final _yearRe = RegExp(r'(20|19|18)\d{2}');

bool isYearFolder(Directory dir) {
  final name = p.basename(dir.path);

  // Check "<prefix>YYYY" patterns (most languages)
  for (final prefix in _yearFolderPrefixes) {
    if (name.startsWith(prefix)) {
      final rest = name.substring(prefix.length);
      if (RegExp(r'^(20|19|18)\d{2}$').hasMatch(rest)) return true;
    }
  }

  // Check "YYYY<suffix>" patterns (JA, KO, ZH)
  for (final suffix in _yearFolderSuffixes) {
    if (name.endsWith(suffix)) {
      final rest = name.substring(0, name.length - suffix.length);
      if (RegExp(r'^(20|19|18)\d{2}$').hasMatch(rest)) return true;
    }
  }

  return false;
}

Future<bool> isAlbumFolder(Directory dir) =>
    dir.parent.list().whereType<Directory>().any((e) => isYearFolder(e));
