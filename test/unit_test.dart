import 'package:flutter_test/flutter_test.dart';
import 'package:stepsperhour/main.dart';

void main() {
  group("roundDecimal rounds correctly", () {
    var inputsToExpected = {
      0: 0,
      1: 5,
      2: 5,
      3: 5,
      4: 5,
      5: 5,
      6: 10,
      7: 10,
      8: 10,
      9: 10,
      10: 10,
      11: 15,
      12: 15,
      13: 15,
      14: 15,
      15: 15,
      16: 20,
      17: 20,
      18: 20,
      19: 20,
      20: 20,
      193: 195,
      1234: 1235,
      9999: 10000,
      9998: 10000,
      9994: 9995
    };

    inputsToExpected.forEach((input, expected) {
      test("$input -> $expected", () {
        expect(roundDecimal(input), expected);
      });
    });
  });
}
