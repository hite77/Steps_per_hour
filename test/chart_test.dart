import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stepsperhour/chart.dart';
import 'package:stepsperhour/dbhelper.dart';

class mockDbHelper extends Mock implements DatabaseHelper {}

var dbHelper = mockDbHelper();
var chartState = new ChartState();

setupDataForMonth(now, monthBack) {
  var startDate = new DateTime(now.year, now.month - monthBack, 1);
  var endDate;
  if (monthBack > 0) {
    endDate = new DateTime(now.year, now.month - monthBack + 1, 0);
  } else {
    endDate = new DateTime(now.year, now.month, now.day);
  }
  var encode = jsonEncode({
    "weight": [
      {"weight": 184.45, "date": "2020-01-10"}
    ]
  });
  var entries = [
    {"end": "${endDate.month}.${endDate.day}.${endDate.year}", "data": encode}
  ];
  when(dbHelper
          .queryRows("${startDate.month}.${startDate.day}.${startDate.year}"))
      .thenAnswer((_) => Future.value(entries));
}

verifyQueryRows(monthsago) {
  DateTime now = DateTime.now();
  var startDate = new DateTime(now.year, now.month - monthsago, 1);
  verify(dbHelper
      .queryRows("${startDate.month}.${startDate.day}.${startDate.year}"));
}

