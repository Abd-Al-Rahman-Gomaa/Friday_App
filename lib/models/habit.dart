import 'package:isar/isar.dart';
// run cmd to generate file: dart run build_runner build
part 'habit.g.dart';

@Collection()
class Habit {
  Id id = Isar.autoIncrement;

  // Habit Name
  // Completed Days
  List<DateTime> completedDays = [];
}
