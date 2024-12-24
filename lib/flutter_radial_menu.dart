import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<T?> showRadialMenu<T extends Object?>(
  BuildContext context, {
  required Set<T?> options,
  required PointerDownEvent event,
  double startRadius = -pi / 2,
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

    final angle = atan2(value.dy, value.dx);

    double modifiedAngle = angle - startRadius;
    if (modifiedAngle < 0) {
      modifiedAngle += pi * 2;
    }

    final index = (modifiedAngle ~/ (pi * 2 / options.length)) % options.length;
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
    return Positioned(
      left: dragInfo.position.dx - 100,
      top: dragInfo.position.dy - 100,
      child: CustomPaint(
        size: const Size(200, 200),
        painter: RaialPainter(
          itemCount: dragInfo.options.length,
          startRadius: dragInfo.startRadius,
          selectedIndex: dragInfo.selectedIndex,
        ),
      ),
    );
  }
}

class RaialPainter extends CustomPainter {
  RaialPainter({
    required this.itemCount,
    required this.startRadius,
    required this.selectedIndex,
  }) : super(repaint: selectedIndex);

  final int itemCount;
  final double startRadius;
  final ValueNotifier<int?> selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < itemCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: min(size.width, size.height) / 2,
        ),
        startRadius + i * (pi * 2 / itemCount),
        pi * 2 / itemCount,
        true,
        Paint()..color = selectedIndex.value == i ? Colors.red : Colors.blue,
      );
    }
  }

  @override
  bool shouldRepaint(RaialPainter oldDelegate) => false;
}
