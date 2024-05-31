import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:minimal_habit_tracker/models/app_settings.dart';
import 'package:minimal_habit_tracker/models/habit.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([AppSettingsSchema, HabitSchema], directory: dir.path);
  }

  Future<void> saveFirstLaunchDate() async {
    final existingSetting = await isar.appSettings.where().findFirst();
    if (existingSetting == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  final List<Habit> currentHabits = [];

  Future<void> addHabit(String habitName) async {
    final newHabit = Habit()..name = habitName;
    await isar.writeTxn(() => isar.habits.put(newHabit));
    await readHabits();
  }

  Future<void> readHabits() async {
    final fetchedHabits = await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    notifyListeners();
  }

  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    final habit = await isar.habits.get(id);
    if (habit != null) {
      await isar.writeTxn(() async {
        final today = DateTime.now();
        if (isCompleted) {
          if (!habit.completedDays.any((date) =>
          date.year == today.year &&
              date.month == today.month &&
              date.day == today.day)) {
            habit.completedDays.add(DateTime(today.year, today.month, today.day));
          }
        } else {
          habit.completedDays.removeWhere((date) =>
          date.year == today.year &&
              date.month == today.month &&
              date.day == today.day);
        }
        await isar.habits.put(habit);
      });
    }
    await readHabits();
  }

  Future<void> updateHabitName(int id, String newName) async {
    final habit = await isar.habits.get(id);
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;
        await isar.habits.put(habit);
      });
    }
    await readHabits();
  }

  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    await readHabits();
  }
}
