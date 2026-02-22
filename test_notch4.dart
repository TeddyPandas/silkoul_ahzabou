import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 20,
          shadowColor: Colors.black54,
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            CircleBorder(),
          ),
          notchMargin: 8,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(height: 70),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){}),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
  ));
}
