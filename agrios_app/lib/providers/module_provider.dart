import 'package:flutter/material.dart';

enum AgriModule { indoor, outdoor }

class ModuleProvider extends ChangeNotifier {
  AgriModule _currentModule = AgriModule.outdoor;

  AgriModule get currentModule => _currentModule;

  void setModule(AgriModule module) {
    _currentModule = module;
    notifyListeners();
  }

  String get moduleName => _currentModule == AgriModule.indoor ? 'INDOOR_MODULE' : 'OUTDOOR_MODULE';
}













