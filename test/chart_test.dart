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

  // test for deleteOld
}
