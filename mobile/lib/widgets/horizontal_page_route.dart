import 'package:flutter/material.dart';

PageRouteBuilder<T> horizontalPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1, 0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      ),
      child: child,
    ),
  );
}
