import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'config.dart';
import 'token_storage.dart';

/// Se sobrescribe en main() con la instancia ya cargada.
final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

final tokenStorageProvider = Provider((ref) => TokenStorage(ref.watch(sharedPrefsProvider)));

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(tokenStorageProvider).read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (e, handler) {
      final isLogin = e.requestOptions.path == '/auth/login';
      if (e.response?.statusCode == 401 && !isLogin) {
        // token vencido o inválido: cerrar sesión
        ref.read(authProvider.notifier).sessionExpired();
      }
      handler.next(e);
    },
  ));
  return dio;
});

final apiProvider = Provider((ref) => ApiService(ref.watch(dioProvider)));

// --- sesión ---

class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    if (ref.read(tokenStorageProvider).read() == null) return null;
    try {
      return await ref.read(apiProvider).me();
    } on ApiException catch (e) {
      if (e.statusCode == 401) await ref.read(tokenStorageProvider).clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final api = ref.read(apiProvider);
    final token = await api.login(email, password);
    await ref.read(tokenStorageProvider).save(token);
    state = AsyncData(await api.me());
  }

  Future<void> register(String email, String username, String password) async {
    await ref.read(apiProvider).register(email, username, password);
    await login(email, password);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> sessionExpired() => logout();
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

// --- datos ---

final competitionsProvider =
    FutureProvider((ref) => ref.watch(apiProvider).competitions());

final groupsProvider = FutureProvider((ref) => ref.watch(apiProvider).groups());

final groupDetailProvider =
    FutureProvider.family((ref, int id) => ref.watch(apiProvider).groupDetail(id));

final leaderboardProvider =
    FutureProvider.family((ref, int id) => ref.watch(apiProvider).leaderboard(id));

final matchesProvider =
    FutureProvider.family((ref, String code) => ref.watch(apiProvider).matches(code));

final predictionsProvider =
    FutureProvider.family((ref, int groupId) => ref.watch(apiProvider).predictions(groupId));
