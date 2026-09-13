import 'package:flutter/foundation.dart';

/// Bottom-navigation state shared by the tabs and pushed routes.
class ShellController extends ChangeNotifier {
  static const home = 0;
  static const explore = 1;
  static const cart = 2;
  static const activity = 3;
  static const profile = 4;

  int _index = home;
  bool _exploreGlobal = false;

  int get index => _index;
  bool get exploreGlobal => _exploreGlobal;

  void go(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void openExplore({required bool global}) {
    _index = explore;
    _exploreGlobal = global;
    notifyListeners();
  }

  void setExploreGlobal(bool value) {
    if (value == _exploreGlobal) return;
    _exploreGlobal = value;
    notifyListeners();
  }

  void reset() {
    _index = home;
    _exploreGlobal = false;
    notifyListeners();
  }
}
