library svg_path_parser;

import 'package:svg_path_parser/src/sub_parser.dart';

import 'src/parser.dart';
import 'dart:ui';

export 'src/tokens.dart';
export 'src/scanner.dart';
export 'src/parser.dart';

/// A wrapper to quickly parse a Svg path.
Path parseSvgPath(String source, {bool failSilently = false}) {
  try {
    return Parser(source).parse();
  } catch (e) {
    if (!failSilently) {
      rethrow;
    } else {
      return Path();
    }
  }
}

Path parseSubPath(String source, Offset start, Offset end, Canvas canvas, Paint paint, {bool failSilently = false}) {
  try {
    return SubParser(source, start, end, canvas, paint).parse();
  } catch (e) {
    if (!failSilently) {
      rethrow;
    } else {
      return Path();
    }
  }
}