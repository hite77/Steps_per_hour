// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:clock/clock.dart';

void main() => runApp(MyApp());

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
  var hour = clock.now().hour,

  var entries = <String>[];
    if (hour >= 7) { entries.add('7  -->   715 steps')};
    '8  -->  1430 steps',
    '9  -->  2145 steps',
    '10 -->  2860 steps',
    '11 -->  3575 steps',
    '12 -->  4290 steps',
    ' 1 -->  5005 steps',
    ' 2 -->  5720 steps',
    ' 3 -->  6435 steps',
    ' 4 -->  7150 steps',
    ' 5 -->  7865 steps',
    ' 6 -->  8580 steps',
    ' 7 -->  9295 steps',
    ' 8 --> 10000 steps'
  ];
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget _buildStepsPerHour() {
    return ListView.builder(
        padding: const EdgeInsets.all(2.0),
        itemBuilder: (context, i) {
          if (i < entries.length) {
            return _buildRow(entries[i]);
          }
          else
            return ListTile();
        });
  }

  Widget _buildRow(String text) {
    return ListTile(
        title: Text(
          text,
          style: _biggerFont,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Steps Per Hour'),
          actions: <Widget>[
      // action button
      IconButton(
      icon: Icon(Icons.adjust),
      onPressed: () {
//        ;
      },
    ),
      ]),
          body: _buildStepsPerHour(),
    );
  }
}

class StepsPerHour extends StatefulWidget {
  @override
  StepsPerHourState createState() => StepsPerHourState();
}

