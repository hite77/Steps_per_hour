import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

int goalStepsDefault = 12000;
int goalSteps = 12000;
int offset = 0;
bool stepGoalMode = true;

_write_settings(int steps, int offset) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('goalsteps', steps);
  prefs.setInt('offset', offset);
}

Future<dynamic> _pullGoalStepsFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int steps = (prefs.getInt('goalsteps') ?? goalStepsDefault);
  int offset = (prefs.getInt('offset') ?? 0);
  return [steps, offset];
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
    var goalSteps = data[0];
    var offset = data[1];
    var hour = clock.now().hour;
    var entries = <String>[];

    var increase = (goalSteps / 14).floor();
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
              _write_settings(goalSteps, offset);
            }),
        Expanded(
          child: Center(
            child: Text((stepGoalMode)
                ? "Goal:$goalSteps Offset:$offset"
                : "Offset:$offset Goal:$goalSteps"),
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
              _write_settings(goalSteps, offset);
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
                      _write_settings(goalStepsDefault, 0);
                      setState(() {
                        goalSteps = goalStepsDefault;
                        offset = 0;
                      });
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
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
