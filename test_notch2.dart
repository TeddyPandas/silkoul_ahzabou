import 'package:flutter/material.dart';
void main() {
  final shape = AutomaticNotchedShape(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
    CircularNotchedRectangle(),
  );
}
