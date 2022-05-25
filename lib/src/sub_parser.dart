import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:svg_path_parser/src/parser.dart';
import 'package:svg_path_parser/src/tokens.dart';

class SubParser extends Parser {
  SubParser(source, this.start, this.end, this.canvas, this.paint) : super(source);

  Offset start;
  Offset end;
  bool isStarted = false;
  bool isEnded = false;
  Canvas canvas;
  Paint paint;

  @protected
  parseCommand() {
    super.parseCommand();

    final len = lastCommandArgs.length;

    final lastOffset = Offset(lastCommandArgs[len - 1], lastCommandArgs[len - 2]);
    if(lastOffset == start) {
      isStarted = true;
    }

    // If start point didn't find yet then reset the path
    if(!isStarted) {
      path.reset();
    } else {
      if(lastOffset == end) {
        isEnded = true;
      }
    }

    canvas.drawCircle(lastOffset, 1, paint);
  }

  /// Parses the SVG path.
  Path parse() {
    // Scan streamStart Token
    parseStreamStart();

    while (scanner.peek() != TokenType.streamEnd && isEnded != true) {
      parseCommand();
    }

    parseStreamEnd();

    return this.path;
  }
}