import 'dart:collection';
import 'dart:convert';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(TabBarApp());

class TabBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.directions_walk)),
                Tab(icon: Icon(Icons.multiline_chart)),
              ],
            ),
            title: Text('Fit Data'),
          ),
          body: TabBarView(
            children: [
              StepApp(),
              new TimeSeriesLineAnnotationChart(),
            ],
          ),
        ),
      ),
    );
  }
}

int goalStepsDefault = 12000;
int goalSteps = 12000;
int offset = 0;
String dateString = '';
String currentSteps = '0';
int steps = 0;
int increase = roundDecimal((goalSteps / 14).floor());

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

_write_settings(int steps, int offset, String date, int increase) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('goalsteps', steps);
  prefs.setInt('offset', offset);
  prefs.setString('date', date);
  prefs.setInt('increase', increase);
}

Future<dynamic> _pullGoalStepsFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int steps = (prefs.getInt('goalsteps') ?? goalStepsDefault);
  int offset = (prefs.getInt('offset') ?? 0);
  String date = (prefs.getString('date') ?? '');
  int increase =
      (prefs.getInt('increase') ?? roundDecimal((goalSteps / 14).floor()));
  return [steps, offset, date, increase];
}

class StepApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steps per hour',
      home: StepsPerHour(),
    );
  }
}

class StringWithCompletion {
  final text;
  final complete;
  const StringWithCompletion(this.text, this.complete);
}

