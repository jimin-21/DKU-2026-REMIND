import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> searchBar = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 10,
      offset: Offset(0, -2),
    ),
  ];
}