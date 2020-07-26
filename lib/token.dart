import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepsperhour/utilities.dart';

import 'main.dart';

void persistTokens(accessToken, refreshToken) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('accessToken', accessToken);
  prefs.setString('refreshToken', refreshToken);
}

write_settings(int steps, int offset, String date, int increase) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('goalsteps', steps);
  prefs.setInt('offset', offset);
  prefs.setString('date', date);
  prefs.setInt('increase', increase);
}

Future<dynamic> pullGoalStepsFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int steps = (prefs.getInt('goalsteps') ?? goalStepsDefault);
  int offset = (prefs.getInt('offset') ?? 0);
  String date = (prefs.getString('date') ?? '');
  int increase =
      (prefs.getInt('increase') ?? roundDecimal((goalSteps / 14).floor()));
  return [steps, offset, date, increase];
}
