import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<T?> showRadialMenu<T extends Object?>(
  BuildContext context, {
  required Set<T?> options,
  required PointerDownEvent event,
  double startRadius = -math.pi / 2,
  RadialMenuThemeData? theme,
  MultiDragGestureRecognizer? recognizer,
}) async {
  recognizer ??= (ImmediateMultiDragGestureRecognizer()
    ..gestureSettings = MediaQuery.gestureSettingsOf(context));

  final resultCompleter = Completer<T?>();

  late OverlayEntry overlayEntry;
  late DragInfo dragInfo;

  Drag dragStart(Offset position) {
    final OverlayState overlay = Overlay.of(context);

    final CapturedThemes capturedThemes =
        InheritedTheme.capture(from: context, to: overlay.context);

    dragInfo = DragInfo<T>(
      options: options,
      completer: resultCompleter,
      capturedThemes: capturedThemes,
      theme: theme,
      position: position,
      startRadius: startRadius,
    );

    overlayEntry = OverlayEntry(builder: dragInfo.createProxy);
    overlay.insert(overlayEntry);

    return dragInfo;
  }

  recognizer
    ..onStart = dragStart
    ..addPointer(event);

  final result = await resultCompleter.future;

  overlayEntry.remove();
  overlayEntry.dispose();
  dragInfo.dispose();

  return result;
}

class DragInfo<T extends Object?> extends Drag {
  DragInfo({
    required this.options,
    required this.completer,
    required this.capturedThemes,
    required this.position,
    required this.startRadius,
    required this.theme,
  });

  final Set<T?> options;
  final RadialMenuThemeData? theme;
  final double startRadius;
  final Offset position;
  final Completer<T?> completer;
  final CapturedThemes capturedThemes;

  late final double centerRadius = () {
    final radius = theme?.radius ?? 100;
    final centerRadiusProportion = theme?.centerRadiusProportion ?? 0.5;
    return radius * centerRadiusProportion;
  }();

  Offset _startAndEndDelta = Offset.zero;
  Offset get startAndEndDelta => _startAndEndDelta;
  set startAndEndDelta(Offset value) {
    _startAndEndDelta = value;

    if (value.distance < centerRadius) {
      selectedIndex.value = null;
      return;
    }

    final angle = math.atan2(value.dy, value.dx);

    double modifiedAngle = angle - startRadius;
    if (modifiedAngle < 0) {
      modifiedAngle += math.pi * 2;
    }

    final index =
        (modifiedAngle ~/ (math.pi * 2 / options.length)) % options.length;
    selectedIndex.value = index;
  }

  ValueNotifier<int?> selectedIndex = ValueNotifier(null);

  @override
  void update(DragUpdateDetails details) {
    startAndEndDelta += details.delta;
  }

  @override
  void end(DragEndDetails details) {
    completer.complete(options.elementAt(selectedIndex.value ?? 0));
  }

  @override
  void cancel() {
    completer.complete(null);
  }

  void dispose() {
    selectedIndex.dispose();
  }

  Widget createProxy(BuildContext context) {
    return capturedThemes.wrap(
      RadialMenu(
        dragInfo: this,
        theme: theme ?? RadialMenuTheme.maybeOf(context),
      ),
    );
  }
}

class RadialMenuTheme extends InheritedTheme {
  const RadialMenuTheme({
    super.key,
    required super.child,
    required this.data,
  });

  final RadialMenuThemeData data;

  static RadialMenuThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RadialMenuTheme>()?.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return RadialMenuTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(RadialMenuTheme oldWidget) => data != oldWidget.data;
}

@immutable
class RadialMenuThemeData with Diagnosticable {
  const RadialMenuThemeData({
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.foregroundColor,
    this.selectedForegroundColor,
    this.itemPadding,
    this.centerPadding,
    this.radius,
    this.centerRadiusProportion,
    this.foregroundAlignment,
  });

  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? foregroundColor;
  final Color? selectedForegroundColor;
  final double? itemPadding;
  final double? centerPadding;
  final double? radius;

  /// 0-1之间的值
  final double? centerRadiusProportion;

  /// 0-1之间的值
  final double? foregroundAlignment;

  RadialMenuThemeData copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    Color? foregroundColor,
    Color? selectedForegroundColor,
    double? itemPadding,
    double? centerPadding,
    double? radius,
    double? centerRadiusProportion,
    double? foregroundAlignment,
  }) {
    return RadialMenuThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      selectedForegroundColor:
          selectedForegroundColor ?? this.selectedForegroundColor,
      itemPadding: itemPadding ?? this.itemPadding,
      centerPadding: centerPadding ?? this.centerPadding,
      radius: radius ?? this.radius,
      centerRadiusProportion:
          centerRadiusProportion ?? this.centerRadiusProportion,
      foregroundAlignment: foregroundAlignment ?? this.foregroundAlignment,
    );
  }
}

