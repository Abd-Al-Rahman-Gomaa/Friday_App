import 'package:isar/isar.dart';
part 'app_settings.g.dart';

@Collection()
class AppSettings {
  Id id = Isar.autoIncrement; // Always needed

  DateTime? firstLaunchDate;
}
