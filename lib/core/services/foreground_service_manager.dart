import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Keep alive isolate started
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // We update the notification manually from the main isolate
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Task destroyed
  }
}

class ForegroundServiceManager {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pagroo_tracking',
        channelName: 'Pagroo Tracking Service',
        channelDescription: 'Keeps Pagroo alive during active trips',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<ServiceRequestResult> startDistanceTracking() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }
    return FlutterForegroundTask.startService(
      notificationTitle: 'Pagroo',
      notificationText: 'Distance Tracking Active',
      callback: startCallback,
    );
  }

  static Future<ServiceRequestResult> startTimeTracking() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }
    return FlutterForegroundTask.startService(
      notificationTitle: 'Pagroo',
      notificationText: 'Time Tracking Active',
      callback: startCallback,
    );
  }

  static Future<void> updateNotification(String title, String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }

  static Future<ServiceRequestResult> stopService() async {
    return FlutterForegroundTask.stopService();
  }

  static Future<void> requestPermissions() async {
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }
}
