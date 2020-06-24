import 'package:stepsperhour/dbhelper.dart';

class Weight {
  int id;
  // contains the body text from fitbit that has the weight
  String data;
  // start date includes month/dayyear
  String start;
  // end date current month will keep adding, next month it will be completed
  String end;
  // to find age, storing an int for milliseconds since epoch
  int age;

  Weight(this.id, this.data, this.start, this.end, this.age);

  Weight.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    data = map['data'];
    start = map['start'];
    end = map['end'];
    age = map['age'];
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnData: data,
      DatabaseHelper.columnStart: start,
      DatabaseHelper.columnEnd: end,
      DatabaseHelper.columnAge: age
    };
  }
}
