// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

// class RadialMenu extends MultiChildRenderObjectWidget {
//   const RadialMenu({super.key, super.children, this.childAlignment = 0.6});

//   final double childAlignment;

//   @override
//   RenderObject createRenderObject(BuildContext context) {
//     return RenderRadialMenu();
//   }
// }

// class RenderRadialMenu extends RenderBox
//     with ContainerRenderObjectMixin<RenderBox, RadialMenuParentData> {
//   RenderRadialMenu({
//     List<RenderBox>? children,
//   }) {
//     addAll(children);
//   }

//   @override
//   void setupParentData(RenderBox child) {
//     if (child.parentData is! RadialMenuParentData) {
//       StackParentData
//       child.parentData = RadialMenuParentData();
//     }
//   }
// }

// class RadialMenuParentData extends ContainerBoxParentData<RenderBox> {
//   RadialMenuParentData({super.offset});
// }