class StepsPerHourState extends State<StepsPerHour> {
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget _buildStepsPerHour(List<dynamic> data) {
    goalSteps = data[0];
    offset = data[1];
    dateString = data[2];
    increase = data[3];
    var today = "${clock.now().month}.${clock.now().day}.${clock.now().year}";
    if (dateString != today) {
      dateString = today;
      offset = 0;
      increase = roundDecimal((goalSteps / 14).floor());
      _write_settings(goalSteps, offset, dateString, increase);
    }

    var hour = clock.now().hour;
    var entries = <StringWithCompletion>[];

    if (hour <= 7)
      entries.add(StringWithCompletion(
          "7  -->   ${increase + offset} steps", steps >= (increase + offset)));
    if (hour <= 8)
      entries.add(StringWithCompletion(
          "8  -->   ${increase * 2 + offset} steps",
          steps >= (increase * 2 + offset)));
    if (hour <= 9)
      entries.add(StringWithCompletion(
          "9  -->   ${increase * 3 + offset} steps",
          steps >= (increase * 3 + offset)));
    if (hour <= 10)
      entries.add(StringWithCompletion("10 -->  ${increase * 4 + offset} steps",
          steps >= (increase * 4 + offset)));
    if (hour <= 11)
      entries.add(StringWithCompletion("11 -->  ${increase * 5 + offset} steps",
          steps >= (increase * 5 + offset)));
    if (hour <= 12)
      entries.add(StringWithCompletion("12 -->  ${increase * 6 + offset} steps",
          steps >= (increase * 6 + offset)));
    if (hour <= 13)
      entries.add(StringWithCompletion("1  -->  ${increase * 7 + offset} steps",
          steps >= (increase * 7 + offset)));
    if (hour <= 14)
      entries.add(StringWithCompletion("2  -->  ${increase * 8 + offset} steps",
          steps >= (increase * 8 + offset)));
    if (hour <= 15)
      entries.add(StringWithCompletion("3  -->  ${increase * 9 + offset} steps",
          steps >= (increase * 9 + offset)));
    if (hour <= 16)
      entries.add(StringWithCompletion(
          "4  -->  ${increase * 10 + offset} steps",
          steps >= (increase * 10 + offset)));
    if (hour <= 17)
      entries.add(StringWithCompletion(
          "5  -->  ${increase * 11 + offset} steps",
          steps >= (increase * 11 + offset)));
    if (hour <= 18)
      entries.add(StringWithCompletion(
          "6  -->  ${increase * 12 + offset} steps",
          steps >= (increase * 12 + offset)));
    if (hour <= 19)
      entries.add(StringWithCompletion(
          "7  -->  ${increase * 13 + offset} steps",
          steps >= (increase * 13 + offset)));
    if (hour <= 20) if (hour <= 20) {
      if (offset <= 0) {
        entries.add(StringWithCompletion(
            "8  -->  ${goalSteps} steps", steps >= (goalSteps)));
      } else {
        entries.add(StringWithCompletion("8  -->  ${goalSteps + offset} steps",
            steps >= (goalSteps + offset)));
      }
    }

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
              goalSteps += 1000;
              offset = 0;
              increase = roundDecimal((goalSteps / 14).floor());
              _write_settings(goalSteps, offset, dateString, increase);
              setState(() {});
            }),
        Expanded(
          child: Center(
            child: Text((offset <= 0)
                ? "Goal:$goalSteps Current:$currentSteps"
                : "Goal:${goalSteps + offset} Current:$currentSteps"),
          ),
        ),
        IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () async {
              goalSteps -= 1000;
              offset = 0;
              increase = roundDecimal((goalSteps / 14).floor());
              _write_settings(goalSteps, offset, dateString, increase);
              setState(() {});
            }),
      ],
    );
  }

  Widget _buildRow(StringWithCompletion stringWithCompletion) {
    return ListTile(
      leading: Icon((stringWithCompletion.complete)
          ? Icons.check_box
          : Icons.check_box_outline_blank),
      title: Text(
        stringWithCompletion.text,
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
                    icon: Icon(Icons.restore),
                    onPressed: () async {
                      _write_settings(goalSteps, 0, dateString,
                          roundDecimal((goalSteps / 14).floor()));
                      setState(() {
                        offset = 0;
                      });
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () async {
                        currentSteps = await getSteps();
                        steps = int.parse(currentSteps);
                        setState(() {});
                      }),
                  IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        await recalculateStepIncrease();
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

  Future recalculateStepIncrease() async {
    currentSteps = await getSteps();
    steps = int.parse(currentSteps);
    int hour = clock.now().hour;
    int originalIncrease = roundDecimal((goalSteps / 14).floor());
    int currentHourGoalSteps = originalIncrease * (hour - 6);
    if (steps >= currentHourGoalSteps) {
      offset = steps - currentHourGoalSteps;
      increase =
          roundDecimal(((goalSteps + offset - steps) / (20 - hour)).floor());
    } else if (steps < currentHourGoalSteps) {
      increase = ((goalSteps - steps) / (20 - hour)).floor();
      offset = steps - increase * (hour - 6);
    }

    _write_settings(goalSteps, offset, dateString, increase);
  }
}

class TimeSeriesLineAnnotationChart extends StatelessWidget {
  List<charts.Series> seriesList;
  var animate;

  /// Creates a [TimeSeriesChart] with sample data and no transition.

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: _loadAMonth(),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            seriesList = snapshot.data;
            return new charts.TimeSeriesChart(seriesList, animate: animate);
          } else {
            return CircularProgressIndicator();
          }
        }

        // this was what was needed to annotate....
//        behaviors: [
//      new charts.RangeAnnotation([
//        new charts.LineAnnotationSegment(
//            new DateTime(2017, 10, 4), charts.RangeAnnotationAxisType.domain,
//            startLabel: 'Oct 4'),
//        new charts.LineAnnotationSegment(
//            new DateTime(2017, 10, 15), charts.RangeAnnotationAxisType.domain,
//            endLabel: 'Oct 15'),
//      ]),
//    ]
        );
  }

  /// Create one series with sample hard coded data.
  Future<List<charts.Series<TimeSeriesSales, DateTime>>> _loadAMonth() async {
    final String accessToken = await getTokens();
    var combinedHeader = new HashMap<String, String>();
    combinedHeader['Authorization'] = 'Bearer ' + accessToken;
    combinedHeader['Accept-Language'] = 'en_US';
    combinedHeader['Accept-Local'] = 'en_US';

    DateTime now = DateTime.now();
    var prevMonth = new DateTime(now.year, now.month - 1, now.day);

    var weightMonth = await http.get(
        "https://api.fitbit.com/1/user/-/body/log/weight/date/${prevMonth.year}-${(prevMonth.month < 10) ? "0${prevMonth.month}" : prevMonth.month}-${(prevMonth.day < 10) ? "0${prevMonth.day}" : prevMonth.day}/${now.year}-${(now.month < 10) ? "0${now.month}" : now.month}-${(now.day < 10) ? "0${now.day}" : now.day}.json",
        headers: combinedHeader);

    var data = <TimeSeriesSales>[];

    jsonDecode(weightMonth.body)['weight'].forEach((weight) => data.add(
        new TimeSeriesSales(
            DateTime.parse(weight['date']), weight['weight'].toDouble())));

    var series = [
      new charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];

    return series;
  }
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime time;
  final double sales;

  TimeSeriesSales(this.time, this.sales);
}

class StepsPerHour extends StatefulWidget {
  @override
  StepsPerHourState createState() => StepsPerHourState();
}
