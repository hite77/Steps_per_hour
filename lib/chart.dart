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

  /// Creates a [TimeSeriesChart] with sample data and no transition.

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: _loadWeightData(),
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

  AddElements(data, weightMonth, lowest, highest, current) {
    jsonDecode(weightMonth)['weight'].forEach((weight) {
      if (weight['weight'].toDouble() > highest) {
        highest = weight['weight'].toDouble();
      } else if (weight['weight'].toDouble() < lowest) {
        lowest = weight['weight'].toDouble();
      }
      current = weight['weight'];
      data.add(new TimeSeriesWeight(
          DateTime.parse(weight['date']), weight['weight'].toDouble()));
    });

    return [lowest, highest, current];
  }

  _request_data(accessToken, dbHelper, startDate, endDate) async {
    var entries = await dbHelper
        .queryRows("${startDate.month}.${startDate.day}.${startDate.year}");
    if (entries.length == 1) {
      if (entries[0]['end'] ==
          "${endDate.month}.${endDate.day}.${endDate.year}") {
        // happiest path, I have the data for this end.
        return entries[0]['data'];
      }
      // need to fetch data and update it out....
      final dataToInsert =
          await fetch_weights_from_fitbit(startDate, endDate, accessToken);
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
    final dataToInsert =
        await fetch_weights_from_fitbit(startDate, endDate, accessToken);
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
      _loadWeightData() async {
    var data = <TimeSeriesWeight>[];

    final dbHelper = DatabaseHelper.instance;

    await dbHelper.deleteOld();

    final String accessToken = await getTokens();

    DateTime now = DateTime.now();

    for (var i = months; i > 1; i = i - 1) {
      var weightMonth = await _request_data(
          accessToken,
          dbHelper,
          new DateTime(now.year, now.month - i, 1),
          new DateTime(now.year, now.month - i + 1, 0));
      var extremes = AddElements(data, weightMonth, lowest, highest, current);
      lowest = extremes[0];
      highest = extremes[1];
    }

    var currentMonth = await _request_data(
        accessToken,
        dbHelper,
        new DateTime(now.year, now.month, 1),
        new DateTime(now.year, now.month, now.day));
    var extremes = AddElements(data, currentMonth, lowest, highest, current);
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