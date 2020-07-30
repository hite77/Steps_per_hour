import 'dart:collection';
import 'dart:convert';

import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepsperhour/secret.dart';
import 'package:stepsperhour/token.dart';

Future<List> authorizeAndGetTokens(Secret secret, String base64Str) async {
  final callbackUrlScheme = 'com.test.app://oauth2redirect';

  final url = Uri.https('www.fitbit.com', '/oauth2/authorize', {
    'response_type': 'code',
    'client_id': secret.clientId,
    'redirect_uri': '$callbackUrlScheme',
    'scope': 'activity weight',
    'expires_in': '604800'
  });

  final result = await FlutterWebAuth.authenticate(
      url: Uri.decodeComponent(url.toString()),
      callbackUrlScheme: 'com.test.app');
  final code = result.split('?code=')[1].split('#_=_')[0];

  final tokens = await http.post("https://api.fitbit.com/oauth2/token", body: {
    'client_id': secret.clientId,
    'grant_type': 'authorization_code',
    'redirect_uri': '$callbackUrlScheme',
    'code': code,
  }, headers: {
    'Authorization': 'Basic ' + base64Str
  });

  String accessToken = jsonDecode(tokens.body)['access_token'];
  String refreshToken = jsonDecode(tokens.body)['refresh_token'];

  persistTokens(accessToken, refreshToken);

  return [accessToken, refreshToken];
}

Future<String> getTokens() async {
  Secret secret = await SecretLoader(secretPath: "secrets.json").load();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String accessToken = (prefs.getString('accessToken') ?? '');
  String refreshToken = (prefs.getString('refreshToken') ?? '');

  String secretsText = "${secret.clientId}:${secret.clientSecret}";
  List encodedText = utf8.encode(secretsText);
  String base64Str = base64.encode(encodedText);

  if (accessToken == '') {
    List tokens = await authorizeAndGetTokens(secret, base64Str);
    accessToken = tokens[0];
    refreshToken = tokens[1];
  }

  var activity = await http.get(
      'https://api.fitbit.com/1/user/-/activities/date/today.json',
      headers: {'Authorization': 'Bearer ' + accessToken});
  if (activity.statusCode != 200) {
    final refresh =
        await http.post("https://api.fitbit.com/oauth2/token", body: {
      'client_id': secret.clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    }, headers: {
      'Authorization': 'Basic ' + base64Str
    });

    if (refresh.statusCode != 200) {
      // try one more time
      authorizeAndGetTokens(secret, base64Str);
      List tokens = await authorizeAndGetTokens(secret, base64Str);
      accessToken = tokens[0];
      refreshToken = tokens[1];
      var activity = await http.get(
          'https://api.fitbit.com/1/user/-/activities/date/today.json',
          headers: {'Authorization': 'Bearer ' + accessToken});
      if (activity.statusCode != 200) {
        prefs.remove('accessToken');
        prefs.remove('refreshToken');
        return 'error refresh token';
      }
    } else {
      accessToken = jsonDecode(refresh.body)['access_token'];
      refreshToken = jsonDecode(refresh.body)['refresh_token'];
      persistTokens(accessToken, refreshToken);
    }
  }
  return accessToken;
}

Future<String> getSteps() async {
  final String accessToken = await getTokens();
  var activity = await http.get(
      'https://api.fitbit.com/1/user/-/activities/date/today.json',
      headers: {'Authorization': 'Bearer ' + accessToken});
  String steps = jsonDecode(activity.body)['summary']['steps'].toString();
  return steps;
}

//todo: put in a class so I can mock this?
fetch_weights_from_fitbit(startDate, endDate, accessToken) async {
  var combinedHeader = new HashMap<String, String>();
  combinedHeader['Authorization'] = 'Bearer ' + accessToken;
  combinedHeader['Accept-Language'] = 'en_US';
  combinedHeader['Accept-Local'] = 'en_US';

  var weightMonth = await http.get(
      "https://api.fitbit.com/1/user/-/body/log/weight/date/${startDate.year}-${(startDate.month < 10) ? "0${startDate.month}" : startDate.month}-${(startDate.day < 10) ? "0${startDate.day}" : startDate.day}/${endDate.year}-${(endDate.month < 10) ? "0${endDate.month}" : endDate.month}-${(endDate.day < 10) ? "0${endDate.day}" : endDate.day}.json",
      headers: combinedHeader);

  return weightMonth.body;
}
