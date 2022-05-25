import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:svg_path_parser/src/scanner.dart';
import 'package:svg_path_parser/src/tokens.dart';

/// A Parser that converts a SVG path to a [Path] object.
class Parser {
  /// Creates a new [Parser] object.
  ///
  /// [source] should not be null.
  Parser(source)
      : scanner = Scanner(source),
        path = Path(),
        initialPoint = Offset.zero,
        currentPoint = Offset.zero,
        lastCommandArgs = [];

  /// Last command Parsed
  @protected
  late CommandToken lastCommand;

  /// List of Arguments of Previous Command
  List<dynamic> lastCommandArgs;

  /// The initial [Offset] where the [Path] object started from.
  @protected
  Offset initialPoint;

  /// The current [Offset] where the [Path] is currently at.
  @protected
  Offset currentPoint;

  /// The path object to be returned.
  Path path;

  /// The underlying [Scanner] which reads input source and emits [Token]s.
  @protected
  final Scanner scanner;

  /// Parses the SVG path.
  Path parse() {
    // Scan streamStart Token
    parseStreamStart();

    while (scanner.peek()!.type != TokenType.streamEnd) {
      parseCommand();
    }

    parseStreamEnd();

    return this.path;
  }

  /// Parses the stream start token.
  @protected
  parseStreamStart() {
    scanner.scan();
  }

  /// Parses the stream end token.
  @protected
  parseStreamEnd() {
    scanner.scan();
  }

  /// Parses a SVG path Command.
  @protected
  parseCommand() {
    Token token = scanner.peek()!;
    // If extra arguments are encountered. Use the last command.
    if (!(token is CommandToken)) {
      // Subsequent pairs after first Move to are considered as implicit
      // Line to commands. https://www.w3.org/TR/SVG/paths.html#PathDataMovetoCommands
      if (lastCommand.type == TokenType.moveTo) {
        token = CommandToken(TokenType.lineTo, lastCommand.coordinateType);
      } else {
        token = lastCommand;
      }
    } else {
      token = scanner.scan()!;
    }

    switch (token.type) {
      case TokenType.moveTo:
        _parseMoveTo(token as CommandToken);
        return;
      case TokenType.closePath:
        _parseClosePath(token as CommandToken);
        return;
      case TokenType.lineTo:
        _parseLineTo(token as CommandToken);
        return;
      case TokenType.horizontalLineTo:
        _parseHorizontalLineTo(token as CommandToken);
        return;
      case TokenType.verticalLineTo:
        _parseVerticalLineTo(token as CommandToken);
        return;
      case TokenType.curveTo:
        _parseCurveTo(token as CommandToken);
        return;
      case TokenType.smoothCurveTo:
        _parseSmoothCurveTo(token as CommandToken);
        return;
      case TokenType.quadraticBezierCurveTo:
        _parseQuadraticBezierCurveTo(token as CommandToken);
        return;
      case TokenType.smoothQuadraticBezierCurveTo:
        _parseSmoothQuadraticBezierCurveTo(token as CommandToken);
        return;
      case TokenType.ellipticalArcTo:
        _parseEllipticalArcTo(token as CommandToken);
        return;
      default:
        return;
    }
  }

  /// Parses a [CommandToken] of type [TokenType.moveTo] and it's Argument [ValueToken]s.
  ///
  /// move-to-args: x, y            (absolute)
  /// move-to-args: dx, dy          (relative)
  _parseMoveTo(CommandToken commandToken) {
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.moveTo(x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeMoveTo(x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }
    // moveTo command reset the initial and current point
    initialPoint = currentPoint;

    lastCommand = commandToken;
    lastCommandArgs = [x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.closePath].
  _parseClosePath(CommandToken commandToken) {
    this.path.close();
    // closePath resets the current point to initial point.
    currentPoint = initialPoint;

    lastCommand = commandToken;
    lastCommandArgs.clear();
  }

  /// Parses a [CommandToken] of type [TokenType.lineTo] and it's Argument [ValueToken]s.
  ///
  /// line-to-args: x, y            (absolute)
  /// line-to-args: dx, dy          (relative)
  _parseLineTo(CommandToken commandToken) {
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeLineTo(x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.horizontalLineTo] and it's Argument [ValueToken]s.
  ///
  /// horizontal-line-to-args: x     (absolute)
  /// horizontal-line-to-args: dx    (relative)
  _parseHorizontalLineTo(CommandToken commandToken) {
    var h = (scanner.scan()! as ValueToken).value;
    var y = currentPoint.dy;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(h as double, y);
      currentPoint = Offset(h, y);
    } else {
      this.path.relativeLineTo(h as double, 0);
      currentPoint = currentPoint.translate(h, 0);
    }

    lastCommand = commandToken;
    lastCommandArgs = [h];
  }

  /// Parses a [CommandToken] of type [TokenType.verticalLineTo] and it's Argument [ValueToken]s.
  ///
  /// vertical-line-to-args: y        (absolute)
  /// vertical-line-to-args: dy       (relative)
  _parseVerticalLineTo(CommandToken commandToken) {
    var v = (scanner.scan()! as ValueToken).value;
    var x = currentPoint.dx;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x, v as double);
      currentPoint = Offset(x, v);
    } else {
      this.path.relativeLineTo(0, v as double);
      currentPoint = currentPoint.translate(0, v);
    }

    lastCommand = commandToken;
    lastCommandArgs = [v];
  }