verifyNeverQueryRows(monthsago) {
  DateTime now = DateTime.now();
  var startDate = new DateTime(now.year, now.month - monthsago, 1);
  verifyNever(dbHelper
      .queryRows("${startDate.month}.${startDate.day}.${startDate.year}"));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

//  test("call request data and verify calls for happiest path", () async {
//    DateTime now = DateTime.now();
//    var startDate = now;
//    var endDate = now;
//  var encode = jsonEncode({
//    "weight": [
//      {"weight": 184.45, "date": "2020-01-10"}
//    ]
//  });
//
//    List<Map<String, dynamic>> entries = [
//      {'end': "${endDate.month}.${endDate.day}.${endDate.year}", 'data': encode}
//    ];
//
//    when(dbHelper
//            .queryRows("${startDate.month}.${startDate.day}.${startDate.year}"))
//        .thenAnswer((_) => Future.value(entries));
//
//    chartState.requestData('accessToken', dbHelper, startDate, endDate);
//    // does this pass....
//    //    expect(actual, expected);
//  });

  test("loadWeightData will request 6 months of data including current date",
      () async {
    chartState.months = 6;

    DateTime now = DateTime.now();

    setupDataForMonth(now, 6);
    setupDataForMonth(now, 5);
    setupDataForMonth(now, 4);
    setupDataForMonth(now, 3);
    setupDataForMonth(now, 2);
    setupDataForMonth(now, 1);
    setupDataForMonth(now, 0);

    await chartState.loadWeightData(dbHelper, 'accessToken');

    verifyQueryRows(0);
    verifyQueryRows(1);
    verifyQueryRows(2);
    verifyQueryRows(3);
    verifyQueryRows(4);
    verifyQueryRows(5);
    verifyQueryRows(6);
  });

  test("loadWeightData will request current months of data is set to 0",
      () async {
    chartState.months = 0;

    DateTime now = DateTime.now();

    setupDataForMonth(now, 0);

    await chartState.loadWeightData(dbHelper, 'accessToken');

    verifyQueryRows(0);
    verifyNeverQueryRows(1);
    verifyNeverQueryRows(2);
    verifyNeverQueryRows(3);
    verifyNeverQueryRows(4);
    verifyNeverQueryRows(5);
    verifyNeverQueryRows(6);
  });

  test("loadWeightData will request current months of data is set to 1",
      () async {
    chartState.months = 1;

    DateTime now = DateTime.now();

    setupDataForMonth(now, 0);
    setupDataForMonth(now, 1);

    await chartState.loadWeightData(dbHelper, 'accessToken');

    verifyQueryRows(0);
    verifyQueryRows(1);
    verifyNeverQueryRows(2);
    verifyNeverQueryRows(3);
    verifyNeverQueryRows(4);
    verifyNeverQueryRows(5);
    verifyNeverQueryRows(6);
  });

  test("loadWeightData will request current months of data is set to 2",
      () async {
    chartState.months = 2;

    DateTime now = DateTime.now();

    setupDataForMonth(now, 0);
    setupDataForMonth(now, 1);
    setupDataForMonth(now, 2);

    await chartState.loadWeightData(dbHelper, 'accessToken');

    verifyQueryRows(0);
    verifyQueryRows(1);
    verifyQueryRows(2);
    verifyNeverQueryRows(3);
    verifyNeverQueryRows(4);
    verifyNeverQueryRows(5);
    verifyNeverQueryRows(6);
  });

  test("loadWeightData will call delete old", () async {
    await chartState.loadWeightData(dbHelper, 'accessToken');

    verify(dbHelper.deleteOld());
  });

  test("Add Elements Adds Data", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"}
      ]
    });
    var data = <TimeSeriesWeight>[];

    chartState.AddElements(data, weightMonth, 0, 0);

    expect(data[0].date, DateTime.parse("2020-01-10"));
    expect(data[0].weight, 184.45);
  });

  test("Add elements updates Current to be latest", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"},
        {"weight": 180.45, "date": "2020-01-11"},
        {"weight": 182.43, "date": "2020-01-12"},
        {"weight": 190.23, "date": "2020-01-13"},
        {"weight": 181.23, "date": "2020-01-14"}
      ]
    });
    var values = chartState.AddElements([], weightMonth, 0, 0);
    var current = values[2];

    expect(current, 181.23);
  });

  test("Add elements updates Highest to be highest", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"},
        {"weight": 180.45, "date": "2020-01-11"},
        {"weight": 182.43, "date": "2020-01-12"},
        {"weight": 190.23, "date": "2020-01-13"},
        {"weight": 181.23, "date": "2020-01-14"}
      ]
    });
    var values = chartState.AddElements([], weightMonth, 0, 0);
    var highest = values[1];

    expect(highest, 190.23);
  });

  test(
      "Add elements updates lowest to be lowest, keeps a low from previous month",
      () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"},
        {"weight": 180.45, "date": "2020-01-11"},
        {"weight": 182.43, "date": "2020-01-12"},
        {"weight": 190.23, "date": "2020-01-13"},
        {"weight": 181.23, "date": "2020-01-14"}
      ]
    });
    var firstweight = jsonDecode(weightMonth)['weight'][0]['weight'];
    var reallylowweight = 180.00;
    var values =
        chartState.AddElements([], weightMonth, reallylowweight, firstweight);
    var lowest = values[0];

    expect(lowest, reallylowweight);
  });

  test("Add elements updates highest and lowest together", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.5, "date": "2020-01-10"},
      ]
    });
    var values = chartState.AddElements([], weightMonth, 1000, 0);
    expect(values[0], 184.5);
    expect(values[1], 184.5);
  });

  test("Add elements updates current", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184, "date": "2020-01-10"},
      ]
    });
    var values = chartState.AddElements([], weightMonth, 1000, 0);
    expect(values[2], 184);
  });

  test("Add elements handles int values", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184, "date": "2020-01-10"},
      ]
    });
    var data = [];
    chartState.AddElements(data, weightMonth, 0, 0);
    expect(data[0].weight, 184);
  });

  test(
      "Add elements updates highest to be highest, keeps a high from previous month",
      () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"},
        {"weight": 180.45, "date": "2020-01-11"},
        {"weight": 182.43, "date": "2020-01-12"},
        {"weight": 190.23, "date": "2020-01-13"},
        {"weight": 181.23, "date": "2020-01-14"}
      ]
    });
    var firstweight = jsonDecode(weightMonth)['weight'][0]['weight'];
    var reallyhighweight = 500;
    var values =
        chartState.AddElements([], weightMonth, firstweight, reallyhighweight);
    var highest = values[1];

    expect(highest, reallyhighweight);
  });

  test("Add elements updates lowest to be lowest", () {
    final weightMonth = jsonEncode({
      "weight": [
        {"weight": 184.45, "date": "2020-01-10"},
        {"weight": 180.45, "date": "2020-01-11"},
        {"weight": 182.43, "date": "2020-01-12"},
        {"weight": 190.23, "date": "2020-01-13"},
        {"weight": 181.23, "date": "2020-01-14"}
      ]
    });
    var firstweight = jsonDecode(weightMonth)['weight'][0]['weight'];
    var values =
        chartState.AddElements([], weightMonth, firstweight, firstweight);
    var lowest = values[0];

    expect(lowest, 180.45);
  });
}
