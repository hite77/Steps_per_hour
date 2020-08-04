import 'package:flutter_test/flutter_test.dart';
import 'package:stepsperhour/fitbit_api.dart';

void main() {
  test("Add elements updates lowest to be lowest", () {
//    expected 1, actual 0
    // finish setting up, and get mock in somehow....
    FitbitApi().fetch_weights_from_fitbit(startDate, endDate, accessToken);
    expect(0, 1);
  });
}
