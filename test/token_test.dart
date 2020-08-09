import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepsperhour/main.dart';
import 'package:stepsperhour/token.dart';
import 'package:stepsperhour/utilities.dart';

void main() {
  test("can persist the two tokens", () async {
    SharedPreferences.setMockInitialValues({});

    var expectedAccessToken = 'access_token';
    var expectedRefreshToken = 'refresh_token';
    SharedPreferences pref = await SharedPreferences.getInstance();

    await token().persistTokens(expectedAccessToken, expectedRefreshToken);

    expect(pref.getString('accessToken'), expectedAccessToken);
    expect(pref.getString('refreshToken'), expectedRefreshToken);
  });

  test("can persist settings", () async {
    SharedPreferences.setMockInitialValues({});

    int steps = 42;
    int offset = 1000;
    String date = "some date";
    int increase = 152;
    SharedPreferences pref = await SharedPreferences.getInstance();

    await token().write_settings(steps, offset, date, increase);

    expect(pref.getInt('goalsteps'), steps);
    expect(pref.getInt('offset'), offset);
    expect(pref.getString('date'), date);
    expect(pref.getInt('increase'), increase);
  });

  test("can retrieve goalsteps that is saved", () async {
    final storedGoalSteps = 11234;
    SharedPreferences.setMockInitialValues(
        {'flutter.goalsteps': storedGoalSteps});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final steps = data[0];
    expect(steps, storedGoalSteps);
  });

  test("returns goalStepsDefault for steps if not stored", () async {
    SharedPreferences.setMockInitialValues({});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final steps = data[0];
    expect(steps, goalStepsDefault);
  });

  test("can retrieve offset that is saved", () async {
    final storedOffset = 11;
    SharedPreferences.setMockInitialValues({'flutter.offset': storedOffset});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final offset = data[1];
    expect(offset, storedOffset);
  });

  test("returns zero for offset if not stored", () async {
    SharedPreferences.setMockInitialValues({});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final offset = data[1];
    expect(offset, 0);
  });

  test("can retrieve date that is saved", () async {
    final storedDate = 'Some date';
    SharedPreferences.setMockInitialValues({'flutter.date': storedDate});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final date = data[2];
    expect(date, storedDate);
  });

  test("returns empty string for date if not stored", () async {
    SharedPreferences.setMockInitialValues({});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final date = data[2];
    expect(date, '');
  });

  test("can retrieve date that is saved", () async {
    final storedIncrease = 1234;
    SharedPreferences.setMockInitialValues(
        {'flutter.increase': storedIncrease});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final increase = data[3];
    expect(increase, storedIncrease);
  });

  test(
      "returns calculated start value based on goalsteps for increase if increase not stored",
      () async {
    final goalsteps = 12000;
    final calculatedIncrease = roundDecimal((goalsteps / 14).floor());

    SharedPreferences.setMockInitialValues({'flutter.goalsteps': goalsteps});

    List<dynamic> data = await token().pullGoalStepsFromPreferences();

    final increase = data[3];
    expect(increase, calculatedIncrease);
  });
}
