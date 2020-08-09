import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:stepsperhour/chart.dart';
import 'package:stepsperhour/fitbit_api.dart';
import 'package:stepsperhour/token.dart';
import 'package:stepsperhour/utilities.dart';

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
              ChartApp(),
            ],
          ),
        ),
      ),
    );
  }
}

int goalStepsDefault = 10000;
int goalSteps = 10000;
int offset = 0;
String dateString = '';
String currentSteps = '0';
int steps = 0;
int increase = roundDecimal((goalSteps / 14).floor());

class StepApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steps per hour',
      home: StepsPerHour(),
    );
  }
}

class ChartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Chart',
      home: Chart(),
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
      token().write_settings(goalSteps, offset, dateString, increase);
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
              token().write_settings(goalSteps, offset, dateString, increase);
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
              token().write_settings(goalSteps, offset, dateString, increase);
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
      future: token().pullGoalStepsFromPreferences(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(
                title: Text('Steps Per Hour'),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.restore),
                    onPressed: () async {
                      token().write_settings(goalSteps, 0, dateString,
                          roundDecimal((goalSteps / 14).floor()));
                      setState(() {
                        offset = 0;
                      });
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () async {
                        currentSteps = await FitbitApi().getSteps();
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
    currentSteps = await FitbitApi().getSteps();
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

    token().write_settings(goalSteps, offset, dateString, increase);
  }
}

class StepsPerHour extends StatefulWidget {
  @override
  StepsPerHourState createState() => StepsPerHourState();
}
