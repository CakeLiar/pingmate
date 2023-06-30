import 'package:flutter/material.dart';

class NavBarController extends ChangeNotifier {
  var navBarShown = true;
  String currentScreen = "";

  void hide () {
    navBarShown = false;
    notifyListeners();
  }

  void show() {
    navBarShown = true;
    notifyListeners();
  }
}