class RadialMenu<T extends Object?> extends StatelessWidget {
  const RadialMenu({
    super.key,
    required this.dragInfo,
    required this.theme,
  });

  final DragInfo dragInfo;
  final RadialMenuThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final itemPadding = theme?.itemPadding ?? 4;
    final centerPadding = theme?.centerPadding ?? itemPadding;
    final radius = theme?.radius ?? 100;
    final centerRadius = theme?.centerRadiusProportion ?? 0.5;
    final centerRadiusProportion = theme?.centerRadiusProportion ?? 0.5;
    final foregroundAlignment = theme?.foregroundAlignment ?? 0.84;
    final backgroundColor =
        theme?.backgroundColor ?? Colors.black.withAlpha(144);
    final selectedBackgroundColor =
        theme?.selectedBackgroundColor ?? Colors.black;

    final centerAngleOffset =
        math.pi / 2 - math.acos((itemPadding / 2) / (radius * centerRadius));
    final outerAngleOffset =
        math.pi / 2 - math.acos((itemPadding / 2) / radius);

    return Positioned(
      left: dragInfo.position.dx - radius,
      top: dragInfo.position.dy - radius,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ValueListenableBuilder(
          valueListenable: dragInfo.selectedIndex,
          builder: (context, value, child) {
            return Stack(
              children: [
                Align(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A8CD3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: SizedBox(
                      width:
                          (radius * centerRadiusProportion - centerPadding) * 2,
                      height:
                          (radius * centerRadiusProportion - centerPadding) * 2,
                    ),
                  ),
                ),
                for (var i = 0; i < dragInfo.options.length; i++)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(radius * 2, radius * 2),
                      painter: _PiePainter(
                        startAngle: dragInfo.startRadius +
                            i * (math.pi * 2 / dragInfo.options.length),
                        sweepAngle: math.pi * 2 / dragInfo.options.length,
                        centerAngleOffset: centerAngleOffset,
                        outerAngleOffset: outerAngleOffset,
                        centerRadius: centerRadius,
                        color: value == i
                            ? selectedBackgroundColor
                            : backgroundColor,
                      ),
                      child: Align(
                        alignment: Alignment(
                          math.cos(
                                dragInfo.startRadius +
                                    (i + 0.5) *
                                        (math.pi * 2 / dragInfo.options.length),
                              ) *
                              foregroundAlignment,
                          math.sin(
                                dragInfo.startRadius +
                                    (i + 0.5) *
                                        (math.pi * 2 / dragInfo.options.length),
                              ) *
                              foregroundAlignment,
                        ),
                        child: Text(
                          i.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.centerAngleOffset,
    required this.outerAngleOffset,
    required this.centerRadius,
    required this.color,
  });

  final double centerAngleOffset;
  final double outerAngleOffset;
  final double startAngle;
  final double sweepAngle;

  /// 归一化后的值
  final double centerRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final sectionRadiusRect = Rect.fromCircle(center: center, radius: radius);
    final centerRadiusRect =
        Rect.fromCircle(center: center, radius: radius * centerRadius);

    final innerStartAngle = startAngle + centerAngleOffset;
    final innerEndAngle = startAngle + sweepAngle - centerAngleOffset;

    final startInnerPoint = center +
        Offset(
          math.cos(innerStartAngle) * radius * centerRadius,
          math.sin(innerStartAngle) * radius * centerRadius,
        );

    final startOuterPoint = center +
        Offset(
          math.cos(startAngle + outerAngleOffset) * radius,
          math.sin(startAngle + outerAngleOffset) * radius,
        );

    final endInnerPoint = center +
        Offset(
          math.cos(innerEndAngle) * radius * centerRadius,
          math.sin(innerEndAngle) * radius * centerRadius,
        );

    final path = Path()
      ..moveTo(startInnerPoint.dx, startInnerPoint.dy)
      ..lineTo(startOuterPoint.dx, startOuterPoint.dy)
      ..arcTo(
        sectionRadiusRect,
        startAngle + outerAngleOffset,
        sweepAngle - (outerAngleOffset * 2),
        false,
      )
      ..lineTo(endInnerPoint.dx, endInnerPoint.dy)
      ..arcTo(
        centerRadiusRect,
        innerEndAngle,
        -sweepAngle + (centerAngleOffset * 2),
        false,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) =>
      oldDelegate.startAngle != startAngle ||
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.centerRadius != centerRadius ||
      oldDelegate.color != color;
}
