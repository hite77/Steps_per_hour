import 'dart:convert';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:stepsperhour/dbhelper.dart';
import 'package:stepsperhour/fitbit_api.dart';
import 'package:stepsperhour/weight.dart';

class ChartState extends State<Chart> {
  List<charts.Series> seriesList;
  var animate;
  double lowest = 100000.0;
  double highest = 0.0;
  int months = 6;
  double current = 0.0;

  final dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: accessTokenAndLoadWeightData(dbHelper),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            seriesList = snapshot.data;
            return Scaffold(
                appBar: AppBar(
                  title: Text('$months, $highest, $lowest, $current'),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_downward),
                      onPressed: () async {
                        if (months > 1) {
                          months = months - 1;
                          highest = 0.0;
                          lowest = 100000.0;
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_upward),
                      onPressed: () async {
                        if (months < 12) {
                          months = months + 1;
                          highest = 0.0;
                          lowest = 100000.0;
                        }
                        setState(() {});
                      },
                    ),
                  ],
                ),
                body: new charts.TimeSeriesChart(
                  seriesList,
                  animate: animate,
                  primaryMeasureAxis: new charts.NumericAxisSpec(
                      viewport: new charts.NumericExtents(lowest, highest)),
                  behaviors: [new charts.PanAndZoomBehavior()],
                ));
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  //todo: return a class with these values, so the names will be used.
  AddElements(data, weightMonth, lowest, highest) {
    jsonDecode(weightMonth)['weight'].forEach((weight) {
      double weight_double = weight['weight'].toDouble();
      if (weight_double > highest) {
        highest = weight_double;
      }
      if (weight_double < lowest) {
        lowest = weight_double;
      }
      current = weight_double;
      data.add(
          new TimeSeriesWeight(DateTime.parse(weight['date']), weight_double));
    });

    return [lowest, highest, current];
  }

//  todo: test this by mocking dbHelper, and also mocking either http, or fetch_weights_from_fitbit
  requestData(accessToken, dbHelper, startDate, endDate) async {
    var entries = await dbHelper
        .queryRows("${startDate.month}.${startDate.day}.${startDate.year}");
    if (entries.length == 1) {
      if (entries[0]['end'] ==
          "${endDate.month}.${endDate.day}.${endDate.year}") {
        // happiest path, I have the data for this end.
        return entries[0]['data'];
      }
      // need to fetch data and update it out....
      final dataToInsert = await FitbitApi()
          .fetch_weights_from_fitbit(startDate, endDate, accessToken);
      Map<String, dynamic> row = {
        DatabaseHelper.columnId: entries[0]['id'],
        DatabaseHelper.columnAge: endDate.millisecondsSinceEpoch,
        DatabaseHelper.columnData: dataToInsert,
        DatabaseHelper.columnStart: entries[0]['start'],
        DatabaseHelper.columnEnd:
            "${endDate.month}.${endDate.day}.${endDate.year}"
      };

      Weight weight = Weight.fromMap(row);
      await dbHelper.update(weight);
      return dataToInsert;
    }

    // need to fetch data and insert.....
    final dataToInsert = await FitbitApi()
        .fetch_weights_from_fitbit(startDate, endDate, accessToken);
    Map<String, dynamic> row = {
      DatabaseHelper.columnData: dataToInsert,
      DatabaseHelper.columnAge: endDate.millisecondsSinceEpoch,
      DatabaseHelper.columnStart:
          "${startDate.month}.${startDate.day}.${startDate.year}",
      DatabaseHelper.columnEnd:
          "${endDate.month}.${endDate.day}.${endDate.year}"
    };

    Weight weight = Weight.fromMap(row);
    await dbHelper.insert(weight);
    return dataToInsert;
  }

  Future<List<charts.Series<TimeSeriesWeight, DateTime>>>
      accessTokenAndLoadWeightData(dbHelper) async {
    final String accessToken = await FitbitApi().getTokens();
    return await loadWeightData(dbHelper, accessToken);
  }

//  todo: this function needs to be tested most likely pull out the dbHelper as a param
  Future<List<charts.Series<TimeSeriesWeight, DateTime>>> loadWeightData(
      dbHelper, String accessToken) async {
    var data = <TimeSeriesWeight>[];

    await dbHelper.deleteOld();

    DateTime now = DateTime.now();

    for (var i = months; i > 0; i = i - 1) {
      var weightMonth = await requestData(
          accessToken,
          dbHelper,
          new DateTime(now.year, now.month - i, 1),
          new DateTime(now.year, now.month - i + 1, 0));
      var extremes = AddElements(data, weightMonth, lowest, highest);
      lowest = extremes[0];
      highest = extremes[1];
    }

    var currentMonth = await requestData(
        accessToken,
        dbHelper,
        new DateTime(now.year, now.month, 1),
        new DateTime(now.year, now.month, now.day));
    var extremes = AddElements(data, currentMonth, lowest, highest);
    lowest = extremes[0];
    highest = extremes[1];
    current = extremes[2];

    var series = [
      new charts.Series<TimeSeriesWeight, DateTime>(
        id: 'Weight',
        domainFn: (TimeSeriesWeight entry, _) => entry.date,
        measureFn: (TimeSeriesWeight entry, _) => entry.weight,
        data: data,
      )
    ];

    return series;
  }
}

class TimeSeriesWeight {
  final DateTime date;
  final double weight;

  TimeSeriesWeight(this.date, this.weight);
}

class Chart extends StatefulWidget {
  @override
  ChartState createState() => ChartState();
}
