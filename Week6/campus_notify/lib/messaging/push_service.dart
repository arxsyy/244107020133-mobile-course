import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'route_parser.dart';

const topicPengumuman = 'pengumuman-kampus';

const _channel = AndroidNotificationChannel(
  'pengumuman', // harus sama dengan default_notification_channel_id di Manifest
  'Pengumuman Kampus',
  description: 'Notifikasi pengumuman dari kampus',
  importance: Importance.high,
);

final _local = FlutterLocalNotificationsPlugin();

/// Token FCM terakhir, untuk ditampilkan (terpotong) di halaman Debug.
final latestFcmToken = ValueNotifier<String?>(null);

/// Deep link yang menunggu router siap (mis. klik banner sebelum router ada).
String? pendingDeepLink;
void Function(String route)? _navigate;

/// Token tidak boleh tampil/log penuh: 12 karakter pertama + ...
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '-';
  return token.length <= 12 ? '$token...' : '${token.substring(0, 12)}...';
}

// ---------------------------------------------------------------------------
// Background handler: WAJIB fungsi top-level, berjalan di isolate terpisah.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini.
  // Tugasnya: catat / simpan ringan saja. Navigasi dilakukan saat klik.
  debugPrint('[FCM] background message id=${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ---------------------------------------------------------------------------
// Permission + local notifications
// ---------------------------------------------------------------------------

/// Android 13+ (POST_NOTIFICATIONS) dan iOS wajib meminta izin runtime.
/// Android <= 12 otomatis "authorized".
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
    announcement: false, carPlay: false, criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    // Izin iOS sudah diminta lewat FirebaseMessaging.requestPermission.
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> teruskan payload ke router.
      final route = response.payload;
      if (route != null) _goOrQueue(route);
    },
  );

  // Android 8+: channel high-importance agar banner heads-up muncul.
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // iOS: tampilkan banner sistem walau aplikasi foreground? Tidak — kita
  // tampilkan manual lewat local notification agar perilaku sama dengan Android.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false, badge: true, sound: false,
  );

  // Aplikasi terminated lalu dibuka dari banner LOKAL (bukan banner FCM).
  final launch = await _local.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    pendingDeepLink = launch!.notificationResponse?.payload;
  }
}

// ---------------------------------------------------------------------------
// Token lifecycle
// ---------------------------------------------------------------------------
StreamSubscription<String>? _tokenRefreshSub;

Future<void> initFcmToken(
    {required Future<void> Function(String token) onToken}) async {
  Future<void> handle(String token) async {
    latestFcmToken.value = token;
    debugPrint('[FCM] token=${maskToken(token)}'); // jangan log token penuh
    try {
      await onToken(token);
    } catch (e) {
      debugPrint('[FCM] gagal kirim token ke backend: $e');
    }
  }

  // 1. Ambil token saat ini dan kirim ke backend.
  // firebase_messaging 17 menandai getToken/onTokenRefresh deprecated
  // (pengganti: register() + onRegistered). Tetap dipakai sesuai codelab.
  // ignore: deprecated_member_use
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await handle(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  await _tokenRefreshSub?.cancel();
  // ignore: deprecated_member_use
  _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(handle);

  // 3. Langganan topik kampus (mis. semua mahasiswa angkatan).
  await subscribeTopic();
}

Future<void> subscribeTopic() =>
    FirebaseMessaging.instance.subscribeToTopic(topicPengumuman);

Future<void> unsubscribeTopic() =>
    FirebaseMessaging.instance.unsubscribeFromTopic(topicPengumuman);

// ---------------------------------------------------------------------------
// Tiga app state: foreground, background (klik), terminated (klik)
// ---------------------------------------------------------------------------
void listenForeground(void Function(String route) go) {
  _navigate = go;

  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id, _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high, priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: details,
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

/// Panggil SETELAH router siap.
Future<void> handleTerminated(void Function(String route) go) async {
  _navigate = go;
  // Terminated -> dibuka dari notifikasi FCM.
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(routeFromMessage(initial.data));
  final pending = pendingDeepLink;
  if (pending != null) {
    pendingDeepLink = null;
    go(pending);
  }
}

void _goOrQueue(String route) {
  final go = _navigate;
  if (go != null) {
    go(route);
  } else {
    pendingDeepLink = route;
  }
}
