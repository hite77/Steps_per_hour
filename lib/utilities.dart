import 'package:flutter_web_auth/flutter_web_auth.dart';

roundDecimal(int unroundedSteps) {
  final lastNumber = unroundedSteps % 10;
  if (lastNumber == 0 || lastNumber == 5) {
    return unroundedSteps;
  } else if (lastNumber < 5) {
    return (unroundedSteps - lastNumber + 5);
  } else {
    return (unroundedSteps - lastNumber + 10);
  }
}

//static authenticate forced a wrapper method
class FlutterWebAuthWrapper {
  Future<String> authenticate(String url, String callbackUrlScheme) async {
    return await FlutterWebAuth.authenticate(
        url: url, callbackUrlScheme: callbackUrlScheme);
  }
}
