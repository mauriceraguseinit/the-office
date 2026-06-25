import 'dart:core';

class Units {
  static double degreeOne = 0.0174533;
  static double degree90 = degreeOne * 90;
  static double degree180 = degreeOne * 180;
  static double degree270 = degreeOne * 270;
  static double radFromDegree(double degree) {
    return degree * degreeOne;
  }
}

enum Layers {
  floor(1),

  stuff(2),
  player(3),
  dialogs(4);

  final int value;
  const Layers(this.value);
}
