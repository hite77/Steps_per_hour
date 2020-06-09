import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

int goalStepsDefault = 12000;
int goalSteps = 12000;
int offset = 0;
String date = '';
bool stepGoalMode = true;
String currentSteps = '0';

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

class Secret {
  final String clientId;
  final String clientSecret;
  Secret({this.clientId = "", this.clientSecret = ""});
  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    return new Secret(
        clientId: jsonMap["client_id"], clientSecret: jsonMap["client_secret"]);
  }
}

class SecretLoader {
  final String secretPath;

  SecretLoader({this.secretPath});
  Future<Secret> load() {
    return rootBundle.loadStructuredData<Secret>(this.secretPath,
        (jsonStr) async {
      final secret = Secret.fromJson(json.decode(jsonStr));
      return secret;
    });
  }
}

void persistTokens(accessToken, refreshToken) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('accessToken', accessToken);
  prefs.setString('refreshToken', refreshToken);
}

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

Future<String> getSteps() async {
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
      prefs.remove('accessToken');
      prefs.remove('refreshToken');
      return 'error refresh token';
    }

    accessToken = jsonDecode(refresh.body)['access_token'];
    refreshToken = jsonDecode(refresh.body)['refresh_token'];

    persistTokens(accessToken, refreshToken);

    activity = await http.get(
        'https://api.fitbit.com/1/user/-/activities/date/today.json',
        headers: {'Authorization': 'Bearer ' + accessToken});
  }
  String steps = jsonDecode(activity.body)['summary']['steps'].toString();
  return steps;
}

_write_settings(int steps, int offset, String date) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('goalsteps', steps);
  prefs.setInt('offset', offset);
  prefs.setString('date', date);
}

Future<dynamic> _pullGoalStepsFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int steps = (prefs.getInt('goalsteps') ?? goalStepsDefault);
  int offset = (prefs.getInt('offset') ?? 0);
  var date = (prefs.getString('date') ?? '');
  return [steps, offset, date];
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steps per hour',
      home: StepsPerHour(),
    );
  }
}

class StepsPerHourState extends State<StepsPerHour> {
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget _buildStepsPerHour(List<dynamic> data) {
    goalSteps = data[0];
    offset = data[1];
    date = data[2];
    var today = "${clock.now().month}.${clock.now().day}.${clock.now().year}";
    if (date != today) {
      date = today;
      offset = 0;
      _write_settings(goalSteps, offset, date);
    }

    var hour = clock.now().hour;
    var entries = <String>[];

    var increase = roundDecimal((goalSteps / 14).floor());
    if (hour <= 7) entries.add("7  -->   ${increase + offset} steps");
    if (hour <= 8) entries.add("8  -->   ${increase * 2 + offset} steps");
    if (hour <= 9) entries.add("9  -->   ${increase * 3 + offset} steps");
    if (hour <= 10) entries.add("10 -->  ${increase * 4 + offset} steps");
    if (hour <= 11) entries.add("11 -->  ${increase * 5 + offset} steps");
    if (hour <= 12) entries.add("12 -->  ${increase * 6 + offset} steps");
    if (hour <= 13) entries.add("1  -->  ${increase * 7 + offset} steps");
    if (hour <= 14) entries.add("2  -->  ${increase * 8 + offset} steps");
    if (hour <= 15) entries.add("3  -->  ${increase * 9 + offset} steps");
    if (hour <= 16) entries.add("4  -->  ${increase * 10 + offset} steps");
    if (hour <= 17) entries.add("5  -->  ${increase * 11 + offset} steps");
    if (hour <= 18) entries.add("6  -->  ${increase * 12 + offset} steps");
    if (hour <= 19) entries.add("7  -->  ${increase * 13 + offset} steps");
    if (hour <= 20) entries.add("8  --> ${goalSteps + offset} steps");

    List<Widget> entriesList = [];
    entriesList.add(_headerRow());
    entries.map((item) => entriesList.add(_buildRow(item))).toList();
    return ListView(children: entriesList);
  }

  Widget _headerRow() {
    return Row(
      children: <Widget>[
        IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () async {
              setState(() {
                if (stepGoalMode) {
                  goalSteps += 1000;
                } else {
                  offset += 100;
                }
              });
              _write_settings(goalSteps, offset, date);
            }),
        Expanded(
          child: Center(
            child: Text((stepGoalMode)
                ? "Goal:$goalSteps Offset:$offset Current:$currentSteps"
                : "Offset:$offset Goal:$goalSteps Current:$currentSteps"),
          ),
        ),
        IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () async {
              setState(() {
                if (stepGoalMode) {
                  goalSteps -= 1000;
                } else {
                  offset -= 100;
                }
              });
              _write_settings(goalSteps, offset, date);
            }),
      ],
    );
  }

  Widget _buildRow(String text) {
    return ListTile(
      title: Text(
        text,
        style: _biggerFont,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _pullGoalStepsFromPreferences(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(
                title: Text('Steps Per Hour'),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.build),
                    onPressed: () async {
                      setState(() {
                        stepGoalMode = !stepGoalMode;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.restore),
                    onPressed: () async {
                      _write_settings(goalSteps, 0, date);
                      setState(() {
                        offset = 0;
                      });
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () async {
                        currentSteps = await getSteps();
                        setState(() {});
                      }),
                ],
              ),
              body: _buildStepsPerHour(snapshot.data));
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class StepsPerHour extends StatefulWidget {
  @override
  StepsPerHourState createState() => StepsPerHourState();
}
