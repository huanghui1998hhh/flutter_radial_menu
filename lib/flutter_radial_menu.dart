import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<T?> showRadialMenu<T extends Object?>(
  BuildContext context, {
  required PointerDownEvent event,
  MultiDragGestureRecognizer? recognizer,
}) async {
  recognizer ??= (ImmediateMultiDragGestureRecognizer()
    ..gestureSettings = MediaQuery.gestureSettingsOf(context));

  final resultCompleter = Completer<T?>();

  late OverlayEntry overlayEntry;

  Drag dragStart(Offset position) {
    final OverlayState overlay = Overlay.of(context);

    final CapturedThemes capturedThemes =
        InheritedTheme.capture(from: context, to: overlay.context);

    final dragInfo = _DragInfo<T>(
      completer: resultCompleter,
      capturedThemes: capturedThemes,
      position: position,
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

  return result;
}

class _DragInfo<T extends Object?> extends Drag {
  _DragInfo({
    required this.completer,
    required this.capturedThemes,
    required this.position,
  });

  final Offset position;
  final Completer<T?> completer;
  final CapturedThemes capturedThemes;

  @override
  void update(DragUpdateDetails details) {
    print(details);
  }

  @override
  void end(DragEndDetails details) {
    completer.complete(null);
  }

  @override
  void cancel() {
    completer.complete(null);
  }

  Widget createProxy(BuildContext context) {
    return capturedThemes.wrap(
      RadialMenu(
        position: position,
        completer: completer,
      ),
    );
  }
}

class RadialMenu<T extends Object?> extends StatelessWidget {
  const RadialMenu({
    super.key,
    required this.position,
    this.completer,
  });

  final Offset position;
  final Completer<T?>? completer;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 36,
      top: position.dy - 36,
      child: const SizedBox(
        width: 72,
        height: 72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(36)),
            color: Colors.red,
          ),
          child: Align(
            child: Text(
              'X',
              style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
