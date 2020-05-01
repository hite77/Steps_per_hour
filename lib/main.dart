import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

var goalStepsDefault = 12000;
var goalSteps = 12000;

_updateGoalSteps() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final steps = (prefs.getInt('goalsteps') ?? goalStepsDefault);
  print("steps=$steps");
  return steps;
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

  Widget _buildStepsPerHour() {
    var hour = clock.now().hour;
    var entries = <String>[];

    var increase = (goalSteps / 14).floor();
    if (hour <= 7) entries.add("7  -->   $increase steps");
    if (hour <= 8) entries.add("8  -->   ${increase * 2} steps");
    if (hour <= 9) entries.add("9  -->   ${increase * 3} steps");
    if (hour <= 10) entries.add("10 -->  ${increase * 4} steps");
    if (hour <= 11) entries.add("11 -->  ${increase * 5} steps");
    if (hour <= 12) entries.add("12 -->  ${increase * 6} steps");
    if (hour <= 13) entries.add("1  -->  ${increase * 7} steps");
    if (hour <= 14) entries.add("2  -->  ${increase * 8} steps");
    if (hour <= 15) entries.add("3  -->  ${increase * 9} steps");
    if (hour <= 16) entries.add("4  -->  ${increase * 10} steps");
    if (hour <= 17) entries.add("5  -->  ${increase * 11} steps");
    if (hour <= 18) entries.add("6  -->  ${increase * 12} steps");
    if (hour <= 19) entries.add("7  -->  ${increase * 13} steps");
    if (hour <= 20) entries.add("8  --> $goalSteps steps");
    return ListView.builder(
        padding: const EdgeInsets.all(2.0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Row(
              children: <Widget>[
                IconButton(
                    icon: Icon(Icons.arrow_upward),
                    onPressed: () async {
                      setState(() {
                        goalSteps += 1000;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setInt('goalsteps', goalSteps);
                    }),
                Expanded(
                  child: Center(
                    child: Text("$goalSteps"),
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.arrow_downward),
                    onPressed: () async {
                      setState(() {
                        goalSteps -= 1000;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setInt('goalsteps', goalSteps);
                    }),
              ],
            );
          }
          if (i <= entries.length) {
            return _buildRow(entries[i - 1]);
          } else
            return ListTile();
        });
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
    return Scaffold(
        appBar: AppBar(
          title: Text('Steps Per Hour'),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  final steps = await _updateGoalSteps().then((steps) {
                    return steps;
                  });
                  setState(() {
                    goalSteps = steps;
                  });
                }),
          ],
        ),
        body: _buildStepsPerHour());
  }
}

class StepsPerHour extends StatefulWidget {
  @override
  StepsPerHourState createState() => StepsPerHourState();
}
