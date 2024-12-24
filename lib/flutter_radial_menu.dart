import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<T?> showRadialMenu<T extends Object?>(
  BuildContext context, {
  required Set<T?> options,
  required PointerDownEvent event,
  double startRadius = -math.pi / 2,
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
  });

  final Set<T?> options;
  final double startRadius;
  final Offset position;
  final Completer<T?> completer;
  final CapturedThemes capturedThemes;

  Offset _startAndEndDelta = Offset.zero;
  Offset get startAndEndDelta => _startAndEndDelta;
  set startAndEndDelta(Offset value) {
    _startAndEndDelta = value;

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
      RadialMenu(dragInfo: this),
    );
  }
}

class RadialMenu<T extends Object?> extends StatelessWidget {
  const RadialMenu({
    super.key,
    required this.dragInfo,
  });

  final DragInfo dragInfo;

  @override
  Widget build(BuildContext context) {
    const double padding = 4;

    const radius = 100;
    const centerRadius = 0.5;
    final centerAngleOffset =
        math.pi / 2 - math.acos((padding / 2) / (radius * centerRadius));
    final outerAngleOffset = math.pi / 2 - math.acos((padding / 2) / radius);

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
                    child: const SizedBox(
                      width: radius - padding * 2,
                      height: radius - padding * 2,
                    ),
                  ),
                ),
                for (var i = 0; i < dragInfo.options.length; i++)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(radius * 2, radius * 2),
                      painter: PiePainter(
                        startAngle: dragInfo.startRadius +
                            i * (math.pi * 2 / dragInfo.options.length),
                        sweepAngle: math.pi * 2 / dragInfo.options.length,
                        centerAngleOffset: centerAngleOffset,
                        outerAngleOffset: outerAngleOffset,
                        centerRadius: centerRadius,
                        color: value == i
                            ? Colors.black
                            : Colors.black.withAlpha(144),
                      ),
                      child: Align(
                        alignment: Alignment(
                          math.cos(
                                dragInfo.startRadius +
                                    (i + 0.5) *
                                        (math.pi * 2 / dragInfo.options.length),
                              ) *
                              0.84,
                          math.sin(
                                dragInfo.startRadius +
                                    (i + 0.5) *
                                        (math.pi * 2 / dragInfo.options.length),
                              ) *
                              0.84,
                        ),
                        child: Text(
                          i.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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

class PiePainter extends CustomPainter {
  PiePainter({
    required this.startAngle,
    required this.sweepAngle,
    this.centerAngleOffset = 0,
    this.outerAngleOffset = 0,
    required this.centerRadius,
    this.color = Colors.red,
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
  bool shouldRepaint(PiePainter oldDelegate) =>
      oldDelegate.startAngle != startAngle ||
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.centerRadius != centerRadius ||
      oldDelegate.color != color;
}

class RadialPainter extends CustomPainter {
  RadialPainter({
    required this.itemCount,
    required this.startRadius,
    required this.selectedIndex,
  }) : super(repaint: selectedIndex);

  final int itemCount;
  final double startRadius;
  final ValueNotifier<int?> selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final sectionRadiusRect = Rect.fromCircle(center: center, radius: 100);
    final centerRadiusRect = Rect.fromCircle(center: center, radius: 50);
    final sweepRadians = math.pi * 2 / itemCount;

    for (var i = 0; i < itemCount; i++) {
      final startRadians = startRadius + i * (math.pi * 2 / itemCount);

      final endRadians = startRadians + sweepRadians;
      final startLineDirection =
          Offset(math.cos(startRadians), math.sin(startRadians));

      final startLineFrom = center + startLineDirection * 0.5;
      final startLineTo = startLineFrom + startLineDirection * 0.5;

      final endLineDirection =
          Offset(math.cos(endRadians), math.sin(endRadians));

      final endLineFrom = center + endLineDirection * 0.5;

      final path = Path()
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..lineTo(startLineTo.dx, startLineTo.dy)
        ..arcTo(sectionRadiusRect, startRadians, sweepRadians, false)
        ..lineTo(endLineFrom.dx, endLineFrom.dy)
        ..arcTo(centerRadiusRect, endRadians, -sweepRadians, false)
        ..moveTo(startLineFrom.dx, startLineFrom.dy)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = selectedIndex.value == i ? Colors.red : Colors.blue,
      );
    }
  }

  @override
  bool shouldRepaint(RadialPainter oldDelegate) => false;
}
