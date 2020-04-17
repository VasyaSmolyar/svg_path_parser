library svg_path_parser;

import 'package:svg_path_parser/src/parser.dart';
import 'dart:ui';

export 'src/tokens.dart';
export 'src/scanner.dart';
export 'src/parser.dart';

Path parseSvgPath(String source) {
  return Parser(source).parse();
}