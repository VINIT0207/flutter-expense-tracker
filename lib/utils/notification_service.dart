import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/goal.dart';
import '../models/transaction.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.toString()));
    } catch (e) {
      debugPrint("Could not get local timezone, falling back to UTC: $e");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? enabled = await androidImplementation?.areNotificationsEnabled();
    return enabled ?? true;
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? androidGranted = await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final bool? iosGranted = await iOSImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? iosGranted) ?? true;
  }

  /// Checks if notifications are enabled. If not, requests permission or shows a dialog with instructions.
  Future<void> checkAndPromptPermission(BuildContext context) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) {
      final granted = await requestPermissions();
      if (!granted && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151D2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF334155), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.notifications_off_outlined, color: Color(0xFFFBBF24)),
                SizedBox(width: 10),
                Text("Enable Notifications", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Notifications are currently disabled for FinPlus. To receive hourly reminders and savings goal updates, please enable notifications in your phone's Settings > Apps > FinPlus > Notifications.",
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Got It", style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> showBudgetAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alerts_channel',
      'Budget Alerts',
      channelDescription: 'Notifications for budget warnings and limits',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFEF4444), // kDangerColor equivalent
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder to log expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // Schedule for 8 PM every day
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Update your expenses 📝',
      body: 'Take a moment to log your expenses for today.',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleHourlyReminder({List<TransactionModel>? recentTxs}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hourly_reminders_channel',
      'Hourly Expense Reminders',
      channelDescription: 'Hourly reminders to track and log your expenses between 9 AM and 10 PM',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF6366F1),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    // Cancel legacy periodic ID
    await _notificationsPlugin.cancel(id: 2);

    // Check if an expense was logged recently today
    DateTime? lastTxTime;
    if (recentTxs != null && recentTxs.isNotEmpty) {
      final todayTxs = recentTxs.where((tx) =>
          tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day).toList();
      if (todayTxs.isNotEmpty) {
        todayTxs.sort((a, b) => b.date.compareTo(a.date));
        lastTxTime = todayTxs.first.date;
      }
    }

    // Schedule hourly reminders from 9:00 AM (9) to 10:00 PM (22)
    for (int hour = 9; hour <= 22; hour++) {
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

      // If user already logged an expense in the past hour or current slot, skip today's slot
      if (lastTxTime != null &&
          scheduledDate.isAfter(now) &&
          lastTxTime.isAfter(scheduledDate.subtract(const Duration(hours: 1)))) {
        // User already logged an expense for this time slot; defer slot to tomorrow
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: 100 + hour,
        title: 'Track your spending ⏱️',
        body: 'Did you make any recent purchases? Log them to stay on budget!',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> scheduleGoalNotifications(List<GoalModel> goals, {bool hasSavingsLoggedToday = false}) async {
    final activeGoals = goals.where((g) => !g.isCompleted && g.savedAmount < g.targetAmount).toList();
    if (activeGoals.isEmpty) {
      await _notificationsPlugin.cancel(id: 3);
      for (int h = 9; h <= 21; h += 2) {
        await _notificationsPlugin.cancel(id: 200 + h);
      }
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goal_reminders_channel',
      'Savings Goal Reminders',
      channelDescription: 'Every 2 hours reminders for your active savings goals between 9 AM and 10 PM',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF10B981),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final topGoal = activeGoals.first;
    final totalDaily = activeGoals.fold(0.0, (sum, g) => sum + g.dailySavingsNeeded);
    final now = tz.TZDateTime.now(tz.local);

    // Schedule goal reminder every 2 hours between 9 AM and 10 PM (9, 11, 13, 15, 17, 19, 21)
    for (int hour = 9; hour <= 21; hour += 2) {
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

      // If user HAS ALREADY logged savings today, cancel/postpone today's reminder to tomorrow!
      if (hasSavingsLoggedToday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      String body = "Don't forget to save for \"${topGoal.title}\"! (Saved: ₹${topGoal.savedAmount.toStringAsFixed(0)} / Target: ₹${topGoal.targetAmount.toStringAsFixed(0)}). Save ₹${totalDaily.toStringAsFixed(0)}/day to stay on track!";

      await _notificationsPlugin.zonedSchedule(
        id: 200 + hour,
        title: '🎯 Savings Goal Reminder',
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showGoalAlert(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goal_reminders_channel',
      'Savings Goal Reminders',
      channelDescription: 'Daily updates and reminders for your active savings goals',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF10B981),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 4,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}

