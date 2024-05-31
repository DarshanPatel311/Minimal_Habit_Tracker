import 'package:isar/isar.dart';
part 'habit.g.dart';

@collection
class Habit{
  //habit id
  Id id=Isar.autoIncrement;
//habit name
  late String name;
//habit days

List<DateTime> completedDays=[];
}