  /// Parses a [CommandToken] of type [TokenType.curveTo] and it's Argument [ValueToken]s.
  ///
  /// curve-to-args: x1,y1 x2,y2 x,y        (absolute)
  /// curve-to-args: dx1,dy1 dx2,dy2 dx,dy  (relative)
  _parseCurveTo(CommandToken commandToken) {
    var x1 = (scanner.scan()! as ValueToken).value;
    var y1 = (scanner.scan()! as ValueToken).value;
    var x2 = (scanner.scan()! as ValueToken).value;
    var y2 = (scanner.scan()! as ValueToken).value;
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.cubicTo(x1 as double, y1 as double, x2 as double, y2 as double,
          x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeCubicTo(x1 as double, y1 as double, x2 as double,
          y2 as double, x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [x1, y1, x2, y2, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.smoothCurveTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-curve-to-args: x1,y1 x,y        (absolute)
  /// smooth-curve-to-args: dx1,dy1 dx,dy    (relative)
  _parseSmoothCurveTo(CommandToken commandToken) {
    var x2 = (scanner.scan()! as ValueToken).value;
    var y2 = (scanner.scan()! as ValueToken).value;
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;
    // Calculate the first control point
    var cp = _calculateCubicControlPoint();

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.cubicTo(
          cp.dx, cp.dy, x2 as double, y2 as double, x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.cubicTo(cp.dx - currentPoint.dx, cp.dy - currentPoint.dy,
          x2 as double, y2 as double, x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [x2, y2, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.quadraticBezierCurveTo] and it's Argument [ValueToken]s.
  /// Parses a [CommandToken] of type [TokenType.smoothCurveTo] and it's Argument [ValueToken]s.
  ///
  /// quadratic-curve-to-args: x1,y1 x,y        (absolute)
  /// quadratic-curve-to-args: dx1,dy1 dx,dy    (relative)
  _parseQuadraticBezierCurveTo(CommandToken commandToken) {
    var x1 = (scanner.scan()! as ValueToken).value;
    var y1 = (scanner.scan()! as ValueToken).value;
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(
          x1 as double, y1 as double, x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(
          x1 as double, y1 as double, x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [x1, y1, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.smoothQuadraticBezierCurveTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-quadratic-curve-to-args: x,y         (absolute)
  /// smooth-quadratic-curve-to-args: dx,dy       (relative)
  _parseSmoothQuadraticBezierCurveTo(CommandToken commandToken) {
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;
    // Calculate the control point
    var cp = _calculateQuadraticControlPoint();

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(cp.dx, cp.dy, x as double, y as double);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(cp.dx - currentPoint.dx,
          cp.dy - currentPoint.dy, x as double, y as double);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [cp.dx, cp.dy, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.ellipticalArcTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-curve-to-args: rx ry x-axis-rotation large-arc-flag sweep-flag x y     (absolute)
  /// smooth-curve-to-args: rx ry x-axis-rotation large-arc-flag sweep-flag dx dy   (relative)
  _parseEllipticalArcTo(CommandToken commandToken) {
    var rx = (scanner.scan()! as ValueToken).value;
    var ry = (scanner.scan()! as ValueToken).value;
    var theta = (scanner.scan()! as ValueToken).value;
    var fa = (scanner.scan()! as ValueToken).value == 1;
    var fb = (scanner.scan()! as ValueToken).value == 1;
    var x = (scanner.scan()! as ValueToken).value;
    var y = (scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.arcToPoint(Offset(x as double, y as double),
          radius: Radius.elliptical(rx as double, ry as double),
          rotation: theta as double,
          largeArc: fa,
          clockwise: fb);
      currentPoint = Offset(x, y);
    } else {
      this.path.relativeArcToPoint(Offset(x as double, y as double),
          radius: Radius.elliptical(rx as double, ry as double),
          rotation: theta as double,
          largeArc: fa,
          clockwise: fb);
      currentPoint = currentPoint.translate(x, y);
    }

    lastCommand = commandToken;
    lastCommandArgs = [rx, ry, theta, fa, fb, x, y];
  }

  /// Predicts the Control Point [Offset] for a smooth cubic curve command.
  Offset _calculateCubicControlPoint() {
    if (lastCommand.type == TokenType.curveTo) {
      if (lastCommand.coordinateType == CoordinateType.absolute) {
        return currentPoint +
            (currentPoint - Offset(lastCommandArgs[2], lastCommandArgs[3]));
      } else {
        return currentPoint - Offset(lastCommandArgs[2], lastCommandArgs[3]);
      }
    } else if (lastCommand.type == TokenType.smoothCurveTo) {
      if (lastCommand.coordinateType == CoordinateType.absolute) {
        return currentPoint +
            (currentPoint - Offset(lastCommandArgs[0], lastCommandArgs[1]));
      } else {
        return currentPoint - Offset(lastCommandArgs[0], lastCommandArgs[1]);
      }
    } else {
      return currentPoint;
    }
  }

  /// Predicts the Control Point [Offset] for a smooth quadratic bezier curve command.
  Offset _calculateQuadraticControlPoint() {
    if (lastCommand.type == TokenType.quadraticBezierCurveTo) {
      if (lastCommand.coordinateType == CoordinateType.absolute) {
        return currentPoint +
            (currentPoint - Offset(lastCommandArgs[0], lastCommandArgs[1]));
      } else {
        return currentPoint - Offset(lastCommandArgs[1], lastCommandArgs[0]);
      }
    } else if (lastCommand.type == TokenType.smoothQuadraticBezierCurveTo) {
      if (lastCommand.coordinateType == CoordinateType.absolute) {
        return currentPoint +
            (currentPoint - Offset(lastCommandArgs[0], lastCommandArgs[1]));
      } else {
        return currentPoint - Offset(lastCommandArgs[0], lastCommandArgs[1]);
      }
    } else {
      return currentPoint;
    }
  }
}
