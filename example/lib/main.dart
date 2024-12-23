import 'package:flutter/material.dart';
import 'package:flutter_radial_menu/flutter_radial_menu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHome(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        return Listener(
          onPointerDown: (event) {
            showRadialMenu(context, event: event);
          },
          child: ColoredBox(
            color: Colors.transparent,
            child: SizedBox.expand(),
          ),
        );
      }),
    );
  }
}
