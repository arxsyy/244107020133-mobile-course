import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Dio dengan refresh otomatis: saat 401, coba refresh SATU kali lalu ulangi
/// request. Bila refresh gagal, sesi dibersihkan dan [onSessionExpired]
/// dipanggil agar UI kembali ke /login.
Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  void Function()? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://example-campus-api.test',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      final alreadyRetried = e.requestOptions.extra['retried'] == true;
      if (e.response?.statusCode == 401 && !alreadyRetried) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions
              ..headers['Authorization'] = 'Bearer $renewed'
              ..extra['retried'] = true,
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
          onSessionExpired?.call();
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}
