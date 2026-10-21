import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static const int auctionAlarmId = 1001;
  static const int currencyAlertId = 1002;
  static const int batchStatusBaseId = 2000;

  // Notification Channels
  static const String auctionChannelId = 'auction_alerts';
  static const String currencyChannelId = 'currency_alerts';
  static const String batchChannelId = 'batch_alerts';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    await _createChannels();

    _initialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          auctionChannelId,
          'Auction Alerts',
          description: 'Notifikasi jam buka/tutup sesi lelang ICE Futures Europe',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          currencyChannelId,
          'Currency Alerts',
          description: 'Notifikasi perubahan kurs mata uang > 1%',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          batchChannelId,
          'Batch Status',
          description: 'Notifikasi perubahan status batch kopi',
          importance: Importance.high,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  // ─── Auction Alarm ─────────────────────────────────────────

  /// Schedule daily alarm for ICE Futures Europe opening at 10:00 London time
  /// Converted to WIB (UTC+7) = 17:00 WIB (or 16:00 during BST)
  Future<void> scheduleAuctionAlarm() async {
    await _plugin.cancelAll();

    // ICE Futures Europe opens at 10:00 London (UTC+0/+1 BST)
    // For simplicity, using UTC+0 → 10:00 UTC = 17:00 WIB
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      17, // 17:00 WIB = 10:00 London UTC
      0,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      auctionAlarmId,
      '☕ Sesi Lelang Dibuka!',
      'ICE Futures Europe buka pukul 10:00 London (17:00 WIB). Pantau harga kopi sekarang!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          auctionChannelId,
          'Auction Alerts',
          channelDescription: 'Notifikasi jam buka sesi lelang',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(
            'ICE Futures Europe telah membuka sesi perdagangan. Waktu terbaik untuk memantau harga green bean dan merencanakan strategi ekspor.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel auction alarm
  Future<void> cancelAuctionAlarm() async {
    await _plugin.cancel(auctionAlarmId);
  }

  // ─── Currency Alert ────────────────────────────────────────

  /// Show alert when currency change exceeds threshold
  Future<void> showCurrencyAlert({
    required String currency,
    required double changePercent,
    required double oldRate,
    required double newRate,
  }) async {
    final isUp = changePercent > 0;
    final emoji = isUp ? '📈' : '📉';
    final direction = isUp ? 'naik' : 'turun';

    await _plugin.show(
      currencyAlertId + currency.hashCode % 100,
      '$emoji Kurs $currency ${direction}!',
      '$currency $direction ${changePercent.abs().toStringAsFixed(2)}% — '
          'dari ${oldRate.toStringAsFixed(oldRate > 100 ? 0 : 2)} '
          'ke ${newRate.toStringAsFixed(newRate > 100 ? 0 : 2)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          currencyChannelId,
          'Currency Alerts',
          channelDescription: 'Perubahan kurs mata uang',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'currency_$currency',
    );
  }

  // ─── Batch Status Notification ─────────────────────────────

  /// Show notification when batch status changes
  Future<void> showBatchStatusNotification({
    required String batchId,
    required String variety,
    required String newStatus,
  }) async {
    String title;
    String body;

    switch (newStatus) {
      case 'verified':
        title = '✅ Batch Terverifikasi!';
        body = '$variety ($batchId) telah lolos verifikasi Q-Grader dan siap untuk proses selanjutnya.';
        break;
      case 'exported':
        title = '📦 Batch Diekspor!';
        body = '$variety ($batchId) telah masuk proses ekspor. Pantau logistik di peta.';
        break;
      case 'sold':
        title = '🎉 Batch Terjual!';
        body = '$variety ($batchId) telah terjual. Cek detail transaksi.';
        break;
      default:
        title = '📋 Status Batch Berubah';
        body = '$variety ($batchId) status diperbarui menjadi $newStatus.';
    }

    await _plugin.show(
      batchStatusBaseId + batchId.hashCode % 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          batchChannelId,
          'Batch Status',
          channelDescription: 'Perubahan status batch',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'batch_$batchId',
    );
  }

  // ─── Weather Rain Alert ────────────────────────────────────

  /// Show rain alert for plantation
  Future<void> showRainAlert({
    required String location,
    required double precipitationMm,
  }) async {
    await _plugin.show(
      3001,
      '🌧️ Peringatan Hujan — $location',
      'Prakiraan curah hujan ${precipitationMm.toStringAsFixed(1)}mm. '
          'Pertimbangkan untuk mengangkat jemuran biji kopi!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          batchChannelId,
          'Batch Status',
          channelDescription: 'Peringatan cuaca kebun',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'weather_alert',
    );
  }

  // ─── Request Permission ────────────────────────────────────

  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // ─── Cancel All ────